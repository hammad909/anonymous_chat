import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/models.dart';

const String kServerUrl = 'http://192.168.1.105:8001';

// ── Callback typedefs ────────────────────────────────────────────────────────

typedef LoginResultCallback = void Function(
  bool success,
  Map<String, dynamic>? profile,
  List<ChatUser>? users,
  List<Map<String, dynamic>>? recentConversations,
  String? error,
);
typedef KickedCallback = void Function(String reason);
typedef UsersListCallback = void Function(List<ChatUser>);
typedef RecentConversationsCallback = void Function(List<Map<String, dynamic>>);
typedef ReceiveMessageCallback = void Function(ChatMessage);
typedef MessageSentCallback = void Function(ChatMessage);
typedef ChatHistoryCallback = void Function(String, List<ChatMessage>);
typedef UserJoinedCallback = void Function(String);
typedef UserOfflineCallback = void Function(String);
typedef UserTypingCallback = void Function(String);
typedef UserStopTypingCallback = void Function(String);
typedef MessageSeenCallback = void Function(String, String);
typedef ConnectionChangeCallback = void Function(bool);

// ── SocketService ─────────────────────────────────────────────────────────────

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  late IO.Socket socket;
  bool _initialized = false;

  // ── Multi-listener registries ────────────────────────────────────────────

  final _loginResultListeners        = <String, LoginResultCallback>{};
  final _kickedListeners             = <String, KickedCallback>{};
  final _usersListListeners          = <String, UsersListCallback>{};
  final _recentConversationsListeners= <String, RecentConversationsCallback>{};
  final _receiveMessageListeners     = <String, ReceiveMessageCallback>{};
  final _messageSentListeners        = <String, MessageSentCallback>{};
  final _chatHistoryListeners        = <String, ChatHistoryCallback>{};
  final _userJoinedListeners         = <String, UserJoinedCallback>{};
  final _userOfflineListeners        = <String, UserOfflineCallback>{};
  final _userTypingListeners         = <String, UserTypingCallback>{};
  final _userStopTypingListeners     = <String, UserStopTypingCallback>{};
  final _messageSeenListeners        = <String, MessageSeenCallback>{};
  final _connectionChangeListeners   = <String, ConnectionChangeCallback>{};

  bool get isConnected => _initialized && socket.connected;

  // ── Register / unregister ─────────────────────────────────────────────────

  void addLoginResultListener(String key, LoginResultCallback cb)         => _loginResultListeners[key] = cb;
  void addKickedListener(String key, KickedCallback cb)                   => _kickedListeners[key] = cb;
  void addUsersListListener(String key, UsersListCallback cb)              => _usersListListeners[key] = cb;
  void addRecentConversationsListener(String key, RecentConversationsCallback cb) => _recentConversationsListeners[key] = cb;
  void addReceiveMessageListener(String key, ReceiveMessageCallback cb)   => _receiveMessageListeners[key] = cb;
  void addMessageSentListener(String key, MessageSentCallback cb)         => _messageSentListeners[key] = cb;
  void addChatHistoryListener(String key, ChatHistoryCallback cb)         => _chatHistoryListeners[key] = cb;
  void addUserJoinedListener(String key, UserJoinedCallback cb)           => _userJoinedListeners[key] = cb;
  void addUserOfflineListener(String key, UserOfflineCallback cb)         => _userOfflineListeners[key] = cb;
  void addUserTypingListener(String key, UserTypingCallback cb)           => _userTypingListeners[key] = cb;
  void addUserStopTypingListener(String key, UserStopTypingCallback cb)   => _userStopTypingListeners[key] = cb;
  void addMessageSeenListener(String key, MessageSeenCallback cb)         => _messageSeenListeners[key] = cb;
  void addConnectionChangeListener(String key, ConnectionChangeCallback cb) => _connectionChangeListeners[key] = cb;

  void removeLoginResultListener(String key)         => _loginResultListeners.remove(key);
  void removeKickedListener(String key)              => _kickedListeners.remove(key);
  void removeUsersListListener(String key)           => _usersListListeners.remove(key);
  void removeRecentConversationsListener(String key) => _recentConversationsListeners.remove(key);
  void removeReceiveMessageListener(String key)      => _receiveMessageListeners.remove(key);
  void removeMessageSentListener(String key)         => _messageSentListeners.remove(key);
  void removeChatHistoryListener(String key)         => _chatHistoryListeners.remove(key);
  void removeUserJoinedListener(String key)          => _userJoinedListeners.remove(key);
  void removeUserOfflineListener(String key)         => _userOfflineListeners.remove(key);
  void removeUserTypingListener(String key)          => _userTypingListeners.remove(key);
  void removeUserStopTypingListener(String key)      => _userStopTypingListeners.remove(key);
  void removeMessageSeenListener(String key)         => _messageSeenListeners.remove(key);
  void removeConnectionChangeListener(String key)    => _connectionChangeListeners.remove(key);

  // ── Init ─────────────────────────────────────────────────────────────────

  void init() {
    if (_initialized) return;
    _initialized = true;

    socket = IO.io(
      kServerUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.onConnect((_) {
      for (final cb in _connectionChangeListeners.values) {
        cb(true);
      }
    });
    socket.onDisconnect((_) {
      for (final cb in _connectionChangeListeners.values) {
        cb(false);
      }
    });

    // ── Auth ──────────────────────────────────────────────────────────────

    socket.on('login_result', (data) {
      final d = Map<String, dynamic>.from(data as Map);
      final success = d['success'] as bool? ?? false;
      if (success) {
        final users = (d['users'] as List? ?? [])
            .map((u) => ChatUser.fromJson(Map<String, dynamic>.from(u)))
            .toList();
        final recent = (d['recent_conversations'] as List? ?? [])
            .map((m) => Map<String, dynamic>.from(m as Map))
            .toList();
        for (final cb in _loginResultListeners.values) {
          cb(true, Map<String, dynamic>.from(d['profile'] as Map? ?? {}), users, recent, null);
        }
      } else {
        for (final cb in _loginResultListeners.values) {
          cb(false, null, null, null, d['error'] as String? ?? 'login failed');
        }
      }
    });

    socket.on('kicked', (data) {
      final d = Map<String, dynamic>.from(data as Map);
      final reason = d['reason'] as String? ?? 'signed in elsewhere';
      for (final cb in _kickedListeners.values) {
        cb(reason);
      }
    });

    // ── Presence ──────────────────────────────────────────────────────────

    socket.on('users_list', (data) {
      final users = (data as List)
          .map((u) => ChatUser.fromJson(Map<String, dynamic>.from(u)))
          .toList();
      for (final cb in _usersListListeners.values) {
        cb(users);
      }
    });

    socket.on('recent_conversations', (data) {
      final list = (data as List)
          .map((m) => Map<String, dynamic>.from(m as Map))
          .toList();
      for (final cb in _recentConversationsListeners.values) {
        cb(list);
      }
    });

    socket.on('user_joined', (data) {
      final username = data['username'] as String;
      for (final cb in _userJoinedListeners.values) {
        cb(username);
      }
    });

    socket.on('user_offline', (data) {
      final username = data['username'] as String;
      for (final cb in _userOfflineListeners.values) {
        cb(username);
      }
    });

    // ── Messaging ─────────────────────────────────────────────────────────

    socket.on('receive_message', (data) {
      final msg = ChatMessage.fromJson(Map<String, dynamic>.from(data as Map));
      for (final cb in _receiveMessageListeners.values) {
        cb(msg);
      }
    });

    socket.on('message_sent', (data) {
      final msg = ChatMessage.fromJson(Map<String, dynamic>.from(data as Map));
      for (final cb in _messageSentListeners.values) {
        cb(msg);
      }
    });

    socket.on('chat_history', (data) {
      final d = Map<String, dynamic>.from(data as Map);
      final withUser = d['with_user'] as String;
      final messages = (d['messages'] as List)
          .map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m as Map)))
          .toList();
      for (final cb in _chatHistoryListeners.values) {
        cb(withUser, messages);
      }
    });

    // ── Typing / Read ─────────────────────────────────────────────────────

    socket.on('user_typing', (data) {
      final username = data['username'] as String;
      for (final cb in _userTypingListeners.values) {
        cb(username);
      }
    });

    socket.on('user_stop_typing', (data) {
      final username = data['username'] as String;
      for (final cb in _userStopTypingListeners.values) {
        cb(username);
      }
    });

    socket.on('message_seen', (data) {
      final by = data['by'] as String;
      final messageId = data['message_id'] as String;
      for (final cb in _messageSeenListeners.values) {
        cb(by, messageId);
      }
    });

    socket.connect();
  }

  // ── REST: register ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register(String username, String password,
      {String? avatar}) async {
    try {
      final res = await http.post(
        Uri.parse('$kServerUrl/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          if (avatar != null) 'avatar': avatar,
        }),
      );
      if (res.statusCode == 201) return {'success': true};
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return {'success': false, 'error': body['detail'] ?? 'registration failed'};
    } catch (_) {
      return {'success': false, 'error': 'cannot reach server'};
    }
  }

  // ── Socket: login ─────────────────────────────────────────────────────────

  void login(String username, String password) {
    socket.emit('login', {'username': username, 'password': password});
  }

  // ── Messaging ─────────────────────────────────────────────────────────────

  void sendMessage(String sender, String receiver, String message) =>
      socket.emit('send_message', {'sender': sender, 'receiver': receiver, 'message': message});

  void fetchHistory(String withUser, {int limit = 50}) =>
      socket.emit('fetch_history', {'with_user': withUser, 'limit': limit});

  void typing(String receiver) =>
      socket.emit('typing', {'receiver': receiver});

  void stopTyping(String receiver) =>
      socket.emit('stop_typing', {'receiver': receiver});

  void markRead(String sender, String messageId) =>
      socket.emit('message_read', {'sender': sender, 'message_id': messageId});

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  void disconnect() => socket.disconnect();
}