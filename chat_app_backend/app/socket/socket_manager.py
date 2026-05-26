import socketio
from app.services.user_service import (
    authenticate_user,
    set_online,
    set_offline,
    get_all_users,
    get_user,
    profile_exists,
    is_user_online,
    save_message,
    get_conversation_history,
    get_recent_conversations,
)

sio = socketio.AsyncServer(
    async_mode="asgi",
    cors_allowed_origins="*",
)

socket_app = socketio.ASGIApp(sio)

# sid → username  (in-memory, fast lookup — rebuilt on reconnect)
sid_user_map: dict[str, str] = {}

# username → sid  (reverse map — to detect duplicate logins)
user_sid_map: dict[str, str] = {}


# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────

def _public_users():
    """All users without password hashes."""
    return get_all_users()


# ─────────────────────────────────────────────
# Connection lifecycle
# ─────────────────────────────────────────────

@sio.event
async def connect(sid, environ):
    print(f"[connect] {sid}")


@sio.event
async def disconnect(sid):
    username = sid_user_map.pop(sid, None)
    if username:
        # Only mark offline if this is still the active session for this user
        if user_sid_map.get(username) == sid:
            user_sid_map.pop(username, None)
            set_offline(username)
            await sio.emit("users_list", _public_users())
            await sio.emit("user_offline", {"username": username})
    print(f"[disconnect] {sid} ({username})")


# ─────────────────────────────────────────────
# Auth — login over socket
# ─────────────────────────────────────────────

@sio.event
async def login(sid, data):
    """
    Payload: { username, password }

    Authenticates the user. On success:
    - Marks them online
    - Boots any existing session for this username (one session only)
    - Returns { success: true, profile, users, recent_conversations }

    On failure:
    - Returns { success: false, error: "..." }
    """
    username = data.get("username", "").strip()
    password = data.get("password", "")

    if not username or not password:
        await sio.emit("login_result", {"success": False, "error": "Username and password are required."}, to=sid)
        return

    profile = authenticate_user(username, password)
    if not profile:
        await sio.emit("login_result", {"success": False, "error": "Invalid username or password."}, to=sid)
        return

    # ── Enforce single session ──────────────────────────
    existing_sid = user_sid_map.get(username)
    if existing_sid and existing_sid != sid:
        # Kick the old session
        await sio.emit(
            "kicked",
            {"reason": "You were signed in from another location."},
            to=existing_sid,
        )
        sid_user_map.pop(existing_sid, None)

    # Register new session
    sid_user_map[sid] = username
    user_sid_map[username] = sid
    set_online(username, sid)

    # Respond to the joining user
    recent = get_recent_conversations(username)
    await sio.emit(
        "login_result",
        {
            "success": True,
            "profile": profile,
            "users": _public_users(),
            "recent_conversations": recent,
        },
        to=sid,
    )

    # Notify everyone else this user came online
    await sio.emit("user_joined", {"username": username}, skip_sid=sid)

    # Broadcast refreshed user list to everyone
    await sio.emit("users_list", _public_users())

    print(f"[login] {username} ({sid})")


# ─────────────────────────────────────────────
# Messaging
# ─────────────────────────────────────────────

@sio.event
async def send_message(sid, data):
    """
    Payload: { sender, receiver, message }
    Sender must be the authenticated user for this sid.
    """
    authenticated_user = sid_user_map.get(sid)
    sender: str = data.get("sender", "")
    receiver: str = data.get("receiver", "")
    message: str = data.get("message", "")

    # Security: ensure the claimed sender matches the authenticated socket
    if authenticated_user != sender:
        await sio.emit("error", {"message": "Unauthorized sender."}, to=sid)
        return

    if not receiver or not message.strip():
        return

    # Persist to Firestore
    saved = save_message(sender, receiver, message)

    # Deliver to receiver if online
    receiver_sid = user_sid_map.get(receiver)
    if receiver_sid:
        await sio.emit("receive_message", saved, to=receiver_sid)

    # Echo back to sender (server-confirmed version)
    await sio.emit("message_sent", saved, to=sid)


# ─────────────────────────────────────────────
# History
# ─────────────────────────────────────────────

@sio.event
async def fetch_history(sid, data):
    """
    Payload: { with_user, limit? }
    """
    username = sid_user_map.get(sid)
    if not username:
        return

    other_user: str = data.get("with_user", "")
    limit: int = int(data.get("limit", 50))

    history = get_conversation_history(username, other_user, limit=limit)

    await sio.emit(
        "chat_history",
        {"with_user": other_user, "messages": history},
        to=sid,
    )


# ─────────────────────────────────────────────
# Typing indicators
# ─────────────────────────────────────────────

@sio.event
async def typing(sid, data):
    """Payload: { receiver }"""
    sender = sid_user_map.get(sid)
    if not sender:
        return

    receiver_sid = user_sid_map.get(data.get("receiver", ""))
    if receiver_sid:
        await sio.emit("user_typing", {"username": sender}, to=receiver_sid)


@sio.event
async def stop_typing(sid, data):
    """Payload: { receiver }"""
    sender = sid_user_map.get(sid)
    if not sender:
        return

    receiver_sid = user_sid_map.get(data.get("receiver", ""))
    if receiver_sid:
        await sio.emit("user_stop_typing", {"username": sender}, to=receiver_sid)


# ─────────────────────────────────────────────
# Read receipts
# ─────────────────────────────────────────────

@sio.event
async def message_read(sid, data):
    """
    Payload: { sender, message_id }
    """
    reader = sid_user_map.get(sid)
    if not reader:
        return

    sender_sid = user_sid_map.get(data.get("sender", ""))
    if sender_sid:
        await sio.emit(
            "message_seen",
            {"by": reader, "message_id": data["message_id"]},
            to=sender_sid,
        )