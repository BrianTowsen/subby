// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

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
  static const double _hPad = 24;
  static const double _vPad = 24;
  static const double _radius = 16;

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
  // ✅ TYPOGRAPHY (MATCH ListingResultsPageView)
  // =========================================================
  TextStyle _titleStyle(FlutterFlowTheme t) => t.titleLarge.override(
        fontFamily: t.titleLargeFamily,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.2,
      );

  TextStyle _subtitleStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: t.bodySmallFamily,
        color: t.secondaryText,
      );

  TextStyle _labelStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: t.bodySmallFamily,
        color: t.secondaryText,
        fontWeight: FontWeight.w600,
        fontSize: 11,
      );

  TextStyle _fieldTextStyle(FlutterFlowTheme t) => t.bodyMedium.override(
        fontFamily: t.bodyMediumFamily,
      );

  TextStyle _hintStyle(FlutterFlowTheme t) => t.bodyMedium.override(
        fontFamily: t.bodyMediumFamily,
        color: t.secondaryText,
      );

  TextStyle _snackTextStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: t.bodySmallFamily,
        color: t.primaryText,
      );

  TextStyle _buttonTextStyle(FlutterFlowTheme t, {required Color color}) =>
      t.labelLarge.override(
        fontFamily: t.labelLargeFamily,
        color: color,
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

  // ✅ Subby-style snackbar (floating, bordered, secondaryBackground)
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
          backgroundColor: theme.secondaryBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isError ? theme.error.withOpacity(0.35) : theme.alternate,
              width: 1,
            ),
          ),
          duration: const Duration(milliseconds: 1600),
          content: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color:
                      (isError ? theme.error : theme.primary).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isError ? Icons.error_outline_rounded : Icons.check_rounded,
                  size: 16,
                  color: isError ? theme.error : theme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(msg, style: _snackTextStyle(theme)),
              ),
            ],
          ),
        ),
      );
  }

  InputDecoration _inputDeco(
    FlutterFlowTheme theme, {
    required String hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: _hintStyle(theme),
      filled: true,
      fillColor: theme.primaryBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.alternate, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.error, width: 1.6),
      ),
      suffixIcon: suffix,
    );
  }

  BoxDecoration _liftedCardDecoration(FlutterFlowTheme t) => BoxDecoration(
        color: t.primaryBackground,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: t.alternate, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  Widget _circleBack(FlutterFlowTheme t) {
    return GestureDetector(
      onTap: () => context.safePop(),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: t.secondaryBackground,
          shape: BoxShape.circle,
          border: Border.all(color: t.alternate, width: 1),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: t.secondaryText,
        ),
      ),
    );
  }

  Widget _errorBanner(FlutterFlowTheme theme) {
    final msg = (_error ?? '').trim();
    if (msg.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.error.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.error.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: theme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: theme.bodyMedium.override(
                fontFamily: theme.bodyMediumFamily,
                color: theme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
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
        color: theme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.alternate),
      ),
      child: Text(
        msg,
        style: theme.bodyMedium.override(
          fontFamily: theme.bodyMediumFamily,
          fontWeight: FontWeight.w700,
          color: theme.primaryText,
        ),
      ),
    );
  }

  Widget _primaryPillButton(
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
        opacity: disabled ? 0.75 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: theme.primary,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: theme.primary, width: 1),
          ),
          alignment: Alignment.center,
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: _buttonTextStyle(theme, color: Colors.white),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _createAccount() async {
    if (_saving) return;

    _setError(null);
    setState(() {
      _status = 'Creating account…';
      _saving = true;
    });

    final displayName = _displayNameCtrl.text.trim();
    final email = _emailCtrl.text.trim().toLowerCase(); // ✅ normalize
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

      // Keep FirebaseAuth displayName in sync (optional but useful)
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

      setState(() {
        _status = '';
      });

      // Friendlier common errors
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
      setState(() {
        _status = '';
      });
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
      child: SafeArea(
        child: Container(
          color: theme.primaryBackground,
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(_hPad, _vPad, _hPad, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Bar (ListingResults pattern)
                  Row(
                    children: [
                      _circleBack(theme),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Create account', style: _titleStyle(theme)),
                            const SizedBox(height: 2),
                            Text(
                              'Set up your Subby account',
                              style: _subtitleStyle(theme),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Card (lifted like listing cards)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: _liftedCardDecoration(theme),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Display name', style: _labelStyle(theme)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _displayNameCtrl,
                          focusNode: _displayNameFocus,
                          textCapitalization: TextCapitalization.words,
                          style: _fieldTextStyle(theme),
                          decoration: _inputDeco(
                            theme,
                            hint: 'e.g. Brian Towsen',
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text('Email', style: _labelStyle(theme)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailCtrl,
                          focusNode: _emailFocus,
                          keyboardType: TextInputType.emailAddress,
                          style: _fieldTextStyle(theme),
                          decoration: _inputDeco(
                            theme,
                            hint: 'you@example.com',
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text('Password', style: _labelStyle(theme)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordCtrl,
                          focusNode: _passwordFocus,
                          obscureText: _obscurePw,
                          style: _fieldTextStyle(theme),
                          decoration: _inputDeco(
                            theme,
                            hint: 'Create a password',
                            suffix: IconButton(
                              onPressed: () =>
                                  setState(() => _obscurePw = !_obscurePw),
                              icon: Icon(
                                _obscurePw
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: theme.secondaryText,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  _errorBanner(theme),
                  _statusBanner(theme),
                  const SizedBox(height: 16),

                  _primaryPillButton(
                    theme,
                    label: 'Create account',
                    icon: Icons.check_circle_outline,
                    loading: _saving,
                    onPressed: _saving ? null : _createAccount,
                  ),

                  const SizedBox(height: 12),

                  Center(
                    child: TextButton(
                      onPressed: () => context.goNamed(
                        widget.loginRouteName ?? 'loginPage',
                      ),
                      child: Text(
                        'Already have an account? Log in',
                        style: theme.labelMedium.override(
                          fontFamily: theme.labelMediumFamily,
                          color: theme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
