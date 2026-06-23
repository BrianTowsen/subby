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
    this.notificationsRouteName,
  }) : super(key: key);

  final double? width;
  final double? height;

  /// FlutterFlow route name to a page/sheet where YOU run:
  /// Select Media -> Upload -> Update users.photo_url
  final String? editPhotoRouteName;

  /// Optional FF route to a notifications / alerts settings page.
  /// If unset, the Alerts tile shows a "coming soon" toast.
  final String? notificationsRouteName;

  @override
  State<ProfilePageView> createState() => _ProfilePageViewState();
}

class _ProfilePageViewState extends State<ProfilePageView> {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  static const Color _ink = Color(0xFF017374);
  static const Color _inkMute = Color(0xFF5A6675);
  static const Color _faint = Color(0xFF93A0B0);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFEEF1F4);
  static const Color _hairline = Color(0xFFEEF1F4);
  static const Color _hairlineOnSurface = Color(0xFFD7DCE3);
  // Brand accent — TEAL.
  static const Color _teal = Color(0xFF017374);
  static const Color _spark = Color(
      0xFFFEB518); // sunshine — avatar ring + initials over the deep-teal circle
  static const Color _sparkInk = Color(0xFFFFFFFF);
  // Status
  static const Color _live = Color(0xFFE5771E);
  static const Color _coral = Color(0xFFE5771E);
  // Type
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const String _monoFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  // ✅ Use your actual FF route names
  static const String _loginRouteName = 'loginPage';
  static const String _createAccountRouteName = 'createAccountPage';
  static const String _editProfileRouteName = 'editProfilePage';

  static const double _hPad = 24;
  static const double _vPad = 14;
  static const double _radius = 12;

  // =========================================================
  // ✅ TYPOGRAPHY
  // =========================================================
  TextStyle _heroNameStyle(FlutterFlowTheme t) => t.titleLarge.override(
        fontFamily: _displayFont,
        fontWeight: FontWeight.w900,
        fontSize: 21,
        color: _ink,
      );

  TextStyle _uLabelStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: _bodyFont,
        color: _inkMute,
        letterSpacing: 0.6,
        fontWeight: FontWeight.w800,
        fontSize: 11,
      );

  TextStyle _valueStyle(FlutterFlowTheme t) => t.bodyMedium.override(
        fontFamily: _bodyFont,
        fontWeight: FontWeight.w700,
        fontSize: 15,
        color: _ink,
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

  // Primary pill (ink, white content)
  Widget _pillPrimaryButton(
    FlutterFlowTheme t, {
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _ink,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: _paper),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: t.labelLarge.override(
                fontFamily: _bodyFont,
                color: _paper,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Outline pill
  Widget _pillOutlineButton(
    FlutterFlowTheme t, {
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    Color? borderColor,
    Color? textColor,
    Color? iconColor,
  }) {
    final bc = borderColor ?? _hairlineOnSurface;
    final tc = textColor ?? _ink;
    final ic = iconColor ?? _inkMute;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: _paper,
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
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Subby-style snackbar
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
            borderRadius: BorderRadius.circular(12),
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
                child: const Icon(Icons.info_outline_rounded,
                    size: 16, color: _ink),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message, style: _snackTextStyle(theme))),
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

  void _goNotifications() {
    final route = (widget.notificationsRouteName ?? '').trim();
    if (route.isEmpty) {
      _showToast('Notification settings are coming soon.');
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
            backgroundColor: _paper,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: _hairline, width: 1),
            ),
            title: Text(
              'Delete profile?',
              style: theme.titleMedium.override(
                  fontFamily: _displayFont, fontWeight: FontWeight.w900),
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
                    fontWeight: FontWeight.w900,
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

  // Big teal-ringed avatar.
  Widget _avatar(FlutterFlowTheme theme, String photoUrl, String displayName) {
    final initials = Center(
      child: Text(
        _initialsFromName(displayName),
        style: theme.titleMedium.override(
          fontFamily: _bodyFont,
          fontWeight: FontWeight.w900,
          fontSize: 26,
          color: _spark,
        ),
      ),
    );

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _ink,
        border: Border.all(color: _spark, width: 2.5),
      ),
      child: ClipOval(
        child: photoUrl.isNotEmpty
            ? Image.network(
                photoUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, _, __) => initials,
              )
            : initials,
      ),
    );
  }

  // Read-only underline info row.
  Widget _uInfoRow(
    FlutterFlowTheme theme, {
    required IconData icon,
    required String label,
    required String value,
    bool showDivider = true,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: showDivider
              ? const BorderSide(color: _hairline, width: 1)
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: _teal),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: _uLabelStyle(theme)),
                const SizedBox(height: 4),
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

  // Tappable underline action row (chevron).
  Widget _uActionRow(
    FlutterFlowTheme theme, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return InkWell(
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: showDivider
                ? const BorderSide(color: _hairline, width: 1)
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: _teal),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: theme.bodyMedium.override(
                  fontFamily: _bodyFont,
                  color: _ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 22, color: _hairlineOnSurface),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    final double width = widget.width ?? MediaQuery.sizeOf(context).width;
    final double height = widget.height ?? MediaQuery.sizeOf(context).height;

    final userRef = currentUserReference;

    // ✅ Logged-out state
    if (userRef == null) {
      return SizedBox(
        width: width,
        height: height,
        child: SafeArea(
          child: Container(
            color: _paper,
            padding: const EdgeInsets.fromLTRB(_hPad, _vPad, _hPad, _vPad),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: _hairlineOnSurface),
                    ),
                    child: const Icon(Icons.lock_outline,
                        color: _inkMute, size: 24),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You are logged out',
                    style: theme.titleMedium.override(
                      fontFamily: _displayFont,
                      fontWeight: FontWeight.w900,
                      color: _ink,
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
                  const SizedBox(height: 22),
                  _pillPrimaryButton(
                    theme,
                    label: 'Log in',
                    onPressed: () => context.pushNamed(_loginRouteName),
                  ),
                  const SizedBox(height: 10),
                  _pillOutlineButton(
                    theme,
                    label: 'Create account',
                    onPressed: () => context.pushNamed(_createAccountRouteName),
                  ),
                ],
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
                return const Center(
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

              // ---------------------------------------------------------
              // ✅ OPTION C — MINIMAL UNDERLINE
              // ---------------------------------------------------------
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------- HEADER ----------
                  Padding(
                    padding: const EdgeInsets.fromLTRB(_hPad, _vPad, _hPad, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Profile',
                          style: theme.titleLarge.override(
                            fontFamily: _displayFont,
                            color: _ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 30,
                            lineHeight: 1.05,
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _openMore,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF1F4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.menu_rounded,
                                  size: 22, color: _ink),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ---------- CONTENT ----------
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(_hPad, 20, _hPad, 98),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar hero (centered)
                          Center(
                            child: Column(
                              children: [
                                _avatar(theme, photoUrl, displayName),
                                const SizedBox(height: 14),
                                Text(
                                  displayName.isEmpty
                                      ? 'Your name'
                                      : displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _heroNameStyle(theme),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  email.isEmpty ? '—' : email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.bodySmall.override(
                                    fontFamily: _bodyFont,
                                    color: _faint,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Details (read-only underline rows)
                          Text('ACCOUNT', style: _uLabelStyle(theme)),
                          const SizedBox(height: 2),
                          _uInfoRow(
                            theme,
                            icon: Icons.person_outline,
                            label: 'Display name',
                            value: displayName,
                          ),
                          _uInfoRow(
                            theme,
                            icon: Icons.phone_outlined,
                            label: 'Phone number',
                            value: phone,
                          ),
                          _uInfoRow(
                            theme,
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: email,
                            showDivider: false,
                          ),

                          const SizedBox(height: 24),

                          // Edit profile (primary)
                          _pillPrimaryButton(
                            theme,
                            label: 'Edit profile',
                            icon: Icons.edit_outlined,
                            onPressed: () =>
                                context.pushNamed(_editProfileRouteName),
                          ),

                          const SizedBox(height: 24),

                          // Manage rows
                          Text('MANAGE', style: _uLabelStyle(theme)),
                          const SizedBox(height: 2),
                          _uActionRow(
                            theme,
                            icon: Icons.camera_alt_outlined,
                            label: 'Change photo',
                            onTap: _goEditPhoto,
                          ),
                          _uActionRow(
                            theme,
                            icon: Icons.notifications_none_rounded,
                            label: 'Notifications',
                            onTap: _goNotifications,
                            showDivider: false,
                          ),

                          const SizedBox(height: 24),

                          // Account actions (Logout / Delete)
                          Row(
                            children: [
                              Expanded(
                                child: _pillOutlineButton(
                                  theme,
                                  label: 'Logout',
                                  icon: Icons.logout,
                                  onPressed: _logout,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _pillOutlineButton(
                                  theme,
                                  label: 'Delete',
                                  icon: Icons.delete_outline,
                                  borderColor: _coral.withOpacity(0.6),
                                  textColor: _coral,
                                  iconColor: _coral,
                                  onPressed: _confirmAndDeleteProfile,
                                ),
                              ),
                            ],
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

  void _openMore() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _MoreSheet(),
    );
  }
}

// ─── More menu — bottom sheet (matches Directory) ──────────────────────
class _MoreSheet extends StatelessWidget {
  const _MoreSheet();

  static const Color _ink = Color(0xFF017374);
  static const Color _faint = Color(0xFF93A0B0);
  static const Color _label = Color(0xFF5A6675);
  static const Color _rule = Color(0xFFE2E7EE);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.86,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 4),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _ink,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.grid_view_rounded,
                        color: Colors.white),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF1F4),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFEEF1F2)),
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: _label),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Text(
                'More',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 30,
                  height: 1.05,
                  letterSpacing: -0.5,
                  color: _ink,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Text(
                'Jump anywhere, or read the legal bits.',
                style: TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13, color: _faint),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                children: [
                  _sectionLabel('QUICK ACCESS'),
                  _row(context, Icons.home_rounded, 'Home',
                      'Browse categories & locations'),
                  _row(context, Icons.search_rounded, 'Explore',
                      'Search and filter listings'),
                  _row(context, Icons.bookmark_rounded, 'Saved',
                      'Your bookmarked listings'),
                  _row(context, Icons.person_rounded, 'Profile',
                      'Your account details'),
                  const SizedBox(height: 26),
                  _sectionLabel('LEGAL'),
                  _row(context, Icons.description_rounded, 'Terms of Service',
                      null),
                  _row(context, Icons.privacy_tip_rounded, 'Privacy Policy',
                      null),
                  const SizedBox(height: 26),
                  _sectionLabel('SUPPORT'),
                  _row(context, Icons.help_rounded, 'Help & Support',
                      'FAQs and contact options'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 0.6,
            color: _label,
          ),
        ),
      );

  Widget _row(
      BuildContext context, IconData icon, String title, String? subtitle) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _rule))),
        child: Row(
          children: [
            Icon(icon, size: 21, color: _ink),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: -0.1,
                      color: _ink,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: _faint),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 22, color: _faint),
          ],
        ),
      ),
    );
  }
}
