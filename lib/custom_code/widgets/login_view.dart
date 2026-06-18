// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

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
  // less-is-more system · ported from Clutch Putt · lime → yellow.
  // Inline = authoritative for this file. Grep `SUBBY PALETTE (LOCK)` to sync.
  //
  // Neutrals
  static const Color _ink = Color(0xFF16202E);
  static const Color _inkMute = Color(0xFF5A6675);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFEEF1F4);
  static const Color _hairline = Color(0xFFEEF1F4);
  static const Color _hairlineOnSurface = Color(0xFFD7DCE3);
  // Brand accent — YELLOW. Always ink foreground, never white.
  static const Color _spark = Color(0xFFAEE03F); // primary CTA / ranked accent
  static const Color _sparkInk = Color(0xFF16202E);
  // Status
  static const Color _live =
      Color(0xFFFF6A2B); // orange — live / open-now / warning
  static const Color _coral = Color(0xFFE0531C);
  // Type
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const String _monoFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  // Match Subby system spacing
  static const double _hPad = 24;
  static const double _vPad = 24;
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
  // ✅ TYPOGRAPHY (match ListingResultsPageView)
  // =========================================================
  TextStyle _titleStyle(FlutterFlowTheme t) => t.titleLarge.override(
        fontFamily: _displayFont,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.2,
      );

  TextStyle _subtitleStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: _bodyFont,
        color: _inkMute,
      );

  TextStyle _chipLabelStyle(FlutterFlowTheme t) => t.labelMedium.override(
        fontFamily: _bodyFont,
      );

  TextStyle _toggleTextStyle(FlutterFlowTheme t, {required bool selected}) =>
      t.labelMedium.override(
        fontFamily: _bodyFont,
        color: selected ? _paper : _ink,
      );

  TextStyle _labelStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: _bodyFont,
        color: _inkMute,
        fontWeight: FontWeight.w600,
        fontSize: 11,
      );

  TextStyle _inputTextStyle(FlutterFlowTheme t) => t.bodyMedium.override(
        fontFamily: _bodyFont,
      );

  TextStyle _hintStyle(FlutterFlowTheme t) => t.bodyMedium.override(
        fontFamily: _bodyFont,
        color: _inkMute,
      );

  TextStyle _buttonTextStyle(FlutterFlowTheme t, {required Color color}) =>
      t.labelLarge.override(
        fontFamily: _bodyFont,
        color: color,
        fontWeight: FontWeight.w700,
      );

  TextStyle _snackTextStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: _bodyFont,
        color: _ink,
      );

  TextStyle _otpDigitStyle(FlutterFlowTheme t) => t.bodyMedium.override(
        fontFamily: _bodyFont,
        fontWeight: FontWeight.w700,
        fontSize: 18,
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

  InputDecoration _inputDeco(
    FlutterFlowTheme theme,
    String hint, {
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: _hintStyle(theme),
      filled: true,
      fillColor: _paper,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _hairline, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _ink, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _coral, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _coral, width: 1.6),
      ),
      suffixIcon: suffix,
    );
  }

  BoxDecoration _liftedCardDecoration(FlutterFlowTheme t) => BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _hairline, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

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

  Widget _circleIconButton(
    FlutterFlowTheme t, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _surface,
          shape: BoxShape.circle,
          border: Border.all(color: _hairline, width: 1),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: _inkMute),
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
  // UI pieces (Subby ListingResults style)
  // ---------------------------
  Widget _slidingToggle(FlutterFlowTheme theme) {
    final isPhone = _method == LoginMethod.phone;

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: _paper,
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

  Widget _pressButton(
    FlutterFlowTheme theme, {
    required String label,
    required VoidCallback? onPressed,
    bool loading = false,
    IconData? icon,
    bool outline = false,
  }) {
    final disabled = onPressed == null || loading;

    final bg = outline ? _paper : _spark;
    final fg = outline ? _ink : _sparkInk;
    final border = outline ? _hairline : _spark;

    final spinnerColor = outline ? _ink : _sparkInk;

    return GestureDetector(
      onTap: disabled ? null : onPressed,
      child: AnimatedOpacity(
        opacity: disabled ? 0.7 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border, width: 1),
          ),
          alignment: Alignment.center,
          child: loading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: fg),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: _buttonTextStyle(theme, color: fg),
                    ),
                  ],
                ),
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
          style: _otpDigitStyle(theme),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: _paper,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _hairline, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _ink, width: 1.6),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _liftedCardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Phone number', style: _labelStyle(theme)),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 78,
                child: TextField(
                  controller: _countryCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDeco(theme, '+27'),
                  style: _inputTextStyle(theme),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDeco(theme, '081 234 5678'),
                  style: _inputTextStyle(theme),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _pressButton(
            theme,
            label: _codeSent ? 'Resend code' : 'Send code',
            icon: Icons.sms_outlined,
            loading: _sendingCode,
            onPressed: _sendingCode ? null : _sendOtp,
          ),
          if (_codeSent) ...[
            const SizedBox(height: 14),
            Text('OTP code', style: _labelStyle(theme)),
            const SizedBox(height: 8),
            _otpBoxes(theme),
            const SizedBox(height: 14),
            _pressButton(
              theme,
              label: 'Verify & continue',
              icon: Icons.lock_open_outlined,
              loading: _verifyingCode,
              onPressed: _verifyingCode ? null : _verifyOtp,
            ),
          ],
        ],
      ),
    );
  }

  Widget _emailForm(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _liftedCardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Email', style: _labelStyle(theme)),
          const SizedBox(height: 8),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDeco(theme, 'you@example.com'),
            style: _inputTextStyle(theme),
          ),
          const SizedBox(height: 14),
          Text('Password', style: _labelStyle(theme)),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordCtrl,
            obscureText: _obscurePw,
            decoration: _inputDeco(
              theme,
              'Enter password',
              suffix: IconButton(
                onPressed: () => setState(() => _obscurePw = !_obscurePw),
                icon: Icon(
                  _obscurePw ? Icons.visibility_off : Icons.visibility,
                  color: _inkMute,
                  size: 20,
                ),
              ),
            ),
            style: _inputTextStyle(theme),
          ),
          const SizedBox(height: 14),
          _pressButton(
            theme,
            label: 'Log in',
            icon: Icons.login,
            loading: _emailLoading,
            onPressed: _emailLoading ? null : _loginWithEmail,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _forgotPassword,
              child: Text(
                'Forgot password?',
                style: theme.labelMedium.override(
                  fontFamily: _bodyFont,
                  color: _ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    final double width = widget.width ?? MediaQuery.sizeOf(context).width;
    final double height = widget.height ?? MediaQuery.sizeOf(context).height;

    // Match ListingResults SafeArea usage (no manual insets)
    return SizedBox(
      width: width,
      height: height,
      child: SafeArea(
        child: Container(
          color: _paper,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- TOP BAR (match ListingResults pattern) ----------
              Padding(
                padding: const EdgeInsets.fromLTRB(_hPad, _vPad, _hPad, 8),
                child: Row(
                  children: [
                    _circleIconButton(
                      theme,
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => context.safePop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Log in', style: _titleStyle(theme)),
                          const SizedBox(height: 2),
                          Text('Subby account access',
                              style: _subtitleStyle(theme)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Toggle
                      _slidingToggle(theme),
                      const SizedBox(height: 16),

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
                      const SizedBox(height: 16),

                      // Create account (outline pill)
                      _pressButton(
                        theme,
                        label: 'Create account',
                        icon: Icons.person_add_alt_1_outlined,
                        outline: true,
                        onPressed: () => context.pushNamed(
                          widget.createAccountRouteName ??
                              _defaultCreateAccountRoute,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
