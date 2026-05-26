import 'package:chat_app_frontend/theme/theme.dart';
import 'package:flutter/material.dart';


class UserAvatar extends StatelessWidget {
  final String username;
  final bool isOnline;
  final double size;

  const UserAvatar({
    super.key,
    required this.username,
    this.isOnline = false,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    final color = avatarColor(username);
    final initials = avatarInitials(username);
    return SizedBox(
      width: size + 6,
      height: size + 6,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: TextStyle(
                fontFamily: 'DMMono',
                fontSize: size * 0.38,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0,
              ),
            ),
          ),
          if (isOnline)
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: size * 0.27,
                height: size * 0.27,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.bg, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}