import 'package:chat_app_frontend/theme/theme.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import 'user_avatar.dart';

class UserTile extends StatelessWidget {
  final ChatUser user;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final bool hasUnread;
  final VoidCallback onTap;

  const UserTile({
    super.key,
    required this.user,
    this.lastMessage,
    this.lastMessageTime,
    this.hasUnread = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            UserAvatar(username: user.username, isOnline: user.isOnline, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.username,
                          style: TextStyle(
                            fontFamily: 'DMMono',
                            fontSize: 14,
                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                            color: AppTheme.textPrimary,
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (lastMessageTime != null)
                        Text(
                          _formatTime(lastMessageTime!),
                          style: TextStyle(
                            fontFamily: 'DMMono',
                            fontSize: 10,
                            color: hasUnread ? AppTheme.accent : AppTheme.textHint,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage ?? (user.isOnline ? 'online' : _lastSeenText()),
                          style: TextStyle(
                            fontFamily: 'DMMono',
                            fontSize: 12,
                            color: lastMessage != null
                                ? (hasUnread ? AppTheme.textSec : AppTheme.textHint)
                                : (user.isOnline ? AppTheme.accentDim : AppTheme.textHint),
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _lastSeenText() {
    if (user.lastSeen == null) return 'offline';
    final dt = DateTime.tryParse(user.lastSeen!);
    if (dt == null) return 'offline';
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    if (now.difference(local).inHours < 24 &&
        now.day == local.day) {
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }
    return '${local.day}/${local.month}';
  }
}