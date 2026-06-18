// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

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

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();

  bool _prefilled = false;
  bool _saving = false;

  // Match ListingResults / Profile updated style
  static const double _hPad = 24;
  static const double _vPad = 24;
  static const double _radius = 12;

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

  TextStyle _sectionTitleStyle(FlutterFlowTheme t) => t.titleMedium.override(
        fontFamily: _displayFont,
        fontWeight: FontWeight.w800,
      );

  TextStyle _labelStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: _bodyFont,
        color: _inkMute,
        fontWeight: FontWeight.w600,
        fontSize: 11,
      );

  TextStyle _fieldTextStyle(FlutterFlowTheme t) => t.bodyMedium.override(
        fontFamily: _bodyFont,
      );

  TextStyle _hintStyle(FlutterFlowTheme t) => t.bodyMedium.override(
        fontFamily: _bodyFont,
        color: _inkMute,
      );

  TextStyle _snackTextStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: _bodyFont,
        color: _ink,
      );
  // =========================================================

  // =========================================================
  // ✅ ListingResults-style helpers
  // =========================================================
  Widget _circleIconShell(
    FlutterFlowTheme t, {
    required double size,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    final child = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _surface,
        shape: BoxShape.circle,
        border: Border.all(color: _hairline, width: 1),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: size == 32 ? 16 : 18, color: iconColor),
    );

    if (onTap == null) return child;
    return GestureDetector(onTap: onTap, child: child);
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

  Widget _pillPrimaryButton(
    FlutterFlowTheme t, {
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    bool loading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _spark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(_sparkInk),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: _sparkInk),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: t.labelLarge.override(
                      fontFamily: _bodyFont,
                      color: _sparkInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _pillOutlineButton(
    FlutterFlowTheme t, {
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    Color? borderColor,
    Color? textColor,
    Color? iconColor,
    bool loading = false,
  }) {
    final bc = borderColor ?? _hairline;
    final tc = textColor ?? _ink;
    final ic = iconColor ?? _inkMute;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: bc, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_ink),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: ic),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: t.labelLarge.override(
                      fontFamily: _bodyFont,
                      color: tc,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
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

  InputDecoration _inputDeco(
    FlutterFlowTheme theme, {
    required String hint,
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
    );
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
  // LOGGED OUT STATE (extracted)
  // =========================
  Widget _buildLoggedOutState(
    FlutterFlowTheme theme,
    double width,
    double height,
  ) {
    return SizedBox(
      width: width,
      height: height,
      child: SafeArea(
        child: Container(
          color: _paper,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(_hPad, _vPad, _hPad, 8),
                child: Row(
                  children: [
                    _circleIconShell(
                      theme,
                      size: 32,
                      icon: Icons.arrow_back_ios_new_rounded,
                      iconColor: _inkMute,
                      onTap: () => context.safePop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Edit profile', style: _titleStyle(theme)),
                          const SizedBox(height: 2),
                          Text('Profile & account',
                              style: _subtitleStyle(theme)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 24),
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _hairline),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline, color: _inkMute, size: 34),
                          const SizedBox(height: 10),
                          Text(
                            'You are not signed in.',
                            style: theme.titleMedium.override(
                              fontFamily: _displayFont,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Please log in to edit your profile.',
                            style: theme.bodySmall.override(
                              fontFamily: _bodyFont,
                              color: _inkMute,
                            ),
                            textAlign: TextAlign.center,
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
    );
  }

  // =========================
  // SIGNED IN: graceful error card (prevents scary "failed" after logout timing)
  // =========================
  Widget _buildSignedInErrorState(
    FlutterFlowTheme theme,
    double width,
    double height,
  ) {
    return SizedBox(
      width: width,
      height: height,
      child: SafeArea(
        child: Container(
          color: _paper,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(_hPad, _vPad, _hPad, 8),
                child: Row(
                  children: [
                    _circleIconShell(
                      theme,
                      size: 32,
                      icon: Icons.arrow_back_ios_new_rounded,
                      iconColor: _inkMute,
                      onTap: () => context.safePop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Edit profile', style: _titleStyle(theme)),
                          const SizedBox(height: 2),
                          Text('Profile & account',
                              style: _subtitleStyle(theme)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 24),
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _hairline),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_off_rounded,
                              color: _inkMute, size: 34),
                          const SizedBox(height: 10),
                          Text(
                            'Unable to load profile right now.',
                            style: theme.titleMedium.override(
                              fontFamily: _displayFont,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Please try again in a moment.',
                            style: theme.bodySmall.override(
                              fontFamily: _bodyFont,
                              color: _inkMute,
                            ),
                            textAlign: TextAlign.center,
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

          // While auth is resolving, show logged-out UI shell (no scary errors)
          if (authSnap.connectionState == ConnectionState.waiting) {
            return _buildLoggedOutState(theme, width, height);
          }

          // Logged out
          if (authSnap.data == null || userRef == null) {
            // Reset local form flags so next login shows fresh state
            _prefilled = false;
            _saving = false;
            return _buildLoggedOutState(theme, width, height);
          }

          // Signed in — keep your existing UsersRecord stream
          return StreamBuilder<UsersRecord>(
            stream: UsersRecord.getDocument(userRef),
            builder: (context, snapshot) {
              // ✅ IMPORTANT: on logout timing, Firestore streams can throw permission errors.
              // If user is already logged out, do NOT show an error (this is the "logout failed" confusion).
              if (snapshot.hasError) {
                final stillSignedIn = FirebaseAuth.instance.currentUser != null;
                if (!stillSignedIn) {
                  _prefilled = false;
                  _saving = false;
                  return _buildLoggedOutState(theme, width, height);
                }
                return _buildSignedInErrorState(theme, width, height);
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

              return GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SafeArea(
                  child: Container(
                    color: _paper,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ---------- TOP BAR ----------
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(_hPad, _vPad, _hPad, 8),
                          child: Row(
                            children: [
                              _circleIconShell(
                                theme,
                                size: 32,
                                icon: Icons.arrow_back_ios_new_rounded,
                                iconColor: _inkMute,
                                onTap: () => context.safePop(),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Edit profile',
                                        style: _titleStyle(theme)),
                                    const SizedBox(height: 2),
                                    Text('Profile & account',
                                        style: _subtitleStyle(theme)),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: _saving ? null : _saveProfile,
                                child: _saving
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  _ink),
                                        ),
                                      )
                                    : Text(
                                        'Save',
                                        style: theme.labelMedium.override(
                                          fontFamily: _bodyFont,
                                          color: _ink,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ---------- CONTENT ----------
                        Expanded(
                          child: SingleChildScrollView(
                            padding:
                                const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: _liftedCardDecoration(theme),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: _surface,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: (photoUrl.isNotEmpty)
                                              ? Image.network(
                                                  photoUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      Center(
                                                    child: Text(
                                                      _initials(displayName),
                                                      style: theme.bodyMedium
                                                          .override(
                                                        fontFamily: theme
                                                            .bodyMediumFamily,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : Center(
                                                  child: Text(
                                                    _initials(displayName),
                                                    style: theme.bodyMedium
                                                        .override(
                                                      fontFamily: theme
                                                          .bodyMediumFamily,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              displayName.isEmpty
                                                  ? 'Your name'
                                                  : displayName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.bodyMedium.override(
                                                fontFamily: _bodyFont,
                                                fontWeight: FontWeight.w700,
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
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: _liftedCardDecoration(theme),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text('Details',
                                            style: _sectionTitleStyle(theme)),
                                        const SizedBox(height: 12),
                                        Text('Display name',
                                            style: _labelStyle(theme)),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _nameController,
                                          focusNode: _nameFocus,
                                          textInputAction: TextInputAction.next,
                                          onFieldSubmitted: (_) =>
                                              FocusScope.of(context)
                                                  .requestFocus(_phoneFocus),
                                          decoration: _inputDeco(theme,
                                              hint: 'Your name'),
                                          style: _fieldTextStyle(theme),
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
                                        const SizedBox(height: 14),
                                        Text('Phone number',
                                            style: _labelStyle(theme)),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _phoneController,
                                          focusNode: _phoneFocus,
                                          textInputAction: TextInputAction.done,
                                          keyboardType: TextInputType.phone,
                                          decoration: _inputDeco(theme,
                                              hint: 'e.g. 0813151789'),
                                          style: _fieldTextStyle(theme),
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
                                          onFieldSubmitted: (_) =>
                                              _saveProfile(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _pillPrimaryButton(
                                  theme,
                                  label: 'Save Profile',
                                  icon: Icons.check_rounded,
                                  loading: _saving,
                                  onPressed: _saveProfile,
                                ),
                                const SizedBox(height: 10),
                                _pillOutlineButton(
                                  theme,
                                  label: 'Cancel',
                                  icon: Icons.close_rounded,
                                  onPressed: () => context.safePop(),
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
            },
          );
        },
      ),
    );
  }
}
