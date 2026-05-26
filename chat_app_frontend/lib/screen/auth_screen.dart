import 'package:chat_app_frontend/service/socket_service.dart';
import 'package:chat_app_frontend/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  static const _key = 'auth_screen';

  final _usernameCtrl  = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isRegister       = false;
  bool _loading          = false;
  bool _obscurePassword  = true;
  String? _error;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _tryAutoLogin();
  }

  @override
  void dispose() {
    SocketService().removeLoginResultListener(_key);
    SocketService().removeKickedListener(_key);
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _tryAutoLogin() async {
    final prefs      = await SharedPreferences.getInstance();
    final savedUser  = prefs.getString('username');
    final savedPass  = prefs.getString('password');
    if (savedUser == null || savedPass == null || !mounted) return;

    final svc = SocketService();
    svc.addLoginResultListener(_key, (success, profile, users, recent, error) {
      if (!mounted) return;
      if (success) _navigateHome(savedUser, users ?? [], recent ?? []);
      // Silent fail — show login screen normally
    });
    svc.login(savedUser, savedPass);
  }

  void _submit() {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (username.isEmpty) { setState(() => _error = 'enter a username'); return; }
    if (username.length < 2) { setState(() => _error = 'username needs at least 2 characters'); return; }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) { setState(() => _error = 'letters, numbers and _ only'); return; }
    if (password.isEmpty) { setState(() => _error = 'enter a password'); return; }
    if (_isRegister && password.length < 4) { setState(() => _error = 'password needs at least 4 characters'); return; }

    setState(() { _loading = true; _error = null; });

    final svc = SocketService();

    if (_isRegister) {
      svc.register(username, password).then((result) {
        if (!mounted) return;
        if (result['success'] == true) {
          _doSocketLogin(username, password);
        } else {
          setState(() { _loading = false; _error = result['error'] ?? 'registration failed'; });
        }
      });
    } else {
      _doSocketLogin(username, password);
    }
  }

  void _doSocketLogin(String username, String password) {
    final svc = SocketService();
    svc.addLoginResultListener(_key, (success, profile, users, recent, error) async {
      if (!mounted) return;
      if (success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', username);
        await prefs.setString('password', password);
        _navigateHome(username, users ?? [], recent ?? []);
      } else {
        setState(() { _loading = false; _error = error ?? 'invalid username or password'; });
      }
    });
    svc.login(username, password);
  }

  void _navigateHome(String username, List<ChatUser> users, List<Map<String, dynamic>> recentConversations) {
    Navigator.pushReplacementNamed(
      context,
      '/home',
      arguments: {
        'username': username,
        'users': users,
        'recentConversations': recentConversations,
      },
    );
  }

  void _toggleMode() {
    setState(() { _isRegister = !_isRegister; _error = null; _passwordCtrl.clear(); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 2),
                Row(
                  children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.terminal, color: AppTheme.accent, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Text('anonchat',
                        style: TextStyle(
                          fontFamily: 'DMMono', fontSize: 22, fontWeight: FontWeight.w700,
                          color: AppTheme.accent, letterSpacing: -0.5,
                        )),
                  ],
                ),
                const SizedBox(height: 40),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _isRegister ? 'create your\nidentity.' : 'welcome\nback.',
                    key: ValueKey(_isRegister),
                    style: const TextStyle(
                      fontFamily: 'DMMono', fontSize: 32, fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary, height: 1.15, letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _isRegister ? 'pick a name and a password.' : 'sign in to continue.',
                  style: const TextStyle(fontFamily: 'DMMono', fontSize: 13, color: AppTheme.textSec, height: 1.6),
                ),
                const SizedBox(height: 36),
                TextField(
                  controller: _usernameCtrl,
                  focusNode: _usernameFocus,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
                  onChanged: (_) { if (_error != null) setState(() => _error = null); },
                  style: const TextStyle(fontFamily: 'DMMono', fontSize: 15, color: AppTheme.textPrimary, letterSpacing: 0.3),
                  decoration: const InputDecoration(
                    hintText: 'username',
                    prefixText: '> ',
                    prefixStyle: TextStyle(fontFamily: 'DMMono', color: AppTheme.accent, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordCtrl,
                  focusNode: _passwordFocus,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  onChanged: (_) { if (_error != null) setState(() => _error = null); },
                  style: const TextStyle(fontFamily: 'DMMono', fontSize: 15, color: AppTheme.textPrimary, letterSpacing: 0.3),
                  decoration: InputDecoration(
                    hintText: 'password',
                    prefixText: '# ',
                    prefixStyle: const TextStyle(fontFamily: 'DMMono', color: AppTheme.accentDim, fontSize: 15),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppTheme.textHint, size: 18,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.danger, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(fontFamily: 'DMMono', fontSize: 12, color: AppTheme.danger)),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: AppTheme.bg,
                      disabledBackgroundColor: AppTheme.accentDim.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.bg))
                        : Text(
                            _isRegister ? 'create account' : 'sign in',
                            style: const TextStyle(
                              fontFamily: 'DMMono', fontSize: 14,
                              fontWeight: FontWeight.w700, letterSpacing: 0.5,
                            )),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: _loading ? null : _toggleMode,
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontFamily: 'DMMono', fontSize: 12, color: AppTheme.textSec),
                        children: [
                          TextSpan(text: _isRegister ? 'already have an account? ' : 'no account? '),
                          TextSpan(
                            text: _isRegister ? 'sign in' : 'register here',
                            style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                const Center(
                  child: Text('v2.0.0 · password-protected',
                      style: TextStyle(fontFamily: 'DMMono', fontSize: 10, color: AppTheme.textHint, letterSpacing: 1)),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}