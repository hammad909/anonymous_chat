from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from app.services.user_service import (
    create_profile,
    authenticate_user,
    get_all_users,
    get_public_user,
    profile_exists,
)

router = APIRouter(prefix="/users", tags=["Users"])


# ─────────────────────────────────────────────
# Request / Response models
# ─────────────────────────────────────────────

class RegisterRequest(BaseModel):
    username: str
    password: str
    avatar: str | None = None


class LoginRequest(BaseModel):
    username: str
    password: str


# ─────────────────────────────────────────────
# Auth endpoints
# ─────────────────────────────────────────────

@router.post("/register", status_code=status.HTTP_201_CREATED)
def register(body: RegisterRequest):
    """
    Register a new user account.
    Returns the public profile on success.
    Returns 409 if the username is already taken.
    """
    username = body.username.strip()
    if not username or not body.password:
        raise HTTPException(status_code=400, detail="Username and password are required.")

    try:
        profile = create_profile(username, body.password, body.avatar)
    except ValueError as e:
        raise HTTPException(status_code=409, detail=str(e))

    return {"profile": profile}


@router.post("/login")
def login(body: LoginRequest):
    """
    Validate credentials via REST (useful for initial auth before socket connect).
    Returns the public profile on success.
    Returns 401 on bad credentials.

    Note: the actual presence/online state is set by the `login` socket event.
    This endpoint only validates credentials.
    """
    profile = authenticate_user(body.username.strip(), body.password)
    if not profile:
        raise HTTPException(status_code=401, detail="Invalid username or password.")

    return {"profile": profile}


# ─────────────────────────────────────────────
# User lookup
# ─────────────────────────────────────────────

@router.get("/check/{username}")
def check_username(username: str):
    """Check whether a username is already taken."""
    return {"username": username, "exists": profile_exists(username)}


@router.get("/")
def list_users():
    """Return all users (online and offline), no passwords."""
    return get_all_users()


@router.get("/{username}")
def fetch_user(username: str):
    user = get_public_user(username)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user