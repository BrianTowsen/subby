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

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ Input formatters for OTP
import 'package:flutter/services.dart';

enum LoginMethod { phone, email }

class LoginView extends StatefulWidget {
  const LoginView({
    super.key,
    this.width,
    this.height,
    this.defaultCountryCode,
    this.afterLoginRouteName,
    this.createAccountRouteName,
  });

  final double? width;
  final double? height;

  final String? defaultCountryCode;

  /// Where to go after successful login (default: homePage)
  final String? afterLoginRouteName;

  /// Where to go when user taps "Create account" (default: createAccountPage)
  final String? createAccountRouteName;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  static const Color _ink = Color(0xFF017374);
  static const Color _inkMute = Color(0xFF5A6675);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFEEF1F4);
  static const Color _hairline = Color(0xFFEEF1F4);
  static const Color _hairlineOnSurface = Color(0xFFD7DCE3);
  // Brand accent — TEAL (field icons / focus). Primary action is ink.
  static const Color _teal = Color(0xFF017374);
  // Status
  static const Color _live = Color(0xFFE5771E);
  static const Color _coral = Color(0xFFE5771E);
  // Type
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const String _monoFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = 24;
  static const double _vPad = 14;
  static const double _radius = 12;

  static const String _prefsKeyLoginMethod = 'subby_login_method';
  static const int _otpLen = 6;

  LoginMethod _method = LoginMethod.phone;

  // Phone
  final _countryCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // OTP boxes
  final List<TextEditingController> _otpCtrls =
      List.generate(_otpLen, (_) => TextEditingController());
  final List<FocusNode> _otpNodes = List.generate(_otpLen, (_) => FocusNode());

  // Email
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _sendingCode = false;
  bool _verifyingCode = false;
  bool _codeSent = false;

  bool _emailLoading = false;
  bool _obscurePw = true;

  String? _verificationId;
  String? _error;

  static const String _defaultCreateAccountRoute = 'createAccountPage';
  static const String _defaultAfterLoginRoute = 'homePage';

  // =========================================================
  // ✅ TYPOGRAPHY
  // =========================================================
  TextStyle _subtitleStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: _bodyFont,
        color: _inkMute,
      );

  TextStyle _toggleTextStyle(FlutterFlowTheme t, {required bool selected}) =>
      t.labelMedium.override(
        fontFamily: _bodyFont,
        color: selected ? _paper : _ink,
        fontWeight: FontWeight.w800,
      );

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

  TextStyle _buttonTextStyle(FlutterFlowTheme t, {required Color color}) =>
      t.labelLarge.override(
        fontFamily: _bodyFont,
        color: color,
        fontWeight: FontWeight.w900,
      );

  TextStyle _snackTextStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: _bodyFont,
        color: _ink,
      );

  TextStyle _otpDigitStyle(FlutterFlowTheme t) => t.bodyMedium.override(
        fontFamily: _bodyFont,
        fontWeight: FontWeight.w800,
        fontSize: 18,
        color: _ink,
      );
  // =========================================================

  @override
  void initState() {
    super.initState();
    _countryCtrl.text = (widget.defaultCountryCode?.trim().isNotEmpty ?? false)
        ? widget.defaultCountryCode!.trim()
        : '+27';
    _loadLastMethod();
  }

  Future<void> _loadLastMethod() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKeyLoginMethod) ?? 'phone';
      final m = saved == 'email' ? LoginMethod.email : LoginMethod.phone;
      if (!mounted) return;
      setState(() => _method = m);
    } catch (_) {
      // ignore
    }
  }

  Future<void> _saveLastMethod(LoginMethod m) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKeyLoginMethod,
        m == LoginMethod.email ? 'email' : 'phone',
      );
    } catch (_) {
      // ignore
    }
  }

  @override
  void dispose() {
    _countryCtrl.dispose();
    _phoneCtrl.dispose();
    for (final c in _otpCtrls) {
      c.dispose();
    }
    for (final n in _otpNodes) {
      n.dispose();
    }
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ---------------------------
  // Helpers
  // ---------------------------
  void _setError(String? msg) {
    if (!mounted) return;
    setState(() => _error = msg);
  }

  void _clearOtp() {
    for (final c in _otpCtrls) {
      c.text = '';
    }
  }

  String _otpValue() => _otpCtrls.map((c) => c.text.trim()).join();

  String _normalizeToE164({
    required String countryCode,
    required String rawPhone,
  }) {
    var digits = rawPhone.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (digits.startsWith('+')) return digits;

    // SA convenience: 081... -> +2781...
    if (countryCode == '+27' && digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    final cc = countryCode.startsWith('+') ? countryCode : '+$countryCode';
    return '$cc$digits';
  }

  // Borderless field decoration (Option C underline style).
  InputDecoration _bareDeco(FlutterFlowTheme theme, String hint) {
    return InputDecoration(
      isDense: true,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      contentPadding: EdgeInsets.zero,
      hintText: hint,
      hintStyle: _hintStyle(theme),
    );
  }

  void _showSubbySnack(String message, {bool success = true}) {
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
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: _hairline, width: 1),
          ),
          duration: const Duration(milliseconds: 1600),
          content: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _ink.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  success ? Icons.check_rounded : Icons.info_outline_rounded,
                  size: 16,
                  color: _ink,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message, style: _snackTextStyle(theme)),
              ),
            ],
          ),
        ),
      );
  }

  Widget _circleBack(FlutterFlowTheme t) {
    return GestureDetector(
      onTap: () => context.safePop(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _surface,
          shape: BoxShape.circle,
          border: Border.all(color: _hairline, width: 1),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 15, color: _inkMute),
      ),
    );
  }

  // ---------------------------
  // Auth flows
  // ---------------------------
  Future<void> _sendOtp() async {
    _setError(null);

    if (_phoneCtrl.text.trim().isEmpty) {
      _setError('Please enter your phone number.');
      return;
    }

    final e164 = _normalizeToE164(
      countryCode: _countryCtrl.text,
      rawPhone: _phoneCtrl.text,
    );

    setState(() {
      _sendingCode = true;
      _codeSent = false;
      _verificationId = null;
      _clearOtp();
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: e164,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (cred) async {
          final res = await FirebaseAuth.instance.signInWithCredential(cred);
          await _postLogin(res.user);
        },
        verificationFailed: (e) {
          _setError(e.message ?? 'Verification failed.');
        },
        codeSent: (id, _) {
          setState(() {
            _verificationId = id;
            _codeSent = true;
          });

          if (_otpNodes.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) _otpNodes.first.requestFocus();
            });
          }

          _showSubbySnack('OTP sent.', success: true);
        },
        codeAutoRetrievalTimeout: (id) => _verificationId = id,
      );
    } catch (e) {
      _setError('Could not send OTP: $e');
    } finally {
      if (mounted) setState(() => _sendingCode = false);
    }
  }

  Future<void> _verifyOtp() async {
    _setError(null);

    if ((_verificationId ?? '').isEmpty) {
      _setError('Please request an OTP first.');
      return;
    }

    final code = _otpValue();
    if (code.length != _otpLen) {
      _setError('Please enter the full OTP code.');
      return;
    }

    setState(() => _verifyingCode = true);

    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      final res = await FirebaseAuth.instance.signInWithCredential(cred);
      await _postLogin(res.user);
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? e.code);
    } catch (e) {
      _setError('OTP verify failed: $e');
    } finally {
      if (mounted) setState(() => _verifyingCode = false);
    }
  }

  Future<void> _loginWithEmail() async {
    _setError(null);

    final email = _emailCtrl.text.trim();
    final pw = _passwordCtrl.text;

    if (email.isEmpty) {
      _setError('Please enter your email.');
      return;
    }
    if (pw.isEmpty) {
      _setError('Please enter your password.');
      return;
    }

    setState(() => _emailLoading = true);

    try {
      final res = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pw,
      );
      await _postLogin(res.user);
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? e.code);
    } catch (e) {
      _setError('Login failed: $e');
    } finally {
      if (mounted) setState(() => _emailLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    _setError(null);

    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _setError('Enter your email first.');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showSubbySnack('Password reset email sent.', success: true);
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? e.code);
    } catch (e) {
      _setError('Reset failed: $e');
    }
  }

  /// ✅ Post-auth step: ensure Firestore user doc exists, then go Home.
  Future<void> _postLogin(User? user) async {
    if (user == null) return;

    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final now = Timestamp.now();

    await ref.set({
      'uid': user.uid,
      'email': (user.email ?? '').trim(),
      'phone_number': (user.phoneNumber ?? '').trim(),
      'active': true,
      'last_login': now,
    }, SetOptions(merge: true));

    context.goNamed(widget.afterLoginRouteName ?? _defaultAfterLoginRoute);
  }

  // ---------------------------
  // UI pieces (Option C — minimal underline)
  // ---------------------------
  Widget _slidingToggle(FlutterFlowTheme theme) {
    final isPhone = _method == LoginMethod.phone;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _hairline, width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final pillW = (w - 4) / 2;

          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                alignment:
                    isPhone ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  width: pillW,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: _ink,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        setState(() {
                          _method = LoginMethod.phone;
                          _error = null;
                        });
                        await _saveLastMethod(LoginMethod.phone);
                      },
                      child: Center(
                        child: Text(
                          'Phone',
                          style: _toggleTextStyle(theme, selected: isPhone),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        setState(() {
                          _method = LoginMethod.email;
                          _error = null;
                        });
                        await _saveLastMethod(LoginMethod.email);
                      },
                      child: Center(
                        child: Text(
                          'Email',
                          style: _toggleTextStyle(theme, selected: !isPhone),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // Full-width ink primary button.
  Widget _inkButton(
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
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: _ink,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_paper),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: _paper),
                      const SizedBox(width: 8),
                    ],
                    Text(label, style: _buttonTextStyle(theme, color: _paper)),
                  ],
                ),
        ),
      ),
    );
  }

  // Full-width outline secondary button.
  Widget _outlineButton(
    FlutterFlowTheme theme, {
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _hairlineOnSurface, width: 1),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: _inkMute),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: theme.labelLarge.override(
                fontFamily: _bodyFont,
                color: _ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Underline field wrapper.
  Widget _uUnderline({
    required FlutterFlowTheme theme,
    required String label,
    required Widget row,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _hairline, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: _uLabelStyle(theme)),
          const SizedBox(height: 8),
          row,
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
          Icon(Icons.error_outline, size: 18, color: _coral),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: theme.bodyMedium.override(
                fontFamily: _bodyFont,
                color: _coral,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _otpBoxes(FlutterFlowTheme theme) {
    Widget box(int i) {
      return SizedBox(
        width: 44,
        child: TextField(
          controller: _otpCtrls[i],
          focusNode: _otpNodes[i],
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          textAlign: TextAlign.center,
          maxLength: 1,
          cursorColor: _teal,
          style: _otpDigitStyle(theme),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: _surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _hairlineOnSurface, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _teal, width: 1.7),
            ),
          ),
          onChanged: (v) {
            if (v.length > 1) {
              final digits = v.replaceAll(RegExp(r'\D'), '').split('');
              if (digits.isEmpty) return;
              for (int k = 0; k < _otpLen; k++) {
                _otpCtrls[k].text = k < digits.length ? digits[k] : '';
              }
              final next =
                  digits.length >= _otpLen ? _otpLen - 1 : digits.length;
              if (next >= 0 && next < _otpLen) _otpNodes[next].requestFocus();
              setState(() {});
              return;
            }

            if (v.isNotEmpty) {
              if (i < _otpLen - 1) {
                _otpNodes[i + 1].requestFocus();
              } else {
                FocusScope.of(context).unfocus();
              }
            } else {
              if (i > 0) _otpNodes[i - 1].requestFocus();
            }
            setState(() {});
          },
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_otpLen, box),
    );
  }

  Widget _phoneForm(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _uUnderline(
          theme: theme,
          label: 'Phone number',
          row: Row(
            children: [
              const Icon(Icons.phone_outlined, size: 19, color: _teal),
              const SizedBox(width: 10),
              SizedBox(
                width: 46,
                child: TextField(
                  controller: _countryCtrl,
                  keyboardType: TextInputType.phone,
                  cursorColor: _teal,
                  decoration: _bareDeco(theme, '+27'),
                  style: _fieldTextStyle(theme),
                ),
              ),
              Container(
                width: 1,
                height: 22,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: _hairlineOnSurface,
              ),
              Expanded(
                child: TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  cursorColor: _teal,
                  decoration: _bareDeco(theme, '081 234 5678'),
                  style: _fieldTextStyle(theme),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _inkButton(
          theme,
          label: _codeSent ? 'Resend code' : 'Send code',
          icon: Icons.sms_outlined,
          loading: _sendingCode,
          onPressed: _sendingCode ? null : _sendOtp,
        ),
        if (_codeSent) ...[
          const SizedBox(height: 22),
          Text('OTP CODE', style: _uLabelStyle(theme)),
          const SizedBox(height: 12),
          _otpBoxes(theme),
          const SizedBox(height: 20),
          _inkButton(
            theme,
            label: 'Verify & continue',
            icon: Icons.lock_open_outlined,
            loading: _verifyingCode,
            onPressed: _verifyingCode ? null : _verifyOtp,
          ),
        ],
      ],
    );
  }

  Widget _emailForm(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _uUnderline(
          theme: theme,
          label: 'Email',
          row: Row(
            children: [
              const Icon(Icons.mail_outline_rounded, size: 19, color: _teal),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  cursorColor: _teal,
                  decoration: _bareDeco(theme, 'you@example.com'),
                  style: _fieldTextStyle(theme),
                ),
              ),
            ],
          ),
        ),
        _uUnderline(
          theme: theme,
          label: 'Password',
          row: Row(
            children: [
              const Icon(Icons.lock_outline_rounded, size: 19, color: _teal),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePw,
                  cursorColor: _teal,
                  decoration: _bareDeco(theme, 'Enter password'),
                  style: _fieldTextStyle(theme),
                ),
              ),
              InkWell(
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
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _forgotPassword,
            child: Text(
              'Forgot password?',
              style: theme.labelMedium.override(
                fontFamily: _bodyFont,
                color: _inkMute,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _inkButton(
          theme,
          label: 'Log in',
          icon: Icons.login,
          loading: _emailLoading,
          onPressed: _emailLoading ? null : _loginWithEmail,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    final double width = widget.width ?? MediaQuery.sizeOf(context).width;
    final double height = widget.height ?? MediaQuery.sizeOf(context).height;

    // ---------------------------------------------------------
    // ✅ OPTION C — MINIMAL UNDERLINE
    // ---------------------------------------------------------
    return SizedBox(
      width: width,
      height: height,
      child: SafeArea(
        child: Container(
          color: _paper,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(_hPad, _vPad, _hPad, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== TOP ROW: back =====
                Row(children: [_circleBack(theme), const Spacer()]),

                const SizedBox(height: 20),

                // ===== TITLE =====
                Text(
                  'Log in',
                  style: theme.titleLarge.override(
                    fontFamily: _displayFont,
                    color: _ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 30,
                    lineHeight: 1.05,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Subby account access.',
                  style: _subtitleStyle(theme).copyWith(fontSize: 13),
                ),

                const SizedBox(height: 24),

                // Toggle
                _slidingToggle(theme),
                const SizedBox(height: 8),

                // Forms
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: (_method == LoginMethod.phone)
                      ? Container(
                          key: const ValueKey('phone'),
                          child: _phoneForm(theme),
                        )
                      : Container(
                          key: const ValueKey('email'),
                          child: _emailForm(theme),
                        ),
                ),

                _errorBanner(theme),
                const SizedBox(height: 24),

                // Create account (outline)
                _outlineButton(
                  theme,
                  label: 'Create account',
                  icon: Icons.person_add_alt_1_outlined,
                  onPressed: () => context.pushNamed(
                    widget.createAccountRouteName ?? _defaultCreateAccountRoute,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
