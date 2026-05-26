import 'package:chat_app_frontend/theme/theme.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isSelf;
  final bool showTime;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isSelf,
    this.showTime = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isSelf ? 64 : 12,
        right: isSelf ? 12 : 64,
        top: 2,
        bottom: showTime ? 0 : 2,
      ),
      child: Column(
        crossAxisAlignment:
            isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelf ? AppTheme.bubbleSelf : AppTheme.bubbleOther,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isSelf ? 18 : 4),
                bottomRight: Radius.circular(isSelf ? 4 : 18),
              ),
              border: Border.all(
                color: isSelf
                    ? AppTheme.accentDim.withValues(alpha: 0.25)
                    : AppTheme.border,
                width: 1,
              ),
            ),
            child: Text(
              message.message,
              style: const TextStyle(
                fontFamily: 'DMMono',
                fontSize: 13.5,
                color: AppTheme.textPrimary,
                height: 1.5,
              ),
            ),
          ),
          if (showTime)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 2, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.timestamp),
                    style: const TextStyle(
                      fontFamily: 'DMMono',
                      fontSize: 10,
                      color: AppTheme.textHint,
                    ),
                  ),
                  if (isSelf) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.seen ? Icons.done_all : Icons.done,
                      size: 12,
                      color: message.seen ? AppTheme.accent : AppTheme.textHint,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}