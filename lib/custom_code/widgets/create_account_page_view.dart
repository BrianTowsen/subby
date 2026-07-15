// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom widgets

import 'index.dart'; // Imports other custom widgets

import 'index.dart'; // Imports other custom widgets

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateAccountPageView extends StatefulWidget {
  const CreateAccountPageView({
    super.key,
    this.width,
    this.height,
    this.afterCompleteRouteName, // default: homePage
    this.loginRouteName, // default: loginPage
  });

  final double? width;
  final double? height;

  final String? afterCompleteRouteName;
  final String? loginRouteName;

  @override
  State<CreateAccountPageView> createState() => _CreateAccountPageViewState();
}

class _CreateAccountPageViewState extends State<CreateAccountPageView> {
  // ─── SUBBY PALETTE (LOCK) — synced with DashboardPageView v6 ───────────
  static const Color _ink = Color(0xFF1E282E);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _hairline = Color(0xFFEAEEF0);
  static const Color _hairlineOnSurface = Color(0xFFDCE3E6);
  static const Color _steel = Color(0xFF3D4F66); // hero header background
  static const Color _accent = Color(0xFFE7E247); // primary CTA fill
  static const Color _coral = Color(0xFF566670);
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = 20;
  static const double _radius = 12;

  final _displayNameCtrl = TextEditingController();
  final FocusNode _displayNameFocus = FocusNode();

  final _emailCtrl = TextEditingController();
  final FocusNode _emailFocus = FocusNode();

  final _passwordCtrl = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();

  bool _saving = false;
  bool _obscurePw = true;

  String? _error;
  String _status = '';

  // =========================================================
  // TYPOGRAPHY
  // =========================================================
  TextStyle _uLabelStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: _bodyFont,
        color: _inkMute,
        letterSpacing: 0.6,
        fontWeight: FontWeight.w800,
        fontSize: 11,
      );

  TextStyle _fieldTextStyle(FlutterFlowTheme t) => t.bodyMedium.override(
        fontFamily: _bodyFont,
        color: _ink,
        fontWeight: FontWeight.w700,
        fontSize: 16,
        letterSpacing: 0.0,
      );

  TextStyle _hintStyle(FlutterFlowTheme t) => t.bodyMedium.override(
        fontFamily: _bodyFont,
        color: _inkMute.withOpacity(0.7),
        fontWeight: FontWeight.w600,
        fontSize: 16,
        letterSpacing: 0.0,
      );

  TextStyle _snackTextStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: _bodyFont,
        color: _paper,
        fontWeight: FontWeight.w700,
      );
  // =========================================================

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _displayNameFocus.dispose();
    _emailCtrl.dispose();
    _emailFocus.dispose();
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  DocumentReference<Map<String, dynamic>> _userRef(String uid) {
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  void _setError(String? msg) {
    if (!mounted) return;
    setState(() => _error = msg);
  }

  void _showSubbySnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    final theme = FlutterFlowTheme.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          elevation: 0,
          backgroundColor: const Color(0xFF3D4F66),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide.none,
          ),
          duration: const Duration(milliseconds: 1600),
          content: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _paper.withOpacity(0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isError ? Icons.error_outline_rounded : Icons.check_rounded,
                  size: 16,
                  color: _paper,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(msg, style: _snackTextStyle(theme))),
            ],
          ),
        ),
      );
  }

  // =========================================================
  // MINIMAL UNDERLINE FIELD — keyboard action = Done (blue tick)
  // =========================================================
  Widget _uField(
    FlutterFlowTheme theme, {
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _hairlineOnSurface, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: _uLabelStyle(theme)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, size: 19, color: _ink),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: keyboardType,
                  textInputAction: TextInputAction.done,
                  textCapitalization: textCapitalization,
                  obscureText: obscureText,
                  cursorColor: _steel,
                  style: _fieldTextStyle(theme),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: hint,
                    hintStyle: _hintStyle(theme),
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(FlutterFlowTheme theme) {
    final msg = (_error ?? '').trim();
    if (msg.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _coral.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _coral.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: _coral),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg,
                style: const TextStyle(
                    fontFamily: _bodyFont,
                    color: _coral,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _statusBanner(FlutterFlowTheme theme) {
    final msg = _status.trim();
    if (msg.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _ink.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _hairline),
      ),
      child: Text(msg,
          style: const TextStyle(
              fontFamily: _bodyFont, fontWeight: FontWeight.w700, color: _ink)),
    );
  }

  // ACCENT (yellow) primary button — ink label.
  Widget _accentButton(
    FlutterFlowTheme theme, {
    required String label,
    required VoidCallback? onPressed,
    bool loading = false,
    IconData? icon,
  }) {
    final disabled = onPressed == null || loading;
    return GestureDetector(
      onTap: disabled ? null : onPressed,
      child: AnimatedOpacity(
        opacity: disabled ? 0.7 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 54,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(_radius),
          ),
          alignment: Alignment.center,
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_ink),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: _ink),
                      const SizedBox(width: 8),
                    ],
                    Text(label,
                        style: const TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: _ink)),
                  ],
                ),
        ),
      ),
    );
  }

  // ---------------------------
  // NEW STYLE — steel hero
  // ---------------------------
  Widget _heroCircle(IconData icon, VoidCallback onTap) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: _paper.withOpacity(0.14), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: _paper),
          ),
        ),
      );

  Widget _hero() => Container(
        width: double.infinity,
        color: _steel,
        padding: EdgeInsets.fromLTRB(
            _hPad, MediaQuery.of(context).padding.top + 8, _hPad, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _heroCircle(
                    Icons.arrow_back_ios_new_rounded, () => context.safePop()),
                Expanded(
                  child: Center(
                    child: Text('GET STARTED',
                        style: TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                            color: _paper.withOpacity(0.55))),
                  ),
                ),
                const SizedBox(width: 38, height: 38),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Create account',
                style: TextStyle(
                    fontFamily: _displayFont,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    height: 1.0,
                    color: _paper)),
            const SizedBox(height: 8),
            Text('Set up your Subby account in seconds.',
                style: TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _paper.withOpacity(0.6))),
          ],
        ),
      );

  Future<void> _createAccount() async {
    if (_saving) return;
    _setError(null);
    setState(() {
      _status = 'Creating account…';
      _saving = true;
    });

    final displayName = _displayNameCtrl.text.trim();
    final email = _emailCtrl.text.trim().toLowerCase();
    final pw = _passwordCtrl.text;

    if (displayName.isEmpty) {
      setState(() {
        _saving = false;
        _status = '';
      });
      _setError('Please enter your display name.');
      _showSubbySnack('Please enter your display name.', isError: true);
      _displayNameFocus.requestFocus();
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _saving = false;
        _status = '';
      });
      _setError('Please enter a valid email address.');
      _showSubbySnack('Please enter a valid email.', isError: true);
      _emailFocus.requestFocus();
      return;
    }
    if (pw.isEmpty || pw.length < 6) {
      setState(() {
        _saving = false;
        _status = '';
      });
      _setError('Password must be at least 6 characters.');
      _showSubbySnack('Password must be at least 6 characters.', isError: true);
      _passwordFocus.requestFocus();
      return;
    }

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pw,
      );
      final user = cred.user;
      if (user == null) {
        throw Exception('Account created but user is null.');
      }
      try {
        await user.updateDisplayName(displayName);
      } catch (_) {}

      final now = Timestamp.now();
      await _userRef(user.uid).set({
        'uid': user.uid,
        'email': email,
        'phone_number': (user.phoneNumber ?? '').trim(),
        'active': true,
        'display_name': displayName,
        'created_time': now,
        'last_login': now,
      }, SetOptions(merge: true));

      if (!mounted) return;
      final target = widget.afterCompleteRouteName ?? 'homePage';
      setState(() => _status = 'Saved ✅ Redirecting…');
      _showSubbySnack('Account created. Redirecting…');
      context.goNamed(target);
    } on FirebaseAuthException catch (e) {
      final msg = (e.message ?? e.code).toString();
      debugPrint('CreateAccountPageView: FirebaseAuthException: $msg');
      setState(() => _status = '');
      String pretty = msg;
      if (e.code == 'email-already-in-use') {
        pretty = 'That email is already in use. Try logging in instead.';
      } else if (e.code == 'invalid-email') {
        pretty = 'That email address is invalid.';
      } else if (e.code == 'weak-password') {
        pretty = 'That password is too weak.';
      }
      _setError(pretty);
      _showSubbySnack(pretty, isError: true);
    } catch (e) {
      debugPrint('CreateAccountPageView: Create error: $e');
      setState(() => _status = '');
      _setError('Could not create your account. Please try again.');
      _showSubbySnack('Could not create account.', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final double width = widget.width ?? MediaQuery.sizeOf(context).width;
    final double height = widget.height ?? MediaQuery.sizeOf(context).height;

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        color: _paper,
        child: Column(
          children: [
            _hero(),
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(_hPad, 16, _hPad, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _uField(
                        theme,
                        label: 'Display name',
                        controller: _displayNameCtrl,
                        focusNode: _displayNameFocus,
                        icon: Icons.person_outline_rounded,
                        hint: 'e.g. Brian Towsen',
                        textCapitalization: TextCapitalization.words,
                      ),
                      _uField(
                        theme,
                        label: 'Email',
                        controller: _emailCtrl,
                        focusNode: _emailFocus,
                        icon: Icons.mail_outline_rounded,
                        hint: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      _uField(
                        theme,
                        label: 'Password',
                        controller: _passwordCtrl,
                        focusNode: _passwordFocus,
                        icon: Icons.lock_outline_rounded,
                        hint: 'Create a password',
                        obscureText: _obscurePw,
                        trailing: InkWell(
                          onTap: () => setState(() => _obscurePw = !_obscurePw),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              _obscurePw
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: _inkMute,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 17, color: _steel),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Use at least 6 characters for your password.',
                                style: const TextStyle(
                                    fontFamily: _bodyFont,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _inkMute),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _errorBanner(theme),
                      _statusBanner(theme),
                      const SizedBox(height: 24),
                      _accentButton(
                        theme,
                        label: 'Create account',
                        icon: Icons.check_circle_outline,
                        loading: _saving,
                        onPressed: _saving ? null : _createAccount,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: GestureDetector(
                          onTap: () => context.goNamed(
                            widget.loginRouteName ?? 'loginPage',
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: RichText(
                              text: const TextSpan(
                                text: 'Already have an account? ',
                                style: TextStyle(
                                    fontFamily: _bodyFont,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _faint),
                                children: [
                                  TextSpan(
                                    text: 'Log in',
                                    style: TextStyle(
                                        fontFamily: _bodyFont,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: _steel),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
