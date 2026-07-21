// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom widgets

import '/custom_code/actions/index.dart';

// ✅ provides currentUserReference, currentUserEmail, etc.
import '/auth/firebase_auth/auth_util.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// =============================================================================
// ProfilePageView — ACCOUNT hub (v7, steel/accent restyle)
//
//   • Steel identity hero (avatar + name + email) with an Edit pencil that
//     opens EditProfilePageView.
//   • Projects / Directory segmented switcher (option A). Each section shows a
//     "Free while in beta" note. Directory keeps the Create/Edit Listing CTA.
//   • Logout / Delete preserved (real Firebase logic).
//   • No packages/tiers — free service for launch.
//
// Host inside a page that places MainBottomNav(currentIndex: 2).
// =============================================================================

enum _AccountSection { projects, directory }

class ProfilePageView extends StatefulWidget {
  const ProfilePageView({
    Key? key,
    this.width,
    this.height,
    this.editPhotoRouteName,
  }) : super(key: key);

  final double? width;
  final double? height;

  /// Optional — legacy. Photo editing now lives on EditProfilePageView.
  final String? editPhotoRouteName;

  @override
  State<ProfilePageView> createState() => _ProfilePageViewState();
}

class _ProfilePageViewState extends State<ProfilePageView> {
  // ─── SUBBY PALETTE (LOCK) — synced with DashboardPageView v6 ───────────
  static const Color _ink = Color(0xFF1E282E);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _hairline = Color(0xFFEAEEF0);
  static const Color _hairlineOnSurface = Color(0xFFDCE3E6);
  static const Color _steel = Color(0xFF2F3A4C); // hero background
  static const Color _accent = Color(0xFFE7E247); // primary CTA fill
  static const Color _coral = Color(0xFF566670);
  static const Color _warn = Color(0xFFAC0C0C); // delete-dialog red (shared)
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  // Route names — adjust to your FlutterFlow page names.
  static const String _loginRouteName = 'login';
  static const String _createAccountRouteName = 'createAccountPage';
  static const String _editProfileRouteName = 'editProfilePage';
  static const String _editListingRouteName = 'editListingPage';
  static const String _addListingRouteName = 'addListingPage';

  static const double _hPad = 20;

  _AccountSection _section = _AccountSection.projects;

  // ─── Listing presence (subby_listings.ownerRef == user) ───────────────
  static const String _listingCollection = 'subby_listings';
  static const String _listingOwnerRefField = 'ownerRef';
  static const String _listingOwnerIdField = 'ownerId';

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

    if (userRef == null && uid.isEmpty) {
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

      if (userRef != null) {
        final snap = await colRef
            .where(_listingOwnerRefField, isEqualTo: userRef)
            .limit(1)
            .get();
        found = snap.docs.isNotEmpty;
      }
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
  // TYPOGRAPHY
  // =========================================================
  TextStyle get _sectionTitle => const TextStyle(
        fontFamily: _displayFont,
        fontWeight: FontWeight.w800,
        fontSize: 17,
        letterSpacing: -0.3,
        color: _ink,
      );

  TextStyle get _sectionSub => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: _faint,
      );

  // Subby-style snackbar.
  void _showToast(String message) {
    if (!mounted) return;
    showAppToast(context, message, false);
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

  void _goEditProfile() => context.pushNamed(_editProfileRouteName);

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
    FocusScope.of(context).unfocus();
    await _showDeleteDialog(
      icon: Icons.delete_rounded,
      title: 'Delete profile?',
      message:
          'This will permanently delete your account and profile data. This can’t be undone.',
      confirmLabel: 'Delete profile',
      onConfirm: _deleteProfile,
    );
  }

  // Centred destructive confirm dialog — shared "delete warning" module
  // (clay badge, 22-radius card, filled clay confirm + outlined cancel over a
  // 55%-black scrim), identical to DetailTaskPageView._showDeleteDialog.
  Future<void> _showDeleteDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required IconData icon,
    required Future<void> Function() onConfirm,
  }) async {
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _paper,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.30),
                  blurRadius: 54,
                  offset: const Offset(0, 22),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _warn.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: _warn.withOpacity(0.22), width: 1),
                  ),
                  child: Icon(icon, color: _warn, size: 30),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: _displayFont,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    fontSize: 18,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: _bodyFont,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    fontSize: 14,
                    color: _inkMute,
                  ),
                ),
                const SizedBox(height: 22),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      Navigator.pop(ctx);
                      await onConfirm();
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _warn,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        confirmLabel,
                        style: const TextStyle(
                          fontFamily: _bodyFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: _paper,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(ctx),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _paper,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFCBD8DD), width: 1.4),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: _bodyFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: _ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  // ─── Empty-state avatar (shared look with EditProfilePageView) ─────────
  Widget _avatar(String photoUrl, String displayName, {double size = 64}) {
    final initials = Center(
      child: Text(
        _initialsFromName(displayName),
        style: TextStyle(
          fontFamily: _bodyFont,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.34,
          color: _steel,
        ),
      ),
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _paper,
        border: Border.all(color: _accent, width: 2.5),
      ),
      child: ClipOval(
        child: photoUrl.isNotEmpty
            ? Image.network(photoUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => initials)
            : initials,
      ),
    );
  }

  // ─── Steel identity hero ───────────────────────────────────────────────
  Widget _hero(String displayName, String email, String photoUrl) {
    return Container(
      width: double.infinity,
      color: _steel,
      padding: EdgeInsets.fromLTRB(
          _hPad, MediaQuery.of(context).padding.top + 10, _hPad, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ACCOUNT',
              style: TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: _paper.withOpacity(0.55))),
          const SizedBox(height: 16),
          Row(
            children: [
              _avatar(photoUrl, displayName, size: 64),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName.isEmpty ? 'Your name' : displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: _displayFont,
                            fontWeight: FontWeight.w900,
                            fontSize: 21,
                            color: _paper)),
                    const SizedBox(height: 3),
                    Text(email.isEmpty ? '—' : email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _paper.withOpacity(0.6))),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _goEditProfile,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: _paper.withOpacity(0.14),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.edit_outlined,
                        size: 18, color: _paper),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Projects / Directory switcher (animated sliding pill) ─────────────
  Widget _seg(String label, IconData icon, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? _paper : _inkMute),
            const SizedBox(width: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 240),
              style: TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: selected ? _paper : _inkMute),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switcher() {
    final isProjects = _section == _AccountSection.projects;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final pillW = (c.maxWidth - 6) / 2;
          return Stack(
            children: [
              // Sliding pill.
              AnimatedAlign(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment:
                    isProjects ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  width: pillW,
                  height: 38,
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: _steel,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    _seg(
                        'Projects',
                        Icons.grid_view_rounded,
                        isProjects,
                        () => setState(
                            () => _section = _AccountSection.projects)),
                    _seg(
                        'Directory',
                        Icons.contacts_outlined,
                        !isProjects,
                        () => setState(
                            () => _section = _AccountSection.directory)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 18,
                decoration: BoxDecoration(
                    color: _ink, borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: _sectionTitle)),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: _sectionSub),
        ],
      );

  Widget _freeNote(String detail) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: _surface, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, size: 19, color: _steel),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Free while in beta',
                      style: TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _ink)),
                  const SizedBox(height: 2),
                  Text(detail,
                      style: const TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _inkMute)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _accentButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
            color: _accent, borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19, color: _ink),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _ink)),
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
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: textColor)),
          ],
        ),
      ),
    );
  }

  Widget _projectsSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Project management',
              'Build & manage your home projects — tasks, costs, timeline & snags.'),
          const SizedBox(height: 14),
          _freeNote('All project features included.'),
        ],
      );

  Widget _directorySection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Directory listing',
              'How you appear to homeowners browsing the Directory.'),
          const SizedBox(height: 14),
          _freeNote('List your business at no cost.'),
          const SizedBox(height: 16),
          _accentButton(
            !_listingChecked
                ? 'Checking listing…'
                : (_hasListingDoc ? 'Edit Listing' : 'Create Listing'),
            !_listingChecked
                ? Icons.hourglass_top_rounded
                : (_hasListingDoc ? Icons.edit_outlined : Icons.add_rounded),
            () {
              if (!_listingChecked) return;
              if (_hasListingDoc) {
                _pushOrToast(_editListingRouteName, 'Set editListingPage.');
              } else {
                _pushOrToast(_addListingRouteName, 'Set addListingPage.');
              }
            },
          ),
        ],
      );

  // ─── Logged-out state ───────────────────────────────────────────────
  Widget _loggedOut(FlutterFlowTheme theme, double width, double height) {
    return SizedBox(
      width: width,
      height: height,
      child: SafeArea(
        child: Container(
          color: _paper,
          padding: const EdgeInsets.fromLTRB(_hPad, 14, _hPad, 14),
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
                const Text('Log in or create an account to continue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: _bodyFont, fontSize: 13, color: _inkMute)),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: _accentButton('Log in', Icons.login,
                      () => context.pushNamed(_loginRouteName)),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: _outlineButton(
                      label: 'Create account',
                      icon: Icons.person_add_alt_1_outlined,
                      onTap: () => context.pushNamed(_createAccountRouteName)),
                ),
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
                    valueColor: AlwaysStoppedAnimation<Color>(_steel),
                  ),
                ),
              );
            }

            final data = (snap.data!.data() as Map<String, dynamic>?) ?? {};
            final displayName = (data['display_name'] ?? '').toString().trim();
            final photoUrl = (data['photo_url'] ?? '').toString().trim();
            final email = _bestEmail((data['email'] ?? '').toString());

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _hero(displayName, email, photoUrl),
                Expanded(
                  child: SingleChildScrollView(
                    // bottom padding clears the overlaid MainBottomNav (~84px).
                    padding: const EdgeInsets.fromLTRB(_hPad, 24, _hPad, 108),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _switcher(),
                        const SizedBox(height: 24),
                        _section == _AccountSection.projects
                            ? _projectsSection()
                            : _directorySection(),
                        const SizedBox(height: 28),
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
                                borderColor: _coral.withOpacity(0.5),
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
    );
  }
}
