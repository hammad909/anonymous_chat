import 'dart:async';
import 'package:chat_app_frontend/service/socket_service.dart';
import 'package:chat_app_frontend/theme/theme.dart';
import 'package:chat_app_frontend/widgets/chat_bubbles.dart';
import 'package:chat_app_frontend/widgets/date_separator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/user_avatar.dart';

class ChatScreen extends StatefulWidget {
  final String currentUser;
  final String otherUser;

  const ChatScreen({
    super.key,
    required this.currentUser,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  // Unique key for this chat session's listeners
  late final String _key;

  final _messages   = <ChatMessage>[];
  final _inputCtrl  = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode  = FocusNode();

  bool _otherTyping   = false;
  bool _otherOnline   = false;
  String? _otherLastSeen;
  bool _historyLoaded = false;
  bool _sending       = false;
  Timer? _typingTimer;
  bool _isTyping      = false;
  bool _showScrollDown = false;

  @override
  void initState() {
    super.initState();
    // Use the pair of usernames as a unique key so multiple chat screens
    // (if ever stacked) don't share listeners
    _key = 'chat_${widget.currentUser}_${widget.otherUser}';
    WidgetsBinding.instance.addObserver(this);
    _scrollCtrl.addListener(_onScroll);
    _bindSocket();
    SocketService().fetchHistory(widget.otherUser);
  }

  @override
  void dispose() {
    // Clean up only this screen's listeners
    final svc = SocketService();
    svc.removeChatHistoryListener(_key);
    svc.removeReceiveMessageListener(_key);
    svc.removeMessageSentListener(_key);
    svc.removeUserTypingListener(_key);
    svc.removeUserStopTypingListener(_key);
    svc.removeMessageSeenListener(_key);
    svc.removeUsersListListener(_key);
    svc.removeUserOfflineListener(_key);
    svc.removeUserJoinedListener(_key);

    WidgetsBinding.instance.removeObserver(this);
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _inputCtrl.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    final atBottom = _scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 80;
    if (atBottom != !_showScrollDown) {
      setState(() => _showScrollDown = !atBottom);
    }
  }

  void _bindSocket() {
    final svc = SocketService();

    svc.addChatHistoryListener(_key, (withUser, messages) {
      if (withUser == widget.otherUser && mounted) {
        setState(() {
          _messages..clear()..addAll(messages);
          _historyLoaded = true;
        });
        _scrollToBottom(jump: true);
        for (final m in messages) {
          if (m.sender == widget.otherUser && !m.seen) {
            svc.markRead(widget.otherUser, m.id);
          }
        }
      }
    });

    svc.addReceiveMessageListener(_key, (msg) {
      if ((msg.sender == widget.otherUser && msg.receiver == widget.currentUser) ||
          (msg.sender == widget.currentUser && msg.receiver == widget.otherUser)) {
        if (mounted) {
          setState(() => _messages.add(msg));
          _scrollToBottom();
          if (msg.sender == widget.otherUser) {
            svc.markRead(widget.otherUser, msg.id);
          }
        }
      }
    });

    svc.addMessageSentListener(_key, (msg) {
      if (msg.sender == widget.currentUser && msg.receiver == widget.otherUser) {
        if (mounted) {
          setState(() {
            final idx = _messages.indexWhere((m) => m.id == msg.id);
            if (idx == -1) _messages.add(msg);
            _sending = false;
          });
          _scrollToBottom();
        }
      }
    });

    svc.addUserTypingListener(_key, (username) {
      if (username == widget.otherUser && mounted) {
        setState(() => _otherTyping = true);
        _scrollToBottom();
      }
    });

    svc.addUserStopTypingListener(_key, (username) {
      if (username == widget.otherUser && mounted) {
        setState(() => _otherTyping = false);
      }
    });

    svc.addMessageSeenListener(_key, (by, messageId) {
      if (by == widget.otherUser && mounted) {
        setState(() {
          for (final m in _messages) {
            if (m.id == messageId) m.seen = true;
          }
        });
      }
    });

    svc.addUsersListListener(_key, (users) {
      final other = users.where((u) => u.username == widget.otherUser).firstOrNull;
      if (other != null && mounted) {
        setState(() {
          _otherOnline   = other.isOnline;
          _otherLastSeen = other.lastSeen;
        });
      }
    });

    svc.addUserOfflineListener(_key, (username) {
      if (username == widget.otherUser && mounted) {
        setState(() {
          _otherOnline   = false;
          _otherLastSeen = DateTime.now().toIso8601String();
        });
      }
    });

    svc.addUserJoinedListener(_key, (username) {
      if (username == widget.otherUser && mounted) {
        setState(() => _otherOnline = true);
      }
    });
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        if (jump) {
          _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
        } else {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  void _onTextChanged(String value) {
    final svc = SocketService();
    if (value.isNotEmpty && !_isTyping) {
      _isTyping = true;
      svc.typing(widget.otherUser);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        svc.stopTyping(widget.otherUser);
      }
    });
  }

  void _sendMessage() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    HapticFeedback.lightImpact();
    _inputCtrl.clear();

    if (_isTyping) {
      _isTyping = false;
      _typingTimer?.cancel();
      SocketService().stopTyping(widget.otherUser);
    }

    setState(() => _sending = true);
    SocketService().sendMessage(widget.currentUser, widget.otherUser, text);
  }

  @override
  void didChangeMetrics() {
    // ignore: deprecated_member_use
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    if (bottomInset > 0) _scrollToBottom();
  }

  String _statusText() {
    if (_otherOnline) return 'online';
    if (_otherLastSeen != null) {
      final dt = DateTime.tryParse(_otherLastSeen!);
      if (dt != null) {
        final diff = DateTime.now().difference(dt.toLocal());
        if (diff.inMinutes < 1) return 'just now';
        if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
        if (diff.inHours < 24) return '${diff.inHours}h ago';
      }
    }
    return 'offline';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                _buildMessageList(),
                if (_showScrollDown)
                  Positioned(
                    right: 16,
                    bottom: 8,
                    child: _ScrollDownButton(onTap: _scrollToBottom),
                  ),
              ],
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 16),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          UserAvatar(username: widget.otherUser, isOnline: _otherOnline, size: 34),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.otherUser,
                  style: const TextStyle(
                    fontFamily: 'DMMono', fontSize: 14, fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  )),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _otherTyping ? 'typing...' : _statusText(),
                  key: ValueKey(_otherTyping ? 'typing' : _statusText()),
                  style: TextStyle(
                    fontFamily: 'DMMono', fontSize: 10,
                    color: _otherTyping
                        ? AppTheme.accent
                        : (_otherOnline ? AppTheme.accentDim : AppTheme.textHint),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, size: 18),
          color: AppTheme.textSec,
          onPressed: () {},
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(0.5),
        child: Divider(height: 0.5, color: AppTheme.border),
      ),
    );
  }

  Widget _buildMessageList() {
    if (!_historyLoaded) {
      return const Center(
        child: SizedBox(
          width: 24, height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentDim),
        ),
      );
    }

    if (_messages.isEmpty && !_otherTyping) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(username: widget.otherUser, isOnline: _otherOnline, size: 56),
            const SizedBox(height: 16),
            Text(widget.otherUser,
                style: const TextStyle(
                  fontFamily: 'DMMono', fontSize: 16, fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                )),
            const SizedBox(height: 6),
            const Text('start a conversation',
                style: TextStyle(fontFamily: 'DMMono', fontSize: 12, color: AppTheme.textHint)),
          ],
        ),
      );
    }

    final items = _buildItems();
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      itemCount: items.length + (_otherTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (_otherTyping && index == items.length) return const TypingIndicator();
        return items[index];
      },
    );
  }

  List<Widget> _buildItems() {
    final widgets = <Widget>[];
    DateTime? lastDate;

    for (int i = 0; i < _messages.length; i++) {
      final msg     = _messages[i];
      final msgDate = msg.timestamp.toLocal();

      if (lastDate == null ||
          lastDate.day   != msgDate.day   ||
          lastDate.month != msgDate.month ||
          lastDate.year  != msgDate.year) {
        widgets.add(DateSeparator(date: msgDate));
        lastDate = msgDate;
      }

      final isSelf        = msg.sender == widget.currentUser;
      final isLast        = i == _messages.length - 1;
      final nextDifferent = !isLast && _messages[i + 1].sender != msg.sender;
      final bigGap        = !isLast &&
          _messages[i + 1].timestamp.difference(msg.timestamp).inMinutes > 5;

      widgets.add(MessageBubble(
        message: msg,
        isSelf: isSelf,
        showTime: isLast || nextDifferent || bigGap,
      ));
    }
    return widgets;
  }

  Widget _buildInputBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      padding: EdgeInsets.only(
        left: 12, right: 8, top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0
            ? 10
            : 10 + MediaQuery.of(context).padding.bottom * 0.5,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: TextField(
                controller: _inputCtrl,
                focusNode: _focusNode,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                onChanged: _onTextChanged,
                style: const TextStyle(
                  fontFamily: 'DMMono', fontSize: 13.5,
                  color: AppTheme.textPrimary, height: 1.5,
                ),
                decoration: const InputDecoration(
                  hintText: 'message...',
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _SendButton(onTap: _sendMessage, sending: _sending),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _SendButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool sending;
  const _SendButton({required this.onTap, required this.sending});

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1, end: 0.88)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: AppTheme.accent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: widget.sending
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.bg),
                )
              : const Icon(Icons.arrow_upward_rounded, color: AppTheme.bg, size: 18),
        ),
      ),
    );
  }
}

class _ScrollDownButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ScrollDownButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppTheme.surfaceHigh,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSec, size: 20),
      ),
    );
  }
}