// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/custom_code/widgets/index.dart'; // (kept if FF expects it)

// ✅ provides currentUserReference, currentUserEmail, etc.
import '/auth/firebase_auth/auth_util.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePageView extends StatefulWidget {
  const ProfilePageView({
    Key? key,
    this.width,
    this.height,
    this.editPhotoRouteName,
  }) : super(key: key);

  final double? width;
  final double? height;

  /// FlutterFlow route name to a page/sheet where YOU run:
  /// Select Media -> Upload -> Update users.photo_url
  final String? editPhotoRouteName;

  @override
  State<ProfilePageView> createState() => _ProfilePageViewState();
}

class _ProfilePageViewState extends State<ProfilePageView> {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  // less-is-more system · ported from Clutch Putt · lime → yellow.
  // Inline = authoritative for this file. Grep `SUBBY PALETTE (LOCK)` to sync.
  //
  // Neutrals
  static const Color _ink = Color(0xFF14243F);
  static const Color _inkMute = Color(0xFF6B7280);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFE3E4E8);
  static const Color _hairline = Color(0xFFE3E4E8);
  static const Color _hairlineOnSurface = Color(0xFFD0D2D8);
  // Brand accent — YELLOW. Always ink foreground, never white.
  static const Color _spark = Color(0xFFFFE74C); // primary CTA / ranked accent
  static const Color _sparkInk = Color(0xFF14243F);
  // Status
  static const Color _live =
      Color(0xFFFFB000); // gold — live / open-now / warning
  static const Color _coral = Color(0xFFC8102E);
  // Type
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const String _monoFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  // ✅ Use your actual FF route names
  static const String _loginRouteName = 'loginPage';
  static const String _createAccountRouteName = 'createAccountPage';
  static const String _editProfileRouteName = 'editProfilePage';

  // ---------------- PADDING / RADIUS (match ListingResultsPageView) ----------------
  static const double _hPad = 24;
  static const double _vPad = 24;
  static const double _radius = 16;
  // -------------------------------------------------------------------------------

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

  TextStyle _valueStyle(FlutterFlowTheme t) => t.bodyMedium.override(
        fontFamily: _bodyFont,
        fontWeight: FontWeight.w800,
      );

  TextStyle _mutedBodyStyle(FlutterFlowTheme t) => t.bodyMedium.override(
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

  // ListingResults card recipe (primaryBackground + subtle shadow)
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

  // ListingResults pill button recipe (radius 999)
  Widget _pillPrimaryButton(
    FlutterFlowTheme t, {
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _spark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Row(
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
  }) {
    final bc = borderColor ?? _hairline;
    final tc = textColor ?? _ink;
    final ic = iconColor ?? _inkMute;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: bc, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Row(
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

  // Subby-style snackbar used in ListingResults
  void _showToast(String message) {
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
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: _hairline, width: 1),
          ),
          duration: const Duration(milliseconds: 1700),
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
                  Icons.info_outline_rounded,
                  size: 16,
                  color: _ink,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: _snackTextStyle(theme),
                ),
              ),
            ],
          ),
        ),
      );
  }
  // =========================================================

  String _initialsFromName(String? name) {
    final n = (name ?? '').trim();
    if (n.isEmpty) return 'U';
    final parts = n.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  String _bestEmail(String emailFromDoc) {
    final fromDoc = emailFromDoc.trim();
    if (fromDoc.isNotEmpty) return fromDoc;

    final fromAuthUtil = (currentUserEmail ?? '').toString().trim();
    return fromAuthUtil;
  }

  void _goEditPhoto() {
    final route = (widget.editPhotoRouteName ?? '').trim();
    if (route.isEmpty) {
      _showToast(
          'Set editPhotoRouteName on the widget (to open your photo picker page).');
      return;
    }
    context.pushNamed(route);
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      context.goNamed(_loginRouteName);
    } catch (e) {
      _showToast('Logout failed: $e');
    }
  }

  Future<void> _confirmAndDeleteProfile() async {
    final theme = FlutterFlowTheme.of(context);

    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: _surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Delete profile?',
              style: theme.titleMedium.override(
                  fontFamily: _displayFont, fontWeight: FontWeight.w800),
            ),
            content: Text(
              'This will permanently delete your account and profile data. '
              'This cannot be undone.',
              style: _mutedBodyStyle(theme),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Cancel',
                  style: theme.bodyMedium.override(
                      fontFamily: _bodyFont, fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'Delete',
                  style: theme.bodyMedium.override(
                    fontFamily: _bodyFont,
                    color: _coral,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;
    await _deleteProfile();
  }

  Future<void> _deleteProfile() async {
    final userRef = currentUserReference;
    final user = FirebaseAuth.instance.currentUser;

    if (userRef == null || user == null) {
      _showToast('Not signed in.');
      return;
    }

    try {
      // 1) Delete Firestore profile doc first
      await userRef.delete();

      // 2) Delete auth user (may require recent login)
      await user.delete();

      if (!mounted) return;
      context.goNamed(_loginRouteName);
    } on FirebaseAuthException catch (e) {
      final msg = (e.code == 'requires-recent-login')
          ? 'For security, please log in again, then try deleting your profile.'
          : 'Delete failed: ${e.message ?? e.code}';
      _showToast(msg);
    } catch (e) {
      _showToast('Delete failed: $e');
    }
  }

  Widget _infoRow(
    FlutterFlowTheme theme, {
    required IconData icon,
    required String label,
    required String value,
    bool showDivider = true,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: showDivider
              ? BorderSide(color: _hairline, width: 1)
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _inkMute),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _labelStyle(theme)),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '—' : value,
                  style: _valueStyle(theme),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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

    final userRef = currentUserReference;

    // ✅ Logged-out state (match ListingResults empty-state card + pill buttons)
    if (userRef == null) {
      return SizedBox(
        width: width,
        height: height,
        child: SafeArea(
          child: Container(
            color: _paper,
            padding: const EdgeInsets.fromLTRB(_hPad, _vPad, _hPad, _vPad),
            child: Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _hairline),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, color: _inkMute, size: 34),
                    const SizedBox(height: 10),
                    Text(
                      'You are logged out.',
                      style: theme.titleMedium.override(
                        fontFamily: _displayFont,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Log in or create an account to continue.',
                      style: theme.bodySmall.override(
                        fontFamily: _bodyFont,
                        color: _inkMute,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    _pillPrimaryButton(
                      theme,
                      label: 'Log in',
                      onPressed: () => context.pushNamed(_loginRouteName),
                    ),
                    const SizedBox(height: 10),
                    _pillOutlineButton(
                      theme,
                      label: 'Create account',
                      onPressed: () =>
                          context.pushNamed(_createAccountRouteName),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: SafeArea(
        child: Container(
          color: _paper,
          child: StreamBuilder<DocumentSnapshot>(
            stream: userRef.snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(_ink),
                    ),
                  ),
                );
              }

              final data = (snap.data!.data() as Map<String, dynamic>?) ?? {};

              final displayName =
                  (data['display_name'] ?? '').toString().trim();
              final phone = (data['phone_number'] ?? '').toString().trim();
              final photoUrl = (data['photo_url'] ?? '').toString().trim();
              final emailDoc = (data['email'] ?? '').toString();

              final email = _bestEmail(emailDoc);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------- TOP BAR (match ListingResultsPageView) ----------
                  Padding(
                    padding: const EdgeInsets.fromLTRB(_hPad, _vPad, _hPad, 8),
                    child: Row(
                      children: [
                        _circleIconShell(
                          theme,
                          size: 32,
                          icon: Icons.arrow_back_ios_new_rounded,
                          iconColor: _inkMute,
                          onTap: () => context.pop(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Profile', style: _titleStyle(theme)),
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

                  // ---------- CONTENT ----------
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 24),
                      child: Column(
                        children: [
                          // Profile card (match ListingResults card recipe)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: _liftedCardDecoration(theme),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // left "avatar tile" shell like listing icon tile
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _surface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: photoUrl.isNotEmpty
                                        ? Image.network(
                                            photoUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, _, __) =>
                                                Center(
                                              child: Text(
                                                _initialsFromName(displayName),
                                                style:
                                                    theme.bodyMedium.override(
                                                  fontFamily: _bodyFont,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              _initialsFromName(displayName),
                                              style: theme.bodyMedium.override(
                                                fontFamily: _bodyFont,
                                                fontWeight: FontWeight.w900,
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
                                        email.isEmpty ? '—' : email,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.bodySmall.override(
                                          fontFamily: _bodyFont,
                                          color: _inkMute,
                                        ),
                                      ),
                                      const SizedBox(height: 10),

                                      // Photo edit pill icon (like bookmark button shell)
                                      Row(
                                        children: [
                                          InkWell(
                                            onTap: _goEditPhoto,
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            child: Container(
                                              height: 38,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12),
                                              decoration: BoxDecoration(
                                                color: _paper,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                                border: Border.all(
                                                    color: _hairline, width: 1),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                      Icons.camera_alt_outlined,
                                                      size: 18,
                                                      color: _ink),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Edit photo',
                                                    style: theme.labelMedium
                                                        .override(
                                                      fontFamily: theme
                                                          .labelMediumFamily,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Info card (same lifted card + internal dividers like profile rows)
                          Container(
                            padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                            decoration: _liftedCardDecoration(theme),
                            child: Column(
                              children: [
                                _infoRow(
                                  theme,
                                  icon: Icons.person_outline,
                                  label: 'Display name',
                                  value: displayName,
                                ),
                                _infoRow(
                                  theme,
                                  icon: Icons.phone_outlined,
                                  label: 'Phone number',
                                  value: phone,
                                ),
                                _infoRow(
                                  theme,
                                  icon: Icons.email_outlined,
                                  label: 'Email',
                                  value: email,
                                  showDivider: false,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Edit profile (pill)
                          _pillPrimaryButton(
                            theme,
                            label: 'Edit Profile',
                            icon: Icons.edit_outlined,
                            onPressed: () =>
                                context.pushNamed(_editProfileRouteName),
                          ),

                          const SizedBox(height: 18),

                          // Account actions (lifted card + pill outline buttons)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: _liftedCardDecoration(theme),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('Account',
                                    style: _sectionTitleStyle(theme)),
                                const SizedBox(height: 12),
                                _pillOutlineButton(
                                  theme,
                                  label: 'Logout',
                                  icon: Icons.logout,
                                  onPressed: _logout,
                                ),
                                const SizedBox(height: 10),
                                _pillOutlineButton(
                                  theme,
                                  label: 'Delete Profile',
                                  icon: Icons.delete_outline,
                                  borderColor: _coral.withOpacity(0.6),
                                  textColor: _coral,
                                  iconColor: _coral,
                                  onPressed: _confirmAndDeleteProfile,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
