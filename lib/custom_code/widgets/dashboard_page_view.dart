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

import 'index.dart'; // Imports other custom widgets

import 'index.dart'; // Imports other custom widgets

import 'index.dart'; // Imports other custom widgets

// ======================= DashboardPageView (FULL FILE) =======================
//
// v5 — "Focus" home: most-recent project as a HERO card with a large
//       progress ring, the remaining projects as a condensed quick-list.
//       (v4 = portfolio overview list; data/logic unchanged across both.)
//
// WHAT CHANGED FROM v3 (UI only — all logic preserved):
//   • Welcome header is now big & minimal: an uppercase date eyebrow + a
//     teal-ringed initials avatar (notification dot), then a large two-line
//     time-of-day greeting. The header logo is now the bold peak MARK only
//     (no wordmark).
//   • Empty state is a lean ONBOARDING panel (Option C): a teal hero tile, a
//     one-line headline, a single promise sentence and a row of capability
//     chips (Plans · Budget · Programme · Snags · Quotes) — no dense
//     checklist. Then Create project (primary) and Create user profile
//     (secondary — hidden once a profile exists). The persistent bottom nav
//     (MainBottomNav, overlaid by the scaffold) stays put underneath.
//   • New at-a-glance STAT STRIP derived live from the projects stream:
//     Active builds · On track · Needs you.
//   • Projects are a vertical LIST with circular PROGRESS RINGS (was a rail).
//   • The Directory section is GONE from this screen — it now lives in the new
//     bottom nav. Its navigation logic is RETAINED in _goToListing() (+ the
//     listing-check) so it can be wired up from the nav without rebuilding it.
//
// PRESERVED: every constructor param (used + legacy), _safeNavigate /
// _goToProject / _goToAddProject, the active-projects query, the listing-exists
// check, route fallbacks, and date formatting.
//
// PROJECT DOC FIELDS READ (all optional, safe fallbacks):
//   name, city, province, status, updatedAt  (as before)
//   progress : num — 0..1 OR 0..100, drives the ring. Missing ⇒ 0%.

import '/custom_code/widgets/index.dart';
import 'dart:ui';
import '/auth/firebase_auth/auth_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardPageView extends StatefulWidget {
  const DashboardPageView({
    super.key,
    this.width,
    this.height,

    /// Routes — USED
    this.directoryRouteName,
    this.projectsRouteName, // "View all" → MyProjectsHomePage
    this.profileRouteName,
    this.loginRouteName, // signed-out empty state → Log in
    this.createAccountRouteName, // signed-out empty state → Create account
    this.moreRouteName, // top-right menu → More hub
    this.projectDetailRouteName, // open a single project
    this.addProjectsRouteName, // create a new project
    this.projectParamName, // param name for the project ref (default "projectRef")

    /// Listing management routes — RETAINED (Directory now lives in the nav)
    this.addListingRouteName,
    this.editListingRouteName,

    /// LEGACY — kept for FF compatibility, no longer used by this screen
    this.timelineRouteName,
    this.snagListRouteName,
    this.projectCostRouteName,
    this.getQuotesRouteName,
    this.termsRouteName,
    this.privacyRouteName,
    this.supportRouteName,
    this.snagCount,
    this.myProjectsCount,
  });

  final double? width;
  final double? height;

  // USED
  final String? directoryRouteName;
  final String? projectsRouteName;
  final String? profileRouteName;
  final String? loginRouteName;
  final String? createAccountRouteName;
  final String? moreRouteName;
  final String? projectDetailRouteName;
  final String? addProjectsRouteName;
  final String? projectParamName;

  // RETAINED for the Directory (now in the bottom nav)
  final String? addListingRouteName;
  final String? editListingRouteName;

  // LEGACY (unused)
  final String? timelineRouteName;
  final String? snagListRouteName;
  final String? projectCostRouteName;
  final String? getQuotesRouteName;
  final String? termsRouteName;
  final String? privacyRouteName;
  final String? supportRouteName;
  final int? snagCount;
  final int? myProjectsCount;

  @override
  State<DashboardPageView> createState() => _DashboardPageViewState();
}

class _DashboardPageViewState extends State<DashboardPageView> {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  // Inline = authoritative for this file. Grep `SUBBY PALETTE (LOCK)` to sync.
  //
  // Neutrals
  static const Color _ink = Color(0xFF017374); // text, chrome, dark surfaces
  static const Color _inkMute = Color(0xFF5A6675);
  static const Color _faint = Color(0xFF93A0B0); // muted labels, chevrons
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFEEF1F4);
  static const Color _hairline = Color(0xFFEEF1F2);

  // Accents
  static const Color _yellow =
      Color(0xFF017374); // deep teal — "on site" / on track
  static const Color _ringTrack = Color(0xFFEEF2F7);
  static const Color _orange = Color(0xFFE5771E); // attention / snagging
  static const Color _orangeTint = Color(0xFFFBE3CC);
  static const Color _orangeBorder = Color(0xFFE5771E);
  static const Color _orangeText = Color(0xFFE5771E);
  static const Color _projTint = Color(0xFFEEF1F4); // add / empty card fill

  // Geometry
  static const double _rSmall = 6;
  static const double _rMed = 8;
  static const double _rLarge = 12;
  static const double _rPill = 999;
  static const double _pageHPad = 20;

  // Type
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const String _monoFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = _pageHPad;
  static const double _radius = _rLarge;

  // Spacing rhythm
  static const double _titleToDesc = 8;

  // Route fallbacks
  static const String _fallbackProfileRoute = 'profilePage';
  static const String _fallbackLoginRoute = 'login'; // LoginWidget.routeName
  static const String _fallbackCreateAccountRoute =
      'createAccountPage'; // CreateAccountPageWidget.routeName
  // ignore: unused_field
  static const String _fallbackMoreRoute = 'MorePageView';
  static const String _fallbackProjectsRoute = 'MyProjectsHomePage';
  static const String _fallbackProjectDetailRoute = 'ProjectDetailPage';
  static const String _fallbackAddProjectsRoute = 'addProjectsPage';
  static const String _fallbackAddListingRoute = 'addListingPage';
  static const String _fallbackEditListingRoute = 'editListingPage';

  // Listing exists (RETAINED — drives Add / Edit for the Directory in the nav)
  // ignore: unused_field
  bool _hasListing = false;
  bool _listingCheckInFlight = false;
  int _lastListingCheckMs = 0;

  // Date formatting (SA: DD MMM YYYY)
  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  String _fmtDate(DateTime? d) {
    if (d == null) return '';
    final dd = d.day.toString().padLeft(2, '0');
    return '$dd ${_months[d.month - 1]} ${d.year}';
  }

  // "WED 18 JUN"
  String _eyebrowDate(DateTime d) =>
      '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}'
          .toUpperCase();

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _initials(String name) {
    final n = name.trim();
    if (n.isEmpty) return '';
    final parts = n.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      final p = parts.first;
      return (p.length >= 2 ? p.substring(0, 2) : p).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  // =========================================================
  // TYPOGRAPHY
  // =========================================================
  TextStyle get _eyebrowStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: _faint,
      );

  TextStyle get _greetingStyle => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        height: 1.08,
        color: _ink,
      );

  TextStyle get _stepHeadlineStyle => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 17,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        height: 1.05,
        color: _ink,
      );

  TextStyle get _tileTitleStyle => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        color: _ink,
      );

  TextStyle get _tileSubtitleStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: _faint,
      );

  TextStyle get _statNumberStyle => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 26,
        fontWeight: FontWeight.w800,
        height: 1.0,
        color: _ink,
      );

  TextStyle get _ringPctStyle => const TextStyle(
        fontFamily: _monoFont,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: _ink,
        fontFeatures: [FontFeature.tabularFigures()],
      );

  // Focus layout — hero card
  TextStyle get _heroEyebrowStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: _yellow,
      );

  TextStyle get _heroTitleStyle => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 19,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: _ink,
      );
  // =========================================================

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _refreshHasListing(force: true);
    });
  }

  // -----------------------------
  // Navigation
  // -----------------------------
  void _safeNavigate(String? route, {String? fallbackRoute}) {
    final r = (route ?? '').trim();
    final fb = (fallbackRoute ?? '').trim();
    final target = r.isNotEmpty ? r : fb;
    if (target.isEmpty) return;

    context.pushNamed(target);
  }

  void _goToAddProject() => _safeNavigate(
        widget.addProjectsRouteName,
        fallbackRoute: _fallbackAddProjectsRoute,
      );

  // RETAINED — "View all" was removed (contractors top out at ~8–10 projects,
  // all shown inline). Kept so the projects route can still be reached if needed.
  // ignore: unused_element
  void _goToProjects() => _safeNavigate(
        widget.projectsRouteName,
        fallbackRoute: _fallbackProjectsRoute,
      );

  void _goToProfile() => _safeNavigate(
        widget.profileRouteName,
        fallbackRoute: _fallbackProfileRoute,
      );

  // Signed-out empty state CTAs.
  void _goToCreateAccount() => _safeNavigate(
        widget.createAccountRouteName,
        fallbackRoute: _fallbackCreateAccountRoute,
      );

  void _goToLogin() => _safeNavigate(
        widget.loginRouteName,
        fallbackRoute: _fallbackLoginRoute,
      );

  // Top-right menu button → the More hub (Manage · Support · Legal).
  // Pushed as a standard page so it uses the same platform transition as
  // every other in-page link — matching ProfilePageView's _openMore().
  void _goToMore() => _openMore();

  void _openMore() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MorePageView()),
    );
  }

  // RETAINED: the Directory's add-vs-edit decision, ready for the bottom nav.
  // ignore: unused_element
  void _goToListing() {
    if (_hasListing) {
      _safeNavigate(
        widget.editListingRouteName,
        fallbackRoute: _fallbackEditListingRoute,
      );
    } else {
      _safeNavigate(
        widget.addListingRouteName,
        fallbackRoute: _fallbackAddListingRoute,
      );
    }
  }

  // Open a single project — mirrors the contract used by MyProjectsHomePageView
  // (serialized DocumentReference in both queryParameters and extra).
  void _goToProject(DocumentReference projectRef) {
    final target = (widget.projectDetailRouteName ?? '').trim().isNotEmpty
        ? widget.projectDetailRouteName!.trim()
        : _fallbackProjectDetailRoute;

    final paramName = (widget.projectParamName ?? '').trim().isEmpty
        ? 'projectRef'
        : widget.projectParamName!.trim();

    context.pushNamed(
      target,
      queryParameters: <String, dynamic>{
        paramName: serializeParam(projectRef, ParamType.DocumentReference),
      }.withoutNulls,
      extra: <String, dynamic>{
        paramName: projectRef,
      },
    );
  }

  // -----------------------------
  // Projects query (live)
  // -----------------------------
  Query<Map<String, dynamic>>? _activeProjectsQuery() {
    final userRef = currentUserReference;
    if (userRef == null) return null;
    return FirebaseFirestore.instance
        .collection('projects')
        .where('ownerRef', isEqualTo: userRef)
        .where('archived', isEqualTo: false)
        .orderBy('updatedAt', descending: true)
        .limit(20);
  }

  // Archived projects (archived == true). Mirrors MyProjectsHomePageView's
  // archived query so the two screens stay in sync.
  Query<Map<String, dynamic>>? _archivedProjectsQuery() {
    final userRef = currentUserReference;
    if (userRef == null) return null;
    return FirebaseFirestore.instance
        .collection('projects')
        .where('ownerRef', isEqualTo: userRef)
        .where('archived', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .limit(20);
  }

  // -----------------------------
  // Listing exists for current user (RETAINED for the Directory in the nav)
  // Debounced + only setState on change.
  // -----------------------------
  Future<void> _refreshHasListing({bool force = false}) async {
    if (_listingCheckInFlight) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (!force && (nowMs - _lastListingCheckMs) < 350) return; // debounce
    _lastListingCheckMs = nowMs;

    _listingCheckInFlight = true;
    try {
      final userRef = currentUserReference;
      bool has = false;

      if (userRef != null) {
        final snap = await FirebaseFirestore.instance
            .collection('subby_listings')
            .where('ownerRef', isEqualTo: userRef)
            .limit(1)
            .get();
        has = snap.docs.isNotEmpty;
      }

      if (!mounted) return;
      if (has != _hasListing) {
        setState(() => _hasListing = has);
      }
    } catch (_) {
      // keep last known value on error
    } finally {
      _listingCheckInFlight = false;
    }
  }

  // -----------------------------
  // Project field helpers
  // -----------------------------
  double _progress(Map<String, dynamic> data) {
    final p = data['progress'];
    double v = 0;
    if (p is num) v = p.toDouble();
    if (v > 1) v = v / 100.0; // accept 0..100 as well as 0..1
    if (v.isNaN) v = 0;
    return v.clamp(0.0, 1.0);
  }

  bool _needsAttention(String status) {
    final t = status.toLowerCase();
    return t.contains('snag') ||
        t.contains('attention') ||
        t.contains('block') ||
        t.contains('overdue') ||
        t.contains('delay');
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  // -----------------------------
  // Small shared bits
  // -----------------------------
  Widget _accentMarker(Color c) => Container(
        width: 9,
        height: 16,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(5),
        ),
      );

  Widget _sectionHeader() => Row(
        children: [
          _accentMarker(_ink),
          const SizedBox(width: 10),
          Expanded(
              child: Text('My Building Projects', style: _stepHeadlineStyle)),
        ],
      );

  // =====================================================================
  // WELCOME — big & minimal
  // =====================================================================
  Widget _buildWelcomeHeader() {
    final topInset = MediaQuery.of(context).padding.top;
    final name = currentUserDisplayName.trim();
    final hasName = name.isNotEmpty;
    final firstName = hasName ? name.split(RegExp(r'\s+')).first : '';
    final now = DateTime.now();

    return Padding(
      padding: EdgeInsets.fromLTRB(_hPad, topInset + 14, _hPad, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _logo(),
              const Spacer(),
              _menuButton(),
            ],
          ),
          const SizedBox(height: 18),
          Text(_eyebrowDate(now), style: _eyebrowStyle),
          const SizedBox(height: 6),
          Text(
            hasName ? '${_greeting()},\n$firstName' : _greeting(),
            style: _greetingStyle,
          ),
        ],
      ),
    );
  }

  // Icon-only mark — bold, no wordmark.
  Widget _logo() => const SizedBox(
        width: 34,
        height: 34,
        child: CustomPaint(
          painter: _SubbyMarkPainter(peak: _yellow, base: _yellow),
        ),
      );

  Widget _menuButton() => InkWell(
        onTap: _goToMore,
        borderRadius: BorderRadius.circular(_rLarge),
        child: Container(
          width: 42,
          height: 42,
          margin: const EdgeInsets.only(right: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(_rLarge),
          ),
          child: const Icon(Icons.menu_rounded, size: 22, color: _ink),
        ),
      );

  // =====================================================================
  // BODY — stat strip + projects (single stream)
  // =====================================================================
  Widget _buildBody() {
    final q = _activeProjectsQuery();

    if (q == null) {
      // No authenticated user → the only actions are Create account / Log in.
      return Padding(
        padding: const EdgeInsets.fromLTRB(_hPad, 18, _hPad, 0),
        child: _buildSignedOut(),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(_hPad, 18, _hPad, 0),
            child: _buildOnboarding(),
          );
        }

        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return _bodyShell(child: _loadingList());
        }

        final docs = snap.data?.docs ?? const [];

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(_hPad, 18, _hPad, 0),
            child: _buildOnboarding(),
          );
        }

        // Derive stats from the same snapshot.
        final active = docs.length;
        int needs = 0;
        for (final d in docs) {
          final s = (d.data()['status'] as String?)?.trim() ?? '';
          if (_needsAttention(s)) needs++;
        }
        final onTrack = active - needs;

        // Focus layout: most-recent (the query is ordered updatedAt desc) is
        // the hero; everything after it is a condensed quick-list row.
        final feat = docs.first;
        final rest = docs.skip(1).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(_hPad, 18, _hPad, 0),
              child: _statStrip(active, onTrack, needs),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 0),
              child: _sectionHeader(),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _hPad),
              child: _heroCard(feat),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _hPad),
              child: Column(
                children: [
                  for (final d in rest) _condensedRow(d),
                  const SizedBox(height: 14),
                  _newProjectButton(),
                ],
              ),
            ),

            // Shared with me (added as a listing) — read-only projects.
            _buildSharedSection(),

            // Archived Building Projects — collapsed list below the active set.
            _buildArchivedSection(),
          ],
        );
      },
    );
  }

  // -----------------------------
  // Archived Building Projects section
  // -----------------------------
  Widget _buildArchivedSection() {
    final q = _archivedProjectsQuery();
    if (q == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? const [];
        // Hide the whole section when there's nothing archived.
        if (docs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _hPad),
              child: _archivedSectionHeader(),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _hPad),
              child: Column(
                children: [for (final d in docs) _archivedRow(d)],
              ),
            ),
          ],
        );
      },
    );
  }

  // -----------------------------
  // Shared Building Projects — projects this user was added to AS A LISTING.
  // Resolves the user's subby_listing(s) → project_listings → projects.
  // -----------------------------
  Future<List<_SharedProject>> _loadSharedProjects() async {
    final userRef = currentUserReference;
    if (userRef == null) return [];
    try {
      final listingsSnap = await FirebaseFirestore.instance
          .collection('subby_listings')
          .where('ownerRef', isEqualTo: userRef)
          .limit(10)
          .get();
      if (listingsSnap.docs.isEmpty) return [];

      final listingRefs =
          listingsSnap.docs.map((d) => d.reference).take(10).toList();

      final plSnap = await FirebaseFirestore.instance
          .collection('project_listings')
          .where('listingRef', whereIn: listingRefs)
          .get();

      final seen = <String>{};
      final futures = <Future<DocumentSnapshot<Map<String, dynamic>>>>[];
      for (final d in plSnap.docs) {
        final pr = d.data()['projectRef'];
        if (pr is DocumentReference && seen.add(pr.path)) {
          futures.add(
            pr
                .withConverter<Map<String, dynamic>>(
                  fromFirestore: (s, _) => s.data() ?? <String, dynamic>{},
                  toFirestore: (m, _) => m,
                )
                .get(),
          );
        }
      }
      final results = await Future.wait(futures);

      // Enrich each shared project with the project manager (project owner)
      // profile so the row can show who shared it.
      final out = <_SharedProject>[];
      for (final s in results.where((s) => s.exists)) {
        final data = s.data() ?? <String, dynamic>{};
        String pmName = (data['ownerName'] as String?)?.trim() ?? '';
        String pmPhoto = (data['ownerPhotoUrl'] as String?)?.trim() ?? '';
        final ownerRef = data['ownerRef'];
        if ((pmName.isEmpty || pmPhoto.isEmpty) &&
            ownerRef is DocumentReference) {
          try {
            final u = await ownerRef.get();
            final ud = u.data() as Map<String, dynamic>?;
            if (ud != null) {
              if (pmName.isEmpty) {
                pmName = (ud['display_name'] as String?)?.trim() ?? '';
              }
              if (pmPhoto.isEmpty) {
                pmPhoto = (ud['photo_url'] as String?)?.trim() ?? '';
              }
            }
          } catch (_) {}
        }
        out.add(_SharedProject(
          ref: s.reference,
          data: data,
          pmName: pmName,
          pmPhotoUrl: pmPhoto,
        ));
      }
      return out;
    } catch (e) {
      debugPrint('🔥 Failed to load shared projects: $e');
      return <_SharedProject>[];
    }
  }

  Widget _buildSharedSection() {
    if (currentUserReference == null) return const SizedBox.shrink();
    return FutureBuilder<List<_SharedProject>>(
      future: _loadSharedProjects(),
      builder: (context, snap) {
        final docs = snap.data ?? const <_SharedProject>[];
        if (docs.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _hPad),
              child: _sharedSectionHeader(),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _hPad),
              child: Text(
                "Projects you've been added to as a listing.",
                style: _tileSubtitleStyle.copyWith(fontSize: 12),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _hPad),
              child: Column(children: [for (final sp in docs) _sharedRow(sp)]),
            ),
          ],
        );
      },
    );
  }

  Widget _sharedSectionHeader() => Row(
        children: [
          _accentMarker(_ink),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Shared Building Projects', style: _stepHeadlineStyle),
          ),
        ],
      );

  Widget _sharedRow(_SharedProject sp) {
    final data = sp.data;
    final name = (data['name'] as String?)?.trim() ?? '';
    final city = (data['city'] as String?)?.trim() ?? '';
    final province = (data['province'] as String?)?.trim() ?? '';
    final loc = [city, province].where((x) => x.isNotEmpty).join(', ');
    final pm = sp.pmName.trim();
    final sub = pm.isNotEmpty
        ? 'Shared by $pm${loc.isNotEmpty ? ' • $loc' : ''}'
        : (loc.isEmpty ? 'Shared with you' : 'Shared with you • $loc');

    return InkWell(
      onTap: () => _goToProject(sp.ref),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F4F7))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: Color(0xFFE3F4F2),
                shape: BoxShape.circle,
              ),
              child: sp.pmPhotoUrl.isNotEmpty
                  ? Image.network(
                      sp.pmPhotoUrl,
                      width: 38,
                      height: 38,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => _sharedAvatarFallback(pm),
                    )
                  : _sharedAvatarFallback(pm),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Untitled project' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _tileTitleStyle.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.ios_share_rounded,
                          size: 13, color: _faint),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _tileSubtitleStyle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: Color(0xFFCDD6E2)),
          ],
        ),
      ),
    );
  }

  Widget _sharedAvatarFallback(String pm) => Text(
        pm.isNotEmpty ? _initials(pm) : '–',
        style: const TextStyle(
          fontFamily: _displayFont,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: _ink,
        ),
      );

  Widget _archivedSectionHeader() => Row(
        children: [
          _accentMarker(_faint),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Archived Building Projects',
              style: _stepHeadlineStyle.copyWith(color: _inkMute),
            ),
          ),
        ],
      );

  // A muted row: archive glyph, name, location, chevron — taps through to the
  // same project detail page as an active project.
  Widget _archivedRow(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final name = (data['name'] as String?)?.trim() ?? '';
    final city = (data['city'] as String?)?.trim() ?? '';
    final province = (data['province'] as String?)?.trim() ?? '';
    final loc = [city, province].where((x) => x.isNotEmpty).join(', ');

    return InkWell(
      onTap: () => _goToProject(doc.reference),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F4F7))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.archive_outlined, size: 19, color: _faint),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Untitled project' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        _tileTitleStyle.copyWith(fontSize: 14, color: _inkMute),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    loc.isEmpty ? 'No location set' : loc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _tileSubtitleStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: Color(0xFFCDD6E2)),
          ],
        ),
      ),
    );
  }

  Widget _bodyShell({required Widget child}) => Padding(
        padding: const EdgeInsets.fromLTRB(_hPad, 18, _hPad, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );

  // -----------------------------
  // Stat strip
  // -----------------------------
  Widget _statStrip(int active, int onTrack, int needs) => Row(
        children: [
          Expanded(child: _statTile('$active', 'Active builds', dark: true)),
          const SizedBox(width: 10),
          Expanded(child: _statTile('$onTrack', 'On track')),
          const SizedBox(width: 10),
          Expanded(child: _statTile('$needs', 'Needs you', attention: true)),
        ],
      );

  Widget _statTile(
    String value,
    String label, {
    bool dark = false,
    bool attention = false,
  }) {
    final Color bg = dark ? _ink : _paper;
    final Color numColor = dark ? _paper : (attention ? _orange : _ink);
    final Color labelColor = dark
        ? Colors.white.withOpacity(0.7)
        : (attention ? _orangeText : _faint);

    return Container(
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(11),
        border: dark
            ? null
            : Border.all(color: attention ? _orangeBorder : _hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: _statNumberStyle.copyWith(color: numColor)),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: _bodyFont,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------
  // Focus layout — hero card (most recent project)
  // -----------------------------
  Widget _heroCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final name = (data['name'] as String?)?.trim() ?? '';
    final city = (data['city'] as String?)?.trim() ?? '';
    final province = (data['province'] as String?)?.trim() ?? '';
    final status = (data['status'] as String?)?.trim() ?? '';
    final loc = [city, province].where((x) => x.isNotEmpty).join(', ');
    final attention = _needsAttention(status);
    final progress = _progress(data);

    return InkWell(
      onTap: () => _goToProject(doc.reference),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _hairline),
        ),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            _heroRing(progress, attention),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MOST RECENT', style: _heroEyebrowStyle),
                  const SizedBox(height: 5),
                  Text(
                    name.isEmpty ? 'Untitled project' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _heroTitleStyle,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    loc.isEmpty ? 'No location set' : loc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _tileSubtitleStyle.copyWith(fontSize: 12),
                  ),
                  if (status.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _miniPill(status, attention),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroRing(double progress, bool attention) {
    final Color arc = attention ? _orange : _ink;
    final Color track = attention ? _orangeTint : _ringTrack;
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 6,
              strokeCap: StrokeCap.round,
              backgroundColor: track,
              valueColor: AlwaysStoppedAnimation<Color>(arc),
            ),
          ),
          Text('${(progress * 100).round()}%',
              style: _ringPctStyle.copyWith(fontSize: 17)),
        ],
      ),
    );
  }

  // -----------------------------
  // Focus layout — condensed quick-list row
  // -----------------------------
  Widget _condensedRow(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final name = (data['name'] as String?)?.trim() ?? '';
    final city = (data['city'] as String?)?.trim() ?? '';
    final province = (data['province'] as String?)?.trim() ?? '';
    final status = (data['status'] as String?)?.trim() ?? '';
    final loc = [city, province].where((x) => x.isNotEmpty).join(', ');
    final attention = _needsAttention(status);
    final progress = _progress(data);

    return InkWell(
      onTap: () => _goToProject(doc.reference),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F4F7))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 11),
        child: Row(
          children: [
            _miniRing(progress, attention),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Untitled project' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _tileTitleStyle.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    loc.isEmpty ? 'No location set' : loc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _tileSubtitleStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('${(progress * 100).round()}%',
                style: _ringPctStyle.copyWith(fontSize: 13)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: Color(0xFFCDD6E2)),
          ],
        ),
      ),
    );
  }

  Widget _miniRing(double progress, bool attention) {
    final Color arc = attention ? _orange : _ink;
    final Color track = attention ? _orangeTint : _ringTrack;
    return SizedBox(
      width: 36,
      height: 36,
      child: CircularProgressIndicator(
        value: progress,
        strokeWidth: 4,
        strokeCap: StrokeCap.round,
        backgroundColor: track,
        valueColor: AlwaysStoppedAnimation<Color>(arc),
      ),
    );
  }

  Widget _miniPill(String status, bool attention) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: attention ? _orangeTint : _yellow,
          borderRadius: BorderRadius.circular(_rSmall),
        ),
        child: Text(
          _capitalize(status),
          style: TextStyle(
            fontFamily: _bodyFont,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: attention ? _orange : _paper,
          ),
        ),
      );

  // -----------------------------
  // New project button
  // -----------------------------
  Widget _newProjectButton() => InkWell(
        onTap: _goToAddProject,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFCDD6E2), width: 1.4),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, size: 18, color: Color(0xFF4B555D)),
              SizedBox(width: 8),
              Text(
                'New project',
                style: TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4B555D),
                ),
              ),
            ],
          ),
        ),
      );

  // -----------------------------
  // Signed-out (no account / not authenticated) empty state.
  // The ONLY actions here are Create account (primary) and Log in
  // (secondary). The create-project onboarding below is reserved for
  // authenticated users who simply haven't added a project yet.
  // -----------------------------
  Widget _buildSignedOut() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero tile.
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _yellow,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.lock_open_rounded, size: 32, color: _paper),
        ),
        const SizedBox(height: 20),

        // Headline.
        const Text(
          'Sign in to manage your builds',
          style: TextStyle(
            fontFamily: _displayFont,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            height: 1.08,
            color: _ink,
          ),
        ),
        const SizedBox(height: 12),

        // Promise line.
        const Text(
          'Create an account or log in to track plans, budget, '
          'programme, snags and quotes — all in one place.',
          style: TextStyle(
            fontFamily: _bodyFont,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.5,
            color: _inkMute,
          ),
        ),
        const SizedBox(height: 22),

        // Capability chips.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            _CapabilityChip('Plans'),
            _CapabilityChip('Budget'),
            _CapabilityChip('Programme'),
            _CapabilityChip('Snags'),
            _CapabilityChip('Quotes'),
            _CapabilityChip('To-do list'),
          ],
        ),
        const SizedBox(height: 28),

        // Primary — create account.
        _primaryButton(
          label: 'Create account',
          icon: Icons.person_add_alt_1_rounded,
          onTap: _goToCreateAccount,
        ),
        const SizedBox(height: 10),

        // Secondary — log in.
        _secondaryButton(
          label: 'Log in',
          icon: Icons.login_rounded,
          onTap: _goToLogin,
        ),
      ],
    );
  }

  // -----------------------------
  // Onboarding (empty state) — Option C: lean.
  // A teal hero tile, a one-line headline, a single promise sentence and a
  // row of capability chips — then Create project (primary) and Create user
  // profile (secondary, hidden once a profile exists). The persistent bottom
  // nav stays overlaid underneath (the build reserves space for it).
  // -----------------------------
  Widget _buildOnboarding() {
    final hasProfile = currentUserDisplayName.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero tile.
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _yellow,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.add_rounded, size: 34, color: _paper),
        ),
        const SizedBox(height: 20),

        // Headline.
        const Text(
          'Start your first building project',
          style: TextStyle(
            fontFamily: _displayFont,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            height: 1.08,
            color: _ink,
          ),
        ),
        const SizedBox(height: 12),

        // Single promise line.
        const Text(
          'Plans, budget, programme, snags and quotes — managed '
          'end to end, in one place.',
          style: TextStyle(
            fontFamily: _bodyFont,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.5,
            color: _inkMute,
          ),
        ),
        const SizedBox(height: 22),

        // Capability chips.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            _CapabilityChip('Plans'),
            _CapabilityChip('Budget'),
            _CapabilityChip('Programme'),
            _CapabilityChip('Snags'),
            _CapabilityChip('Quotes'),
            _CapabilityChip('To-do list'),
          ],
        ),
        const SizedBox(height: 28),

        // Primary — create project.
        _primaryButton(
          label: 'Create project',
          icon: Icons.add_rounded,
          onTap: _goToAddProject,
        ),

        // Secondary — create profile (hidden once a profile exists).
        if (!hasProfile) ...[
          const SizedBox(height: 10),
          _secondaryButton(
            label: 'Create user profile',
            icon: Icons.person_rounded,
            onTap: _goToProfile,
          ),
        ],
      ],
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_rLarge),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: _ink,
            borderRadius: BorderRadius.circular(_rLarge),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: _paper),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _paper,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _secondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_rLarge),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(_rLarge),
            border: Border.all(color: const Color(0xFFCDD6E2), width: 1.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: _ink),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ],
          ),
        ),
      );

  // -----------------------------
  // Loading
  // -----------------------------
  Widget _loadingList() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heroSkeleton(),
          const SizedBox(height: 14),
          _rowSkeleton(),
          _rowSkeleton(),
        ],
      );

  Widget _heroSkeleton() => Container(
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _hairline),
        ),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration:
                  const BoxDecoration(color: _surface, shape: BoxShape.circle),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 10, width: 80, color: _surface),
                  const SizedBox(height: 10),
                  Container(height: 16, width: 160, color: _surface),
                  const SizedBox(height: 8),
                  Container(height: 10, width: 110, color: _surface),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _rowSkeleton() => Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F4F7))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration:
                  const BoxDecoration(color: _surface, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, width: 130, color: _surface),
                  const SizedBox(height: 7),
                  Container(height: 9, width: 90, color: _surface),
                ],
              ),
            ),
          ],
        ),
      );

  // =====================================================================
  // BUILD
  // =====================================================================
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshHasListing(); // keep listing state fresh on return
    });

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: _paper,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildWelcomeHeader(),
            _buildBody(),
            // Clear the overlaid MainBottomNav (72) + breathing room (28)
            // + system gesture inset, so the last card scrolls up above the bar
            // instead of resting underneath it.
            SizedBox(height: 72 + 28 + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Capability chip — the soft teal pills in the empty state (Plans, Budget…).
// =====================================================================
class _CapabilityChip extends StatelessWidget {
  const _CapabilityChip(this.label);

  final String label;

  static const Color _tealTint = Color(0xFFE3F4F2);
  static const Color _tealText = Color(0xFF017374);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: _tealTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _tealText,
        ),
      ),
    );
  }
}

// Subby mark — bold, icon only (viewBox 0 0 64 64):
//   roof  : filled triangle, peak (32,11), base from (12.8,28.4)-(51.2,28.4).
//   bars  : two full-width rounded bars beneath, matching the roof base width.
class _SubbyMarkPainter extends CustomPainter {
  final Color peak;
  final Color base;
  const _SubbyMarkPainter({required this.peak, required this.base});

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 64.0;
    Offset p(double x, double y) => Offset(x * s, y * s);

    // New Subby mark — roof triangle above two full-width bars.
    final markPaint = Paint()
      ..color = peak
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Roof — filled triangle (base spans the same width as the bars).
    final roof = Path()
      ..moveTo(p(32, 11).dx, p(32, 11).dy) // peak
      ..lineTo(p(51.2, 28.4).dx, p(51.2, 28.4).dy) // right base
      ..lineTo(p(12.8, 28.4).dx, p(12.8, 28.4).dy) // left base
      ..close();
    canvas.drawPath(roof, markPaint);

    // Two full-width rounded bars.
    final r = Radius.circular(2.6 * s);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(p(12.8, 33.5).dx, p(12.8, 33.5).dy, 38.4 * s, 8.3 * s),
        r,
      ),
      markPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(p(12.8, 44.4).dx, p(12.8, 44.4).dy, 38.4 * s, 8.3 * s),
        r,
      ),
      markPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SubbyMarkPainter old) =>
      old.peak != peak || old.base != base;
}

// A shared project plus the project-manager (project owner) profile that
// shared it — used by the Dashboard's "Shared Building Projects" rows.
class _SharedProject {
  final DocumentReference<Map<String, dynamic>> ref;
  final Map<String, dynamic> data;
  final String pmName;
  final String pmPhotoUrl;
  const _SharedProject({
    required this.ref,
    required this.data,
    required this.pmName,
    required this.pmPhotoUrl,
  });
}
