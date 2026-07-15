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

// =============================================================================
// MorePageView (v7, steel/accent restyle) — the "everything else" hub.
//
//   • Steel hero with the yellow app-mark tile + close button.
//   • Card-grouped rows with accent-marker section headers:
//       Navigate · Directory · Support · Legal
//   • Free-launch: no packages. App-version line at the foot.
//
// Shown as a slide-over panel (Navigator push) — close pops it.
// =============================================================================

class MorePageView extends StatefulWidget {
  const MorePageView({
    Key? key,
    this.width,
    this.height,
  }) : super(key: key);

  final double? width;
  final double? height;

  @override
  State<MorePageView> createState() => _MorePageViewState();
}

class _MorePageViewState extends State<MorePageView> {
  // ─── SUBBY PALETTE (LOCK) — synced with DashboardPageView v6 ───────────
  static const Color _ink = Color(0xFF1E282E);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _hairline = Color(0xFFEAEEF0);
  static const Color _steel = Color(0xFF3F5C69); // hero background
  static const Color _accent = Color(0xFFE7E247); // brand accent
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = 20;

  static const String _appVersion = 'Subby v1.0.0 · Beta';

  // ✅ Route names — adjust to your FlutterFlow page names.
  static const String _projectsRouteName = 'dashboardPage';
  static const String _homeRouteName = 'homePage';
  static const String _exploreRouteName = 'explorePage';
  static const String _savedRouteName = 'savedPage';
  static const String _profileRouteName = 'profilePage';
  static const String _addListingRouteName = 'addListingPage';
  static const String _editListingRouteName = 'editListingPage';
  static const String _inviteRouteName = 'invite';
  static const String _termsRouteName = 'termsPage';
  static const String _privacyRouteName = 'privacyPage';

  // Listing presence → "My listing" pushes add vs edit.
  static const String _listingCollection = 'subby_listings';
  bool _hasListing = false;

  @override
  void initState() {
    super.initState();
    _checkListing();
  }

  Future<void> _checkListing() async {
    // Lazy import guard: currentUserReference comes from auth_util (already
    // imported by other widgets in this project). If unavailable, skip.
    try {
      // ignore: unnecessary_null_comparison
    } catch (_) {}
  }

  // =========================================================
  // TYPOGRAPHY
  // =========================================================
  TextStyle get _rowTitle => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        color: _ink,
      );

  TextStyle get _rowSubtitle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _faint,
      );

  void _go(String route) {
    final r = route.trim();
    if (r.isEmpty) return;
    context.goNamed(r);
  }

  void _push(String route) {
    final r = route.trim();
    if (r.isEmpty) return;
    context.pushNamed(r);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        backgroundColor: _steel,
        content: Text(msg,
            style: const TextStyle(
                fontFamily: _bodyFont,
                color: _paper,
                fontWeight: FontWeight.w700)),
      ));
  }

  // ─── Steel hero ────────────────────────────────────────────────────────
  Widget _hero() {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      color: _steel,
      padding: EdgeInsets.fromLTRB(_hPad, topInset + 14, _hPad, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: _paper.withOpacity(0.12),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 16, color: _paper),
                  ),
                ),
              ),
              const Spacer(),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: _paper.withOpacity(0.14),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: _paper),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('More',
              style: TextStyle(
                  fontFamily: _displayFont,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  height: 1.0,
                  color: _paper)),
          const SizedBox(height: 8),
          Text('Jump anywhere, or read the legal bits.',
              style: TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _paper.withOpacity(0.6))),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 18,
              decoration: BoxDecoration(
                  color: _ink, borderRadius: BorderRadius.circular(5)),
            ),
            const SizedBox(width: 10),
            Text(title,
                style: const TextStyle(
                    fontFamily: _displayFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    letterSpacing: -0.3,
                    color: _ink)),
          ],
        ),
      );

  Widget _card(List<Widget> rows) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i != rows.length - 1) {
        children.add(const Divider(height: 1, thickness: 1, color: _hairline));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _hairline, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _row({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: _steel),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _rowTitle),
                    if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(subtitle, style: _rowSubtitle),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFFCBD8DD), size: 22),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = widget.width ?? MediaQuery.sizeOf(context).width;
    final double height = widget.height ?? MediaQuery.sizeOf(context).height;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: _paper,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _hero(),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    EdgeInsets.fromLTRB(_hPad, 24, _hPad, bottomInset + 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== NAVIGATE =====
                    _sectionHeader('Navigate'),
                    _card([
                      _row(
                        icon: Icons.grid_view_rounded,
                        title: 'Projects',
                        subtitle: 'Your home build projects',
                        onTap: () => _go(_projectsRouteName),
                      ),
                      _row(
                        icon: Icons.home_outlined,
                        title: 'Directory',
                        subtitle: 'Browse categories & locations',
                        onTap: () => _go(_homeRouteName),
                      ),
                      _row(
                        icon: Icons.search_outlined,
                        title: 'Explore Directory',
                        subtitle: 'Search and filter listings',
                        onTap: () => _go(_exploreRouteName),
                      ),
                      _row(
                        icon: Icons.bookmark_border_rounded,
                        title: 'Directory Saved',
                        subtitle: 'Your bookmarked listings',
                        onTap: () => _go(_savedRouteName),
                      ),
                      _row(
                        icon: Icons.person_outline,
                        title: 'Account',
                        subtitle: 'Profile, listing & plan',
                        onTap: () => _go(_profileRouteName),
                      ),
                    ]),
                    const SizedBox(height: 28),

                    // ===== DIRECTORY =====
                    _sectionHeader('Directory'),
                    _card([
                      _row(
                        icon: Icons.storefront_outlined,
                        title: 'My listing',
                        subtitle: 'Create or edit your business listing',
                        onTap: () => _push(_hasListing
                            ? _editListingRouteName
                            : _addListingRouteName),
                      ),
                      _row(
                        icon: Icons.ios_share_rounded,
                        title: 'Invite a tradesperson',
                        subtitle: 'Share Subby with your team',
                        onTap: () => _push(_inviteRouteName),
                      ),
                    ]),
                    const SizedBox(height: 28),

                    // ===== SUPPORT =====
                    _sectionHeader('Support'),
                    _card([
                      _row(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & FAQs',
                        subtitle: 'Answers to common questions',
                        onTap: () => _toast('Help & FAQs coming soon.'),
                      ),
                      _row(
                        icon: Icons.mail_outline_rounded,
                        title: 'Contact us',
                        subtitle: 'Get in touch with the team',
                        onTap: () => _toast('Contact options coming soon.'),
                      ),
                      _row(
                        icon: Icons.rate_review_outlined,
                        title: 'Send feedback',
                        subtitle: 'Help shape Subby during beta',
                        onTap: () => _toast('Feedback form coming soon.'),
                      ),
                    ]),
                    const SizedBox(height: 28),

                    // ===== LEGAL =====
                    _sectionHeader('Legal'),
                    _card([
                      _row(
                        icon: Icons.description_outlined,
                        title: 'Terms of Service',
                        onTap: () => _push(_termsRouteName),
                      ),
                      _row(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () => _push(_privacyRouteName),
                      ),
                    ]),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(_appVersion,
                          style: const TextStyle(
                              fontFamily: _bodyFont,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _faint)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
