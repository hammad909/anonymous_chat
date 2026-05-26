import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate("app/firebase/serviceAccountKey.json")
firebase_admin.initialize_app(cred)

db = firestore.client()

users_ref = db.collection("users")
messages_ref = db.collection("messages")