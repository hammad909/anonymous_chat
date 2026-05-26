class ChatMessage {
  final String id;
  final String sender;
  final String receiver;
  final String message;
  final DateTime timestamp;
  final String conversationId;
  bool seen;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.message,
    required this.timestamp,
    required this.conversationId,
    this.seen = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] ?? '',
        sender: json['sender'] ?? '',
        receiver: json['receiver'] ?? '',
        message: json['message'] ?? '',
        timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
        conversationId: json['conversation_id'] ?? '',
        seen: json['seen'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender': sender,
        'receiver': receiver,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'conversation_id': conversationId,
      };
}

class ChatUser {
  final String username;
  final String? avatar;
  final bool isOnline;
  final String? lastSeen;
  final String? sid;
  String? lastMessage;
  DateTime? lastMessageTime;

  ChatUser({
    required this.username,
    this.avatar,
    this.isOnline = false,
    this.lastSeen,
    this.sid,
    this.lastMessage,
    this.lastMessageTime,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) => ChatUser(
        username: json['username'] ?? '',
        avatar: json['avatar'],
        isOnline: json['is_online'] ?? false,
        lastSeen: json['last_seen'],
        sid: json['sid'],
      );

  ChatUser copyWith({
    bool? isOnline,
    String? lastSeen,
    String? sid,
    String? lastMessage,
    DateTime? lastMessageTime,
  }) =>
      ChatUser(
        username: username,
        avatar: avatar,
        isOnline: isOnline ?? this.isOnline,
        lastSeen: lastSeen ?? this.lastSeen,
        sid: sid ?? this.sid,
        lastMessage: lastMessage ?? this.lastMessage,
        lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      );
}