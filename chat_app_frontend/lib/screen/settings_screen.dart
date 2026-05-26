import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme.dart';


class SettingsScreen extends StatefulWidget {
  final String username;

  const SettingsScreen({super.key, required this.username});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  final _handleCtrl  = TextEditingController();
  final _handleFocus = FocusNode();
  bool _editingHandle   = false;
  bool _savingHandle    = false;
  String? _handleError;
  String _displayHandle = '';

  bool get _isDark => ThemeNotifier().isDark;

  @override
  void initState() {
    super.initState();
    _displayHandle = widget.username;
    _handleCtrl.text = widget.username;

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    ThemeNotifier().addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ThemeNotifier().removeListener(_onThemeChanged);
    _fadeCtrl.dispose();
    _handleCtrl.dispose();
    _handleFocus.dispose();
    super.dispose();
  }

  void _toggleTheme() {
    HapticFeedback.selectionClick();
    ThemeNotifier().toggle();
  }

  void _startEditHandle() {
    setState(() {
      _editingHandle = true;
      _handleError = null;
      _handleCtrl.text = _displayHandle;
    });
    Future.delayed(const Duration(milliseconds: 50), () {
      _handleFocus.requestFocus();
      _handleCtrl.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _handleCtrl.text.length,
      );
    });
  }

  Future<void> _saveHandle() async {
    final newHandle = _handleCtrl.text.trim();
    if (newHandle == _displayHandle) {
      setState(() => _editingHandle = false);
      return;
    }
    if (newHandle.length < 2) {
      setState(() => _handleError = 'at least 2 characters');
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(newHandle)) {
      setState(() => _handleError = 'letters, numbers and _ only');
      return;
    }

    setState(() { _savingHandle = true; _handleError = null; });

    // Simulate save (wire up your real API here)
    await Future.delayed(const Duration(milliseconds: 800));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', newHandle);

    if (mounted) {
      setState(() {
        _displayHandle = newHandle;
        _editingHandle = false;
        _savingHandle  = false;
      });
      _showToast('handle updated');
    }
  }

  void _cancelEdit() {
    setState(() {
      _editingHandle = false;
      _handleError   = null;
      _handleCtrl.text = _displayHandle;
    });
    _handleFocus.unfocus();
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: TextStyle(
            fontFamily: 'DMMono',
            fontSize: 13,
            color: AppTheme.of(context).textPrimary,
          )),
      backgroundColor: AppTheme.of(context).surfaceHigh,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: _buildAppBar(c),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: ListView(
          children: [
            // ── Profile Card ────────────────────────────────────────────────
            _ProfileCard(
              username: _displayHandle,
              isDark: _isDark,
              c: c,
              editingHandle: _editingHandle,
              savingHandle: _savingHandle,
              handleCtrl: _handleCtrl,
              handleFocus: _handleFocus,
              handleError: _handleError,
              onEditTap: _startEditHandle,
              onSave: _saveHandle,
              onCancel: _cancelEdit,
              onChanged: (_) {
                if (_handleError != null) setState(() => _handleError = null);
              },
            ),
            const SizedBox(height: 8),

            // ── Appearance ─────────────────────────────────────────────────
            _SectionHeader(label: 'APPEARANCE', c: c),
            _SettingsGroup(c: c, children: [
              _ThemeToggleTile(
                isDark: _isDark,
                onToggle: _toggleTheme,
                c: c,
              ),
            ]),
            const SizedBox(height: 8),

            // ── Account ─────────────────────────────────────────────────────
            _SectionHeader(label: 'ACCOUNT', c: c),
            _SettingsGroup(c: c, children: [
              _SettingsTile(
                icon: Icons.notifications_outlined,
                label: 'notifications',
                trailing: Switch(
                  value: true,
                  onChanged: (v) {},
                  activeThumbColor: c.accent,
                ),
                c: c,
              ),
              _Divider(c: c),
              _SettingsTile(
                icon: Icons.lock_outline_rounded,
                label: 'privacy',
                trailing: Icon(Icons.chevron_right_rounded, size: 18, color: c.textHint),
                onTap: () {},
                c: c,
              ),
              _Divider(c: c),
              _SettingsTile(
                icon: Icons.devices_rounded,
                label: 'active sessions',
                trailing: Icon(Icons.chevron_right_rounded, size: 18, color: c.textHint),
                onTap: () {},
                c: c,
              ),
            ]),
            const SizedBox(height: 8),

            // ── About ───────────────────────────────────────────────────────
            _SectionHeader(label: 'ABOUT', c: c),
            _SettingsGroup(c: c, children: [
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                label: 'version',
                trailing: Text('v2.0.0',
                    style: TextStyle(fontFamily: 'DMMono', fontSize: 12, color: c.textHint)),
                c: c,
              ),
              _Divider(c: c),
              _SettingsTile(
                icon: Icons.terminal_rounded,
                label: 'anonchat',
                trailing: Text('open source',
                    style: TextStyle(fontFamily: 'DMMono', fontSize: 12, color: c.accentDim)),
                onTap: () {},
                c: c,
              ),
            ]),
            const SizedBox(height: 8),

            // ── Danger Zone ─────────────────────────────────────────────────
            _SectionHeader(label: 'DANGER ZONE', c: c),
            _SettingsGroup(c: c, children: [
              _SettingsTile(
                icon: Icons.delete_outline_rounded,
                label: 'delete account',
                labelColor: c.danger,
                iconColor: c.danger,
                trailing: Icon(Icons.chevron_right_rounded, size: 18, color: c.danger.withValues(alpha: 0.5)),
                onTap: () => _showDeleteDialog(c),
                c: c,
              ),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(AppColors c) {
    return AppBar(
      backgroundColor: c.bg,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, size: 16, color: c.textSec),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('settings',
          style: TextStyle(
            fontFamily: 'DMMono',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
            letterSpacing: -0.3,
          )),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: c.border),
      ),
    );
  }

  void _showDeleteDialog(AppColors c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('delete account?',
            style: TextStyle(fontFamily: 'DMMono', color: c.textPrimary, fontSize: 16)),
        content: Text(
          'this is permanent. all messages and data will be removed.',
          style: TextStyle(fontFamily: 'DMMono', color: c.textSec, fontSize: 13, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel', style: TextStyle(fontFamily: 'DMMono', color: c.textSec)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('delete', style: TextStyle(fontFamily: 'DMMono', color: c.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Profile Card ──────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final String username;
  final bool isDark;
  final AppColors c;
  final bool editingHandle;
  final bool savingHandle;
  final TextEditingController handleCtrl;
  final FocusNode handleFocus;
  final String? handleError;
  final VoidCallback onEditTap;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final ValueChanged<String> onChanged;

  const _ProfileCard({
    required this.username,
    required this.isDark,
    required this.c,
    required this.editingHandle,
    required this.savingHandle,
    required this.handleCtrl,
    required this.handleFocus,
    required this.handleError,
    required this.onEditTap,
    required this.onSave,
    required this.onCancel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final avatarBg = avatarColor(username);
    final initials = avatarInitials(username);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          // Avatar + name section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Column(
              children: [
                // Avatar with online ring
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            avatarBg.withValues(alpha: 0.25),
                            avatarBg.withValues(alpha: 0.05),
                          ],
                        ),
                        border: Border.all(
                          color: avatarBg.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                    ),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: avatarBg.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: TextStyle(
                            fontFamily: 'DMMono',
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: avatarBg,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 4, right: 4,
                      child: GestureDetector(
                        onTap: () {}, // future: avatar change
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: c.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: c.bg, width: 2),
                          ),
                          child: Icon(Icons.camera_alt_rounded, size: 13, color: c.bg),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Handle display / edit
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: editingHandle
                      ? _HandleEditor(
                          key: const ValueKey('editor'),
                          ctrl: handleCtrl,
                          focus: handleFocus,
                          error: handleError,
                          saving: savingHandle,
                          onChanged: onChanged,
                          onSave: onSave,
                          onCancel: onCancel,
                          c: c,
                        )
                      : _HandleDisplay(
                          key: const ValueKey('display'),
                          username: username,
                          onEdit: onEditTap,
                          c: c,
                        ),
                ),
              ],
            ),
          ),

          // Stats row
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.border, width: 0.5)),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _StatItem(label: 'member since', value: 'today', c: c),
                  VerticalDivider(width: 0.5, color: c.border),
                  _StatItem(label: 'messages', value: '—', c: c),
                  VerticalDivider(width: 0.5, color: c.border),
                  _StatItem(label: 'status', value: 'active', c: c, valueColor: c.accent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HandleDisplay extends StatelessWidget {
  final String username;
  final VoidCallback onEdit;
  final AppColors c;

  const _HandleDisplay({super.key, required this.username, required this.onEdit, required this.c});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(username,
            style: TextStyle(
              fontFamily: 'DMMono',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
              letterSpacing: -0.5,
            )),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onEdit,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: c.surfaceHigh,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_rounded, size: 12, color: c.accent),
                const SizedBox(width: 5),
                Text('edit handle',
                    style: TextStyle(fontFamily: 'DMMono', fontSize: 11, color: c.accent, letterSpacing: 0.3)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HandleEditor extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focus;
  final String? error;
  final bool saving;
  final ValueChanged<String> onChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final AppColors c;

  const _HandleEditor({
    super.key,
    required this.ctrl,
    required this.focus,
    required this.error,
    required this.saving,
    required this.onChanged,
    required this.onSave,
    required this.onCancel,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 200,
          child: TextField(
            controller: ctrl,
            focusNode: focus,
            onChanged: onChanged,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DMMono',
              fontSize: 16,
              color: c.textPrimary,
              letterSpacing: 0.3,
            ),
            decoration: InputDecoration(
              hintText: 'new handle',
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              isDense: true,
              errorText: null,
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(error!,
              style: TextStyle(fontFamily: 'DMMono', fontSize: 11, color: c.danger)),
        ],
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionBtn(label: 'cancel', onTap: onCancel, color: c.textSec, bg: c.surfaceHigh, c: c),
            const SizedBox(width: 8),
            _ActionBtn(
              label: saving ? '...' : 'save',
              onTap: saving ? null : onSave,
              color: c.bg,
              bg: c.accent,
              c: c,
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color bg;
  final AppColors c;

  const _ActionBtn({required this.label, this.onTap, required this.color, required this.bg, required this.c});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
        ),
        child: Text(label,
            style: TextStyle(fontFamily: 'DMMono', fontSize: 12, color: color, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final AppColors c;
  final Color? valueColor;

  const _StatItem({required this.label, required this.value, required this.c, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                  fontFamily: 'DMMono',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? c.textPrimary,
                )),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(fontFamily: 'DMMono', fontSize: 9, color: c.textHint, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ── Theme Toggle Tile ─────────────────────────────────────────────────────────

class _ThemeToggleTile extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggle;
  final AppColors c;

  const _ThemeToggleTile({required this.isDark, required this.onToggle, required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Mode previews
          Row(
            children: [
              _ThemeChip(dark: true, selected: isDark, c: c),
              const SizedBox(width: 8),
              _ThemeChip(dark: false, selected: !isDark, c: c),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isDark ? 'dark mode' : 'light mode',
                    style: TextStyle(fontFamily: 'DMMono', fontSize: 14, color: c.textPrimary)),
                const SizedBox(height: 2),
                Text(isDark ? 'easy on the eyes' : 'bright and clear',
                    style: TextStyle(fontFamily: 'DMMono', fontSize: 11, color: c.textHint)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 50,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: isDark
                    ? c.accent.withValues(alpha: 0.2)
                    : const Color(0xFFFFC107).withValues(alpha: 0.2),
                border: Border.all(
                  color: isDark ? c.accent.withValues(alpha: 0.4) : const Color(0xFFFFC107).withValues(alpha: 0.4),
                ),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOutCubic,
                    left: isDark ? 4 : 22,
                    top: 4,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isDark ? c.accent : const Color(0xFFFFC107),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                        size: 12,
                        color: isDark ? AppTheme.bg : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final bool dark;
  final bool selected;
  final AppColors c;

  const _ThemeChip({required this.dark, required this.selected, required this.c});

  @override
  Widget build(BuildContext context) {
    final bg   = dark ? const Color(0xFF0A0A0B) : const Color(0xFFF5F5F7);
    final surf = dark ? const Color(0xFF1C1C1F) : const Color(0xFFFFFFFF);
    final text = dark ? const Color(0xFF00E87A) : const Color(0xFF00A855);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 40,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? c.accent : c.border,
          width: selected ? 1.5 : 1,
        ),
        boxShadow: selected
            ? [BoxShadow(color: c.accent.withValues(alpha: 0.2), blurRadius: 6)]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 3, width: 24, decoration: BoxDecoration(color: text, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 2),
            Container(height: 3, width: 16, decoration: BoxDecoration(color: surf, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 2),
            Container(height: 3, width: 20, decoration: BoxDecoration(color: surf, borderRadius: BorderRadius.circular(2))),
          ],
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final AppColors c;

  const _SectionHeader({required this.label, required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Text(label,
          style: TextStyle(
            fontFamily: 'DMMono',
            fontSize: 10,
            letterSpacing: 1.5,
            color: c.textHint,
          )),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  final AppColors c;

  const _SettingsGroup({required this.children, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;
  final AppColors c;
  final Color? labelColor;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.c,
    this.onTap,
    this.labelColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: (iconColor ?? c.accent).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconColor ?? c.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontFamily: 'DMMono',
                    fontSize: 14,
                    color: labelColor ?? c.textPrimary,
                  )),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final AppColors c;
  const _Divider({required this.c});

  @override
  Widget build(BuildContext context) =>
      Divider(indent: 60, height: 0.5, color: c.border, thickness: 0.5);
}