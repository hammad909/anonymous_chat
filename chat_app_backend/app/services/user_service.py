from app.firebase.firebase_config import users_ref, messages_ref
from datetime import datetime, timezone
import uuid
import bcrypt


# ─────────────────────────────────────────────
# Auth helpers
# ─────────────────────────────────────────────

def _hash_password(plain: str) -> str:
    return bcrypt.hashpw(plain.encode(), bcrypt.gensalt()).decode()


def _verify_password(plain: str, hashed: str) -> bool:
    return bcrypt.checkpw(plain.encode(), hashed.encode())


# ─────────────────────────────────────────────
# User operations
# ─────────────────────────────────────────────

def create_profile(username: str, password: str, avatar: str | None = None) -> dict:
    """
    Register a new user. Raises ValueError if username is already taken.
    Returns the created profile (without password hash).
    """
    doc = users_ref.document(username).get()
    if doc.exists:
        raise ValueError(f"Username '{username}' is already taken.")

    profile = {
        "username": username,
        "avatar": avatar or "🐱",
        "password_hash": _hash_password(password),
        "created_at": datetime.now(timezone.utc).isoformat(),
        # Session fields — start as offline
        "sid": None,
        "is_online": False,
        "last_seen": None,
    }
    users_ref.document(username).set(profile)

    # Return public profile (no password hash)
    return _public_profile(profile)


def authenticate_user(username: str, password: str) -> dict | None:
    """
    Verify credentials. Returns public profile on success, None on failure.
    """
    doc = users_ref.document(username).get()
    if not doc.exists:
        return None

    data = doc.to_dict()
    if not _verify_password(password, data.get("password_hash", "")):
        return None

    return _public_profile(data)


def _public_profile(data: dict) -> dict:
    """Strip sensitive fields before sending to client."""
    return {k: v for k, v in data.items() if k != "password_hash"}


def set_online(username: str, sid: str):
    """Mark user as online and store their current socket session ID."""
    users_ref.document(username).update({
        "sid": sid,
        "is_online": True,
    })


def set_offline(username: str):
    """Mark user as offline, clear SID, record last_seen."""
    users_ref.document(username).update({
        "sid": None,
        "is_online": False,
        "last_seen": datetime.now(timezone.utc).isoformat(),
    })


def get_all_users() -> list[dict]:
    """Return all registered users (online and offline), no password hashes."""
    docs = users_ref.stream()
    return [_public_profile(doc.to_dict()) for doc in docs]


def get_user(username: str) -> dict | None:
    doc = users_ref.document(username).get()
    if not doc.exists:
        return None
    return doc.to_dict()  # internal — includes sid for routing


def get_public_user(username: str) -> dict | None:
    doc = users_ref.document(username).get()
    if not doc.exists:
        return None
    return _public_profile(doc.to_dict())


def profile_exists(username: str) -> bool:
    return users_ref.document(username).get().exists


def is_user_online(username: str) -> bool:
    doc = users_ref.document(username).get()
    if not doc.exists:
        return False
    return doc.to_dict().get("is_online", False)


# ─────────────────────────────────────────────
# Message operations
# ─────────────────────────────────────────────

def _conversation_id(user_a: str, user_b: str) -> str:
    """Deterministic conversation ID regardless of who is sender/receiver."""
    return "__".join(sorted([user_a, user_b]))


def save_message(sender: str, receiver: str, message: str) -> dict:
    """Persist a message and return the saved document dict."""
    msg_id = str(uuid.uuid4())
    timestamp = datetime.now(timezone.utc).isoformat()
    conv_id = _conversation_id(sender, receiver)

    payload = {
        "id": msg_id,
        "sender": sender,
        "receiver": receiver,
        "message": message,
        "timestamp": timestamp,
        "conversation_id": conv_id,
    }

    messages_ref \
        .document(conv_id) \
        .collection("chat") \
        .document(msg_id) \
        .set(payload)

    return payload


def get_conversation_history(user_a: str, user_b: str, limit: int = 50) -> list[dict]:
    """
    Return up to `limit` most recent messages between two users,
    ordered oldest → newest.
    """
    conv_id = _conversation_id(user_a, user_b)

    docs = (
        messages_ref
        .document(conv_id)
        .collection("chat")
        .order_by("timestamp", direction="DESCENDING")
        .limit(limit)
        .stream()
    )

    return list(reversed([doc.to_dict() for doc in docs]))


def get_recent_conversations(username: str) -> list[dict]:
    """
    Return the last message of every conversation the user participated in,
    for populating the sidebar/inbox.
    """
    results = []
    docs = messages_ref.stream()

    for conv_doc in docs:
        conv_id = conv_doc.id
        if username not in conv_id.split("__"):
            continue

        latest = (
            messages_ref
            .document(conv_id)
            .collection("chat")
            .order_by("timestamp", direction="DESCENDING")
            .limit(1)
            .stream()
        )

        for msg in latest:
            results.append(msg.to_dict())

    results.sort(key=lambda m: m.get("timestamp", ""), reverse=True)
    return results