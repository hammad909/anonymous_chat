import 'package:chat_app_frontend/service/socket_service.dart';
import 'package:chat_app_frontend/theme/theme.dart';
import 'package:chat_app_frontend/widgets/user_title.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../widgets/user_avatar.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  final List<ChatUser> initialUsers;
  final List<Map<String, dynamic>> initialRecentConversations;

  const HomeScreen({
    super.key,
    required this.username,
    this.initialUsers = const [],
    this.initialRecentConversations = const [],
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _key = 'home_screen';

  final Map<String, ChatUser> _usersMap = {};
  final Map<String, String> _lastMessages = {};
  final Map<String, DateTime> _lastTimes = {};

  bool _connected = false;
  String _search = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    for (final u in widget.initialUsers) {
      if (u.username != widget.username) _usersMap[u.username] = u;
    }
    _applyRecentConversations(widget.initialRecentConversations);
    _bindSocket();
  }

  @override
  void dispose() {
    final svc = SocketService();
    svc.removeConnectionChangeListener(_key);
    svc.removeUsersListListener(_key);
    svc.removeRecentConversationsListener(_key);
    svc.removeUserJoinedListener(_key);
    svc.removeUserOfflineListener(_key);
    svc.removeReceiveMessageListener(_key);
    svc.removeMessageSentListener(_key);
    super.dispose();
  }

  void _applyRecentConversations(List<Map<String, dynamic>> convs) {
    for (final m in convs) {
      final sender   = m['sender']   as String? ?? '';
      final receiver = m['receiver'] as String? ?? '';
      final other    = sender == widget.username ? receiver : sender;
      if (other.isEmpty || other == widget.username) continue;
      _lastMessages[other] = m['message'] as String? ?? '';
      final ts = m['timestamp'] as String?;
      if (ts != null) _lastTimes[other] = DateTime.tryParse(ts) ?? DateTime.now();
      _usersMap.putIfAbsent(other, () => ChatUser(username: other, isOnline: false));
    }
  }

  void _bindSocket() {
    final svc = SocketService();

    svc.addConnectionChangeListener(_key, (connected) {
      if (mounted) setState(() => _connected = connected);
    });

    svc.addUsersListListener(_key, (users) {
      if (!mounted) return;
      setState(() {
        for (final u in users) {
          if (u.username == widget.username) continue;
          _usersMap[u.username] = u;
        }
      });
    });

    svc.addRecentConversationsListener(_key, (convs) {
      if (!mounted) return;
      setState(() => _applyRecentConversations(convs));
    });

    svc.addUserJoinedListener(_key, (username) {
      if (!mounted || username == widget.username) return;
      setState(() {
        final existing = _usersMap[username];
        _usersMap[username] = existing != null
            ? existing.copyWith(isOnline: true)
            : ChatUser(username: username, isOnline: true);
      });
    });

    svc.addUserOfflineListener(_key, (username) {
      if (!mounted) return;
      setState(() {
        final existing = _usersMap[username];
        if (existing != null) {
          _usersMap[username] = existing.copyWith(
            isOnline: false,
            lastSeen: DateTime.now().toIso8601String(),
          );
        }
      });
    });

    // THE FIX: keyed listeners — HomeScreen and ChatScreen both get these
    // events simultaneously without overwriting each other.
    svc.addReceiveMessageListener(_key, (msg) {
      if (!mounted) return;
      final other = msg.sender == widget.username ? msg.receiver : msg.sender;
      setState(() {
        _lastMessages[other] = msg.message;
        _lastTimes[other]    = msg.timestamp;
        _usersMap.putIfAbsent(other, () => ChatUser(username: other, isOnline: false));
      });
    });

    svc.addMessageSentListener(_key, (msg) {
      if (!mounted) return;
      final other = msg.sender == widget.username ? msg.receiver : msg.sender;
      setState(() {
        _lastMessages[other] = msg.message;
        _lastTimes[other]    = msg.timestamp;
        _usersMap.putIfAbsent(other, () => ChatUser(username: other, isOnline: false));
      });
    });

    _connected = svc.isConnected;
  }

  void _openChat(String otherUser) {
    Navigator.pushNamed(context, '/chat', arguments: {
      'currentUser': widget.username,
      'otherUser':   otherUser,
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('sign out?',
            style: TextStyle(fontFamily: 'DMMono', color: AppTheme.textPrimary, fontSize: 16)),
        content: const Text('your account stays — sign back in anytime.',
            style: TextStyle(fontFamily: 'DMMono', color: AppTheme.textSec, fontSize: 13)),
actions: [
  IconButton(
    icon: const Icon(Icons.settings_outlined, size: 20),
    color: AppTheme.textHint,
    onPressed: () {
      Navigator.pushNamed(
        context,
        '/settings',
        arguments: {
          'username': widget.username,
        },
      );
    },
  ),

  IconButton(
    icon: const Icon(Icons.logout_rounded, size: 18),
    onPressed: _logout,
    color: AppTheme.textHint,
  ),
],
      ),
    );
    if (confirmed == true && mounted) {
      SocketService().disconnect();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('username');
      await prefs.remove('password');
      // ignore: use_build_context_synchronously
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  // ── Derived lists ────────────────────────────────────────────────────────

  List<ChatUser> get _conversations {
    final result = _lastMessages.keys
        .where((u) => u != widget.username)
        .map((u) => _usersMap[u] ?? ChatUser(username: u, isOnline: false))
        .toList();
    result.sort((a, b) {
      final ta = _lastTimes[a.username] ?? DateTime(2000);
      final tb = _lastTimes[b.username] ?? DateTime(2000);
      return tb.compareTo(ta);
    });
    return result;
  }

  List<ChatUser> get _people {
    final q = _search.toLowerCase();
    final list = _usersMap.values
        .where((u) => u.username != widget.username)
        .where((u) => q.isEmpty || u.username.toLowerCase().contains(q))
        .toList();
    list.sort((a, b) {
      if (a.isOnline != b.isOnline) return a.isOnline ? -1 : 1;
      return a.username.compareTo(b.username);
    });
    return list;
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: _buildAppBar(),
      body: _selectedIndex == 0 ? _buildChatsTab() : _buildPeopleTab(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.bg,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: AppTheme.border),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: UserAvatar(username: widget.username, isOnline: _connected, size: 34),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('anonchat',
              style: TextStyle(
                fontFamily: 'DMMono', fontSize: 15, fontWeight: FontWeight.w700,
                color: AppTheme.accent, letterSpacing: -0.3,
              )),
          Row(
            children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  color: _connected ? AppTheme.accent : AppTheme.danger,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                _connected ? 'connected' : 'reconnecting...',
                style: TextStyle(
                  fontFamily: 'DMMono', fontSize: 10,
                  color: _connected ? AppTheme.accentDim : AppTheme.danger,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded, size: 18),
          onPressed: _logout,
          color: AppTheme.textHint,
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    final onlineCount = _people.where((u) => u.isOnline).length;
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() {
          _selectedIndex = i;
          if (i == 1) _search = '';
        }),
        backgroundColor: AppTheme.bg,
        selectedItemColor: AppTheme.accent,
        unselectedItemColor: AppTheme.textHint,
        selectedLabelStyle: const TextStyle(fontFamily: 'DMMono', fontSize: 11, letterSpacing: 0.5),
        unselectedLabelStyle: const TextStyle(fontFamily: 'DMMono', fontSize: 11, letterSpacing: 0.5),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: _navIcon(Icons.chat_bubble_outline_rounded, _conversations.length, AppTheme.accent),
            activeIcon: _navIcon(Icons.chat_bubble_rounded, _conversations.length, AppTheme.accent),
            label: 'chats',
          ),
          BottomNavigationBarItem(
            icon: _navIcon(Icons.people_outline_rounded, onlineCount, AppTheme.accentDim),
            activeIcon: _navIcon(Icons.people_rounded, onlineCount, AppTheme.accentDim),
            label: 'people',
          ),
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon, int count, Color badgeColor) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: 22),
        if (count > 0)
          Positioned(
            right: -4, top: -2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text('$count',
                  style: const TextStyle(fontFamily: 'DMMono', fontSize: 9, color: AppTheme.bg, height: 1),
                  textAlign: TextAlign.center),
            ),
          ),
      ],
    );
  }

  // ── CHATS tab ────────────────────────────────────────────────────────────

  Widget _buildChatsTab() {
    final convos = _conversations;
    if (convos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.textHint, size: 40),
            const SizedBox(height: 14),
            const Text('no chats yet',
                style: TextStyle(fontFamily: 'DMMono', fontSize: 14, color: AppTheme.textHint)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => setState(() => _selectedIndex = 1),
              child: const Text('go to people to start one →',
                  style: TextStyle(fontFamily: 'DMMono', fontSize: 12, color: AppTheme.accentDim)),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: convos.length,
      separatorBuilder: (_, _) =>
          const Divider(indent: 72, height: 0, color: AppTheme.border, thickness: 0.4),
      itemBuilder: (context, i) {
        final user = convos[i];
        return UserTile(
          user: user,
          lastMessage: _lastMessages[user.username],
          lastMessageTime: _lastTimes[user.username],
          onTap: () => _openChat(user.username),
        );
      },
    );
  }

  // ── PEOPLE tab ───────────────────────────────────────────────────────────

  Widget _buildPeopleTab() {
    final people = _people;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            style: const TextStyle(fontFamily: 'DMMono', fontSize: 13, color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: 'search people...',
              prefixIcon: Icon(Icons.search, color: AppTheme.textHint, size: 18),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: people.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline_rounded, color: AppTheme.textHint, size: 40),
                      SizedBox(height: 14),
                      Text('no one else here yet',
                          style: TextStyle(fontFamily: 'DMMono', fontSize: 14, color: AppTheme.textHint)),
                    ],
                  ),
                )
              : _buildPeopleList(people),
        ),
      ],
    );
  }

  Widget _buildPeopleList(List<ChatUser> people) {
    final online  = people.where((u) => u.isOnline).toList();
    final offline = people.where((u) => !u.isOnline).toList();
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (online.isNotEmpty) ...[
          _sectionHeader('ONLINE — ${online.length}'),
          ...online.map(_peopleTile),
          if (offline.isNotEmpty) const Divider(height: 0, color: AppTheme.border, thickness: 0.4),
        ],
        if (offline.isNotEmpty) ...[
          _sectionHeader('OFFLINE — ${offline.length}'),
          ...offline.map(_peopleTile),
        ],
      ],
    );
  }

  Widget _sectionHeader(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        child: Text(label,
            style: const TextStyle(fontFamily: 'DMMono', fontSize: 10, letterSpacing: 1.2, color: AppTheme.textHint)),
      );

  Widget _peopleTile(ChatUser user) => InkWell(
        onTap: () => _openChat(user.username),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              UserAvatar(username: user.username, isOnline: user.isOnline, size: 42),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.username,
                        style: const TextStyle(
                          fontFamily: 'DMMono', fontSize: 14, fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        )),
                    const SizedBox(height: 2),
                    Text(
                      user.isOnline ? 'online' : _formatLastSeen(user.lastSeen),
                      style: TextStyle(
                        fontFamily: 'DMMono', fontSize: 11,
                        color: user.isOnline ? AppTheme.accentDim : AppTheme.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              if (_lastMessages.containsKey(user.username))
                const Icon(Icons.chat_bubble_rounded, size: 14, color: AppTheme.textHint),
            ],
          ),
        ),
      );

  String _formatLastSeen(String? lastSeen) {
    if (lastSeen == null) return 'offline';
    final dt = DateTime.tryParse(lastSeen)?.toLocal();
    if (dt == null) return 'offline';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}