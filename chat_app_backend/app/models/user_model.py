from pydantic import BaseModel
from typing import Optional


class User(BaseModel):
    username: str
    avatar: Optional[str] = "🐱"
    sid: Optional[str] = None
    # password is never stored on the model — only hashed in Firestore


class Message(BaseModel):
    id: Optional[str] = None
    sender: str
    receiver: str
    message: str
    timestamp: Optional[str] = None  # ISO 8601 string
    conversation_id: Optional[str] = None