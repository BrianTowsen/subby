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

// ✅ provides currentUserReference, currentUserEmail, etc.
import '/auth/firebase_auth/auth_util.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// =============================================================================
// ProfilePageView  →  now the ACCOUNT hub
//
// Same class / route / params as before (drop-in replacement) but restructured:
//   • PLAN     — current package + the perks that plan includes
//   • LISTING  — entry points to Edit Listing / Add Listing (previously
//                unreachable from the Directory). Empty state → "Add listing".
//   • SETTINGS — Personal details + Notifications.
//                (Help & Support moved to MorePageView.)
//   • Logout / Delete (real Firebase logic preserved)
//
// Host inside a page that places MainBottomNav(currentIndex: 2).
// =============================================================================

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

  /// FF route to a page/sheet where you Select Media → Upload → update photo_url.
  /// Tapping the avatar opens it. If unset, shows a toast.
  final String? editPhotoRouteName;

  /// Optional FF route to notifications settings. If unset → "coming soon" toast.
  final String? notificationsRouteName;

  @override
  State<ProfilePageView> createState() => _ProfilePageViewState();
}

class _ProfilePageViewState extends State<ProfilePageView> {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  static const Color _ink = Color(0xFF1E282E);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _hairline = Color(0xFFECF0F2);
  static const Color _hairlineOnSurface = Color(0xFFCBD8DD);
  // Brand accent — TEAL.
  static const Color _teal = Color(0xFF1E282E);
  // Sunshine — avatar ring + initials.
  static const Color _spark = Color(0xFF4E504F);
  // Status
  static const Color _live = Color(0xFF4E504F);
  static const Color _coral = Color(0xFF4E504F);
  static const Color _ok = Color(0xFF4E504F); // "live in Directory" dot
  // Type
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  // ✅ Route names — adjust to your FlutterFlow page names.
  static const String _loginRouteName = 'loginPage';
  static const String _createAccountRouteName = 'createAccountPage';
  static const String _editProfileRouteName = 'editProfilePage';
  static const String _editListingRouteName = 'editListingPage';
  static const String _addListingRouteName = 'addListingPage';
  static const String _directoryRouteName =
      'explorePage'; // "View in Directory"
  static const String _managePackageRouteName = ''; // optional → toast if empty

  static const double _hPad = 24;
  static const double _vPad = 14;

  // ── PROJECT MANAGEMENT packages ──
  static const List<String> _mgmtTiers = ['Basic', 'Professional'];
  static const Map<String, List<String>> _mgmtPerks = {
    'Basic': [
      'Manage a single project',
    ],
    'Professional': [
      'Manage multiple projects',
    ],
  };

  // ── DIRECTORY packages ── (inclusions TBD)
  static const List<String> _dirTiers = ['Basic Listing', 'Plus Listing'];
  static const Map<String, List<String>> _dirPerks = {
    'Basic Listing': [
      'Inclusions to be defined',
    ],
    'Plus Listing': [
      'Inclusions to be defined',
    ],
  };

  String _mgmtTier = 'Basic';
  String _dirTier = 'Basic Listing';
  bool _tierPrefilled = false;

  // ─── Listing presence ───────────────────────────────────
  // Listings live in their own collection (written by AddListingPageView) with
  // an `ownerRef` DocumentReference back to the user — NOT a field on the user
  // doc. So we detect an existing listing by querying that collection, exactly
  // like EditListingPageView._findMyListingRef().
  static const String _listingCollection = 'subby_listings';
  static const String _listingOwnerRefField = 'ownerRef';
  static const String _listingOwnerIdField = 'ownerId'; // fallback (string uid)

  bool _listingChecked = false;
  bool _hasListingDoc = false;

  @override
  void initState() {
    super.initState();
    _checkListing();
  }

  Future<void> _checkListing() async {
    final userRef = currentUserReference;
    final uid = currentUserUid;

    if (userRef == null && (uid.isEmpty)) {
      if (mounted) {
        setState(() {
          _hasListingDoc = false;
          _listingChecked = true;
        });
      }
      return;
    }

    try {
      final colRef = FirebaseFirestore.instance.collection(_listingCollection);
      bool found = false;

      // Primary: ownerRef == user reference.
      if (userRef != null) {
        final snap = await colRef
            .where(_listingOwnerRefField, isEqualTo: userRef)
            .limit(1)
            .get();
        found = snap.docs.isNotEmpty;
      }

      // Fallback: ownerId == uid string (in case some docs store the uid).
      if (!found && uid.isNotEmpty) {
        final snap = await colRef
            .where(_listingOwnerIdField, isEqualTo: uid)
            .limit(1)
            .get();
        found = snap.docs.isNotEmpty;
      }

      if (!mounted) return;
      setState(() {
        _hasListingDoc = found;
        _listingChecked = true;
      });
    } catch (e) {
      debugPrint('⚠️ listing check failed: $e');
      if (!mounted) return;
      setState(() => _listingChecked = true);
    }
  }

  // =========================================================
  // ✅ TYPOGRAPHY
  // =========================================================
  TextStyle _pageTitle(FlutterFlowTheme t) => t.titleLarge.override(
        fontFamily: _displayFont,
        color: _ink,
        fontWeight: FontWeight.w900,
        fontSize: 30,
        lineHeight: 1.05,
      );

  TextStyle _pageSubtitle(FlutterFlowTheme t) => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: _inkMute,
      );

  TextStyle _heroName(FlutterFlowTheme t) => t.titleLarge.override(
        fontFamily: _displayFont,
        fontWeight: FontWeight.w900,
        fontSize: 21,
        color: _ink,
      );

  TextStyle _uLabel(FlutterFlowTheme t) => const TextStyle(
        fontFamily: _bodyFont,
        color: _inkMute,
        letterSpacing: 0.6,
        fontWeight: FontWeight.w800,
        fontSize: 11,
      );

  TextStyle _rowTitle(FlutterFlowTheme t) => const TextStyle(
        fontFamily: _bodyFont,
        fontWeight: FontWeight.w700,
        fontSize: 15,
        color: _ink,
      );

  TextStyle _muted13(FlutterFlowTheme t) => const TextStyle(
        fontFamily: _bodyFont,
        fontWeight: FontWeight.w500,
        fontSize: 13,
        color: _faint,
      );

  // Subby-style snackbar.
  void _showToast(String message) {
    if (!mounted) return;
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
            side: const BorderSide(color: _hairline, width: 1),
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
              Expanded(
                child: Text(message,
                    style: const TextStyle(
                        fontFamily: _bodyFont, fontSize: 13, color: _ink)),
              ),
            ],
          ),
        ),
      );
  }

  void _pushOrToast(String route, String fallbackMessage) {
    final r = route.trim();
    if (r.isEmpty) {
      _showToast(fallbackMessage);
      return;
    }
    context.pushNamed(r);
  }

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
    return (currentUserEmail ?? '').toString().trim();
  }

  void _goEditPhoto() {
    final route = (widget.editPhotoRouteName ?? '').trim();
    if (route.isEmpty) {
      _showToast('Set editPhotoRouteName to open your photo picker page.');
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
              side: const BorderSide(color: _hairline, width: 1),
            ),
            title: Text('Delete profile?',
                style: theme.titleMedium.override(
                    fontFamily: _displayFont, fontWeight: FontWeight.w900)),
            content: Text(
              'This will permanently delete your account and profile data. '
              'This cannot be undone.',
              style: const TextStyle(
                  fontFamily: _bodyFont, color: _inkMute, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel',
                    style: theme.bodyMedium.override(
                        fontFamily: _bodyFont, fontWeight: FontWeight.w700)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Delete',
                    style: theme.bodyMedium.override(
                        fontFamily: _bodyFont,
                        color: _coral,
                        fontWeight: FontWeight.w900)),
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
      await userRef.delete();
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

  // ─── Avatar ─────────────────────────────────────────────
  Widget _avatar(FlutterFlowTheme theme, String photoUrl, String displayName) {
    final initials = Center(
      child: Text(
        _initialsFromName(displayName),
        style: const TextStyle(
          fontFamily: _bodyFont,
          fontWeight: FontWeight.w900,
          fontSize: 24,
          color: _spark,
        ),
      ),
    );

    return GestureDetector(
      onTap: _goEditPhoto,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _ink,
          border: Border.all(color: _spark, width: 2.5),
        ),
        child: ClipOval(
          child: photoUrl.isNotEmpty
              ? Image.network(photoUrl,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => initials)
              : initials,
        ),
      ),
    );
  }

  // ─── Plan tier pill ─────────────────────────────────────
  Widget _tierPill(String t,
      {required bool selected, required VoidCallback onTap}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3.5),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? _teal : _surface,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              t,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: _bodyFont,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: selected ? _paper : _inkMute,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _perkRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, size: 17, color: _teal),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: _bodyFont,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: _inkMute,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Underline action row ───────────────────────────────
  Widget _uActionRow(
    FlutterFlowTheme theme, {
    required IconData icon,
    required String label,
    Widget? subtitle,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: _rowTitle(theme)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      subtitle,
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 22, color: _hairlineOnSurface),
            ],
          ),
        ),
      ),
    );
  }

  Widget _liveSubtitle(FlutterFlowTheme theme) => Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(color: _ok, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text('Live in Directory', style: _muted13(theme)),
        ],
      );

  // ─── Buttons ────────────────────────────────────────────
  Widget _primaryButton({
    required String label,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: _ink,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 19, color: _paper),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                fontFamily: _bodyFont,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: _paper,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _outlineButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color borderColor = _hairlineOnSurface,
    Color textColor = _ink,
    Color iconColor = _inkMute,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: _bodyFont,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(FlutterFlowTheme theme, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(text.toUpperCase(), style: _uLabel(theme)),
      );

  // ─── Logged-out state ───────────────────────────────────
  Widget _loggedOut(FlutterFlowTheme theme, double width, double height) {
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
                  child:
                      const Icon(Icons.lock_outline, color: _inkMute, size: 24),
                ),
                const SizedBox(height: 16),
                Text('You are logged out',
                    textAlign: TextAlign.center,
                    style: theme.titleMedium.override(
                        fontFamily: _displayFont,
                        fontWeight: FontWeight.w900,
                        color: _ink)),
                const SizedBox(height: 6),
                Text('Log in or create an account to continue.',
                    textAlign: TextAlign.center, style: _pageSubtitle(theme)),
                const SizedBox(height: 22),
                _primaryButton(
                    label: 'Log in',
                    onTap: () => context.pushNamed(_loginRouteName)),
                const SizedBox(height: 10),
                _outlineButton(
                    label: 'Create account',
                    icon: Icons.person_add_alt_1_outlined,
                    onTap: () => context.pushNamed(_createAccountRouteName)),
              ],
            ),
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

    final userRef = currentUserReference;
    if (userRef == null) return _loggedOut(theme, width, height);

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
              final photoUrl = (data['photo_url'] ?? '').toString().trim();
              final email = _bestEmail((data['email'] ?? '').toString());

              // Package + listing presence (adjust field names to your schema).
              final pkg = (data['package'] ?? 'Basic').toString();
              if (!_tierPrefilled) {
                _mgmtTier = _mgmtTiers.contains(pkg) ? pkg : 'Basic';
                _tierPrefilled = true;
              }
              // Listing presence is resolved asynchronously in _checkListing()
              // by querying the subby_listings collection (ownerRef == user).
              final hasListing = _hasListingDoc;

              final mgmtPerks = _mgmtPerks[_mgmtTier] ?? const <String>[];
              final dirPerks = _dirPerks[_dirTier] ?? const <String>[];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== HEADER =====
                  Padding(
                    padding: const EdgeInsets.fromLTRB(_hPad, _vPad, _hPad, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Account', style: _pageTitle(theme)),
                        const SizedBox(height: 8),
                        Text('Manage your profile, listing and plan.',
                            style: _pageSubtitle(theme)),
                      ],
                    ),
                  ),

                  // ===== CONTENT =====
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(_hPad, 20, _hPad, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar hero
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
                                    style: _heroName(theme)),
                                const SizedBox(height: 3),
                                Text(email.isEmpty ? '—' : email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontFamily: _bodyFont,
                                        fontSize: 13,
                                        color: _faint)),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // ===== PROJECT MANAGEMENT =====
                          _sectionLabel(theme, 'Project management'),
                          const SizedBox(height: 10),
                          Row(
                            children: _mgmtTiers
                                .map((t) => _tierPill(t,
                                    selected: t == _mgmtTier,
                                    onTap: () => setState(() => _mgmtTier = t)))
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                          Text('YOUR ${_mgmtTier.toUpperCase()} PLAN INCLUDES',
                              style: const TextStyle(
                                  fontFamily: _bodyFont,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                  color: _ink)),
                          const SizedBox(height: 8),
                          ...mgmtPerks.map(_perkRow),

                          const SizedBox(height: 30),

                          // ===== DIRECTORY =====
                          _sectionLabel(theme, 'Directory'),
                          const SizedBox(height: 10),
                          Row(
                            children: _dirTiers
                                .map((t) => _tierPill(t,
                                    selected: t == _dirTier,
                                    onTap: () => setState(() => _dirTier = t)))
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                          Text('YOUR ${_dirTier.toUpperCase()} INCLUDES',
                              style: const TextStyle(
                                  fontFamily: _bodyFont,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                  color: _ink)),
                          const SizedBox(height: 8),
                          ...dirPerks.map(_perkRow),
                          const SizedBox(height: 16),
                          _primaryButton(
                            label: !_listingChecked
                                ? 'Checking listing…'
                                : (hasListing
                                    ? 'Edit Listing'
                                    : 'Create Listing'),
                            icon: !_listingChecked
                                ? Icons.hourglass_top_rounded
                                : (hasListing
                                    ? Icons.edit_outlined
                                    : Icons.add_rounded),
                            onTap: () {
                              if (!_listingChecked) return;
                              if (hasListing) {
                                _pushOrToast(_editListingRouteName,
                                    'Set _editListingRouteName.');
                              } else {
                                _pushOrToast(_addListingRouteName,
                                    'Set _addListingRouteName.');
                              }
                            },
                          ),

                          const SizedBox(height: 30),

                          // ===== SETTINGS =====
                          _sectionLabel(theme, 'Settings'),
                          _uActionRow(
                            theme,
                            icon: Icons.person_outline,
                            label: 'Personal details',
                            onTap: () =>
                                context.pushNamed(_editProfileRouteName),
                          ),
                          _uActionRow(
                            theme,
                            icon: Icons.notifications_none_rounded,
                            label: 'Notifications',
                            showDivider: false,
                            onTap: _goNotifications,
                          ),

                          const SizedBox(height: 30),

                          // ===== Logout / Delete =====
                          Row(
                            children: [
                              Expanded(
                                child: _outlineButton(
                                  label: 'Logout',
                                  icon: Icons.logout,
                                  onTap: _logout,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _outlineButton(
                                  label: 'Delete',
                                  icon: Icons.delete_outline,
                                  borderColor: _coral.withOpacity(0.6),
                                  textColor: _coral,
                                  iconColor: _coral,
                                  onTap: _confirmAndDeleteProfile,
                                ),
                              ),
                            ],
                          ),
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
