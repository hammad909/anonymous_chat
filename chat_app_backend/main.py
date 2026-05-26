from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.socket.socket_manager import socket_app, sio
from app.route.user_router import router as user_router

fastapi_app = FastAPI(title="Chat Server")

fastapi_app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

fastapi_app.include_router(user_router)


@fastapi_app.get("/")
async def root():
    return {"message": "Chat Server Running"}


# Mount FastAPI under the Socket.IO ASGI app
import socketio
app = socketio.ASGIApp(sio, other_asgi_app=fastapi_app)