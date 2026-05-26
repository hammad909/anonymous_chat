import 'package:chat_app_frontend/screen/auth_screen.dart';
import 'package:chat_app_frontend/screen/chat_screen.dart';
import 'package:chat_app_frontend/screen/home_screen.dart';
import 'package:chat_app_frontend/screen/settings_screen.dart';
import 'package:chat_app_frontend/service/socket_service.dart';
import 'package:chat_app_frontend/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/models.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0A0B),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  SocketService().init();
  runApp(const ChatApp());
}

class ChatApp extends StatefulWidget {
  const ChatApp({super.key});

  @override
  State<ChatApp> createState() => _ChatAppState();
}

class _ChatAppState extends State<ChatApp> {
  @override
  void initState() {
    super.initState();
    // Rebuild whenever the theme changes
    ThemeNotifier().addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});

    // Sync system nav bar color to active theme
    final isDark = ThemeNotifier().isDark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: isDark ? const Color(0xFF0A0A0B) : const Color(0xFFF5F5F7),
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));
  }

  @override
  void dispose() {
    ThemeNotifier().removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeNotifier().isDark;

    return AnimatedTheme(
      data: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: MaterialApp(
        title: 'Anon Chat',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        initialRoute: '/auth',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/auth':
            case '/onboarding':
              return _fadeRoute(const AuthScreen());

            case '/home':
              final args = settings.arguments;
              if (args is Map<String, dynamic>) {
                final username = args['username'] as String;
                final users =
                    (args['users'] as List<ChatUser>?) ?? <ChatUser>[];
                final recent = (args['recentConversations']
                        as List<Map<String, dynamic>>?) ??
                    <Map<String, dynamic>>[];
                return _fadeRoute(HomeScreen(
                  username: username,
                  initialUsers: users,
                  initialRecentConversations: recent,
                ));
              }
              return _fadeRoute(
                  HomeScreen(username: args as String? ?? ''));

            case '/chat':
              final args = settings.arguments as Map<String, dynamic>;
              return _slideRoute(ChatScreen(
                currentUser: args['currentUser'] as String,
                otherUser: args['otherUser'] as String,
              ));

   case '/settings':
  final args = settings.arguments as Map<String, dynamic>?;
  return _slideRoute(SettingsScreen(
    username: args?['username'] as String? ?? '',
  ));

            default:
              return _fadeRoute(const AuthScreen());
          }
        },
      ),
    );
  }

  PageRoute _fadeRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, _, _) => page,
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      );

  PageRoute _slideRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, _, _) => page,
        transitionsBuilder: (_, anim, _, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 320),
      );
}