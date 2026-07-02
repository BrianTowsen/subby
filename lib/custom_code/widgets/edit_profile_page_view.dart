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

// ✅ Auth helpers (currentUserReference, currentUserEmail, etc.)
import '/auth/firebase_auth/auth_util.dart';

// ✅ Needed to rebuild UI on logout (auth state changes)
import 'package:firebase_auth/firebase_auth.dart';

class EditProfilePageView extends StatefulWidget {
  const EditProfilePageView({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<EditProfilePageView> createState() => _EditProfilePageViewState();
}

class _EditProfilePageViewState extends State<EditProfilePageView> {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  static const Color _ink = Color(0xFF29343A);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _hairline = Color(0xFFECF0F2);
  static const Color _hairlineOnSurface = Color(0xFFCBD8DD);
  // Brand accent — TEAL (field icons / focus). Primary action is ink.
  static const Color _teal = Color(0xFF29343A);
  // Status
  static const Color _live = Color(0xFF5D737E);
  static const Color _coral = Color(0xFF5D737E);
  // Type
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const String _monoFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();

  bool _prefilled = false;
  bool _saving = false;

  static const double _hPad = 24;
  static const double _vPad = 14;
  static const double _radius = 12;

  // =========================================================
  // ✅ TYPOGRAPHY
  // =========================================================
  TextStyle _subtitleStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: _bodyFont,
        color: _inkMute,
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

  TextStyle _snackTextStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: _bodyFont,
        color: _ink,
      );
  // =========================================================

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

  void _showToast(String message, {bool success = true}) {
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

  // =========================================================
  // ✅ OPTION C — MINIMAL UNDERLINE FIELD
  // =========================================================
  Widget _uText({
    required FlutterFlowTheme theme,
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    TextInputAction textInputAction = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
    String? Function(String?)? validator,
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
          Row(
            children: [
              Icon(icon, size: 19, color: _teal),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  onFieldSubmitted: onSubmitted,
                  validator: validator,
                  cursorColor: _teal,
                  style: _fieldTextStyle(theme),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: hint,
                    hintStyle: theme.bodyMedium.override(
                      fontFamily: _bodyFont,
                      color: _inkMute.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      letterSpacing: 0.0,
                    ),
                    errorStyle: theme.bodySmall.override(
                      fontFamily: _bodyFont,
                      color: _coral,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _primarySave(FlutterFlowTheme theme) {
    return GestureDetector(
      onTap: _saving ? null : _saveProfile,
      child: Opacity(
        opacity: _saving ? 0.7 : 1,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: _ink,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_paper),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_rounded, size: 18, color: _paper),
                    const SizedBox(width: 8),
                    Text(
                      'Save Profile',
                      style: theme.labelLarge.override(
                        fontFamily: _bodyFont,
                        color: _paper,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  String _initials(String? name) {
    final n = (name ?? '').trim();
    if (n.isEmpty) return '?';
    final parts = n.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    final a = parts.first.substring(0, 1).toUpperCase();
    final b = parts.last.substring(0, 1).toUpperCase();
    return '$a$b';
  }

  Future<void> _saveProfile() async {
    if (_saving) return;

    final formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk) return;

    final userRef = currentUserReference;
    if (userRef == null) {
      _showToast('Not signed in. Please log in again.', success: false);
      return;
    }

    setState(() => _saving = true);

    try {
      final displayName = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      await userRef.update(<String, dynamic>{
        'display_name': displayName,
        'phone_number': phone,
      });

      if (!mounted) return;

      _showToast('Profile updated.', success: true);

      context.pop();
    } catch (e) {
      if (!mounted) return;
      _showToast('Failed to save: $e', success: false);
      if (mounted) setState(() => _saving = false);
    }
  }

  // =========================
  // Minimal header + message scaffold (logged-out / error states)
  // =========================
  Widget _messageState(
    FlutterFlowTheme theme,
    double width,
    double height, {
    required IconData icon,
    required String title,
    required String body,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: SafeArea(
        child: Container(
          color: _paper,
          padding: const EdgeInsets.fromLTRB(_hPad, _vPad, _hPad, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [_circleBack(theme), const Spacer()]),
              const SizedBox(height: 20),
              Text(
                'Edit profile',
                style: theme.titleLarge.override(
                  fontFamily: _displayFont,
                  color: _ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 30,
                  lineHeight: 1.05,
                ),
              ),
              const SizedBox(height: 8),
              Text('Profile & account',
                  style: _subtitleStyle(theme).copyWith(fontSize: 13)),
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    Icon(icon, color: _inkMute, size: 34),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: theme.titleMedium.override(
                        fontFamily: _displayFont,
                        fontWeight: FontWeight.w900,
                        color: _ink,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: theme.bodySmall.override(
                        fontFamily: _bodyFont,
                        color: _inkMute,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    final double width = widget.width ?? MediaQuery.sizeOf(context).width;
    final double height = widget.height ?? MediaQuery.sizeOf(context).height;

    // ✅ KEY FIX: rebuild when auth changes (prevents stale userRef after logout)
    return SizedBox(
      width: width,
      height: height,
      child: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnap) {
          final userRef = currentUserReference;

          if (authSnap.connectionState == ConnectionState.waiting) {
            return _messageState(theme, width, height,
                icon: Icons.lock_outline,
                title: 'You are not signed in.',
                body: 'Please log in to edit your profile.');
          }

          if (authSnap.data == null || userRef == null) {
            _prefilled = false;
            _saving = false;
            return _messageState(theme, width, height,
                icon: Icons.lock_outline,
                title: 'You are not signed in.',
                body: 'Please log in to edit your profile.');
          }

          return StreamBuilder<UsersRecord>(
            stream: UsersRecord.getDocument(userRef),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                final stillSignedIn = FirebaseAuth.instance.currentUser != null;
                if (!stillSignedIn) {
                  _prefilled = false;
                  _saving = false;
                  return _messageState(theme, width, height,
                      icon: Icons.lock_outline,
                      title: 'You are not signed in.',
                      body: 'Please log in to edit your profile.');
                }
                return _messageState(theme, width, height,
                    icon: Icons.cloud_off_rounded,
                    title: 'Unable to load profile right now.',
                    body: 'Please try again in a moment.');
              }

              final userDoc = snapshot.data;

              // Prefill once
              if (!_prefilled && userDoc != null) {
                _nameController.text = userDoc.displayName;
                _phoneController.text = userDoc.phoneNumber;
                _prefilled = true;
              }

              final displayName = userDoc?.displayName ?? '';
              final email = userDoc?.email ?? (currentUserEmail ?? '');
              final photoUrl = userDoc?.photoUrl ?? '';

              // ---------------------------------------------------------
              // ✅ OPTION C — MINIMAL UNDERLINE
              // ---------------------------------------------------------
              return GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SafeArea(
                  child: Container(
                    color: _paper,
                    child: SingleChildScrollView(
                      padding:
                          const EdgeInsets.fromLTRB(_hPad, _vPad, _hPad, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ===== TOP ROW: back =====
                          Row(children: [_circleBack(theme), const Spacer()]),

                          const SizedBox(height: 20),

                          // ===== TITLE =====
                          Text(
                            'Edit profile',
                            style: theme.titleLarge.override(
                              fontFamily: _displayFont,
                              color: _ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 30,
                              lineHeight: 1.05,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Profile & account',
                              style:
                                  _subtitleStyle(theme).copyWith(fontSize: 13)),

                          const SizedBox(height: 24),

                          // ===== AVATAR + IDENTITY =====
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: _ink,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Color(0xFF5D737E), width: 2.2),
                                ),
                                child: ClipOval(
                                  child: (photoUrl.isNotEmpty)
                                      ? Image.network(
                                          photoUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _avatarInitials(
                                                  theme, displayName),
                                        )
                                      : _avatarInitials(theme, displayName),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName.isEmpty
                                          ? 'Your name'
                                          : displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.titleMedium.override(
                                        fontFamily: _displayFont,
                                        color: _ink,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.bodySmall.override(
                                        fontFamily: _bodyFont,
                                        color: _inkMute,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // ===== FORM =====
                          Text('DETAILS', style: _uLabelStyle(theme)),
                          const SizedBox(height: 2),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _uText(
                                  theme: theme,
                                  label: 'Display name',
                                  controller: _nameController,
                                  focusNode: _nameFocus,
                                  icon: Icons.person_outline_rounded,
                                  hint: 'Your name',
                                  onSubmitted: (_) => FocusScope.of(context)
                                      .requestFocus(_phoneFocus),
                                  validator: (v) {
                                    final s = (v ?? '').trim();
                                    if (s.isEmpty) {
                                      return 'Please enter your name.';
                                    }
                                    if (s.length < 2) {
                                      return 'Name is too short.';
                                    }
                                    return null;
                                  },
                                ),
                                _uText(
                                  theme: theme,
                                  label: 'Phone number',
                                  controller: _phoneController,
                                  focusNode: _phoneFocus,
                                  icon: Icons.phone_outlined,
                                  hint: 'e.g. 0813151789',
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _saveProfile(),
                                  validator: (v) {
                                    final s = (v ?? '').trim();
                                    if (s.isEmpty) {
                                      return 'Please enter your phone number.';
                                    }
                                    if (s.length < 8) {
                                      return 'Phone number looks too short.';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          _primarySave(theme),

                          const SizedBox(height: 16),
                          Center(
                            child: GestureDetector(
                              onTap: _saving ? null : () => context.safePop(),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Text(
                                  'Cancel',
                                  style: theme.bodyMedium.override(
                                    fontFamily: _bodyFont,
                                    color: _inkMute,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
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
              );
            },
          );
        },
      ),
    );
  }

  Widget _avatarInitials(FlutterFlowTheme theme, String displayName) {
    return Center(
      child: Text(
        _initials(displayName),
        style: theme.bodyMedium.override(
          fontFamily: _bodyFont,
          color: Color(0xFF5D737E),
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
      ),
    );
  }
}
