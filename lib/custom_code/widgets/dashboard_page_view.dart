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
import 'package:flutter/services.dart'; // SystemUiOverlayStyle (reassert dark status bar on return)

import 'index.dart'; // Imports other custom widgets

import 'index.dart'; // Imports other custom widgets

import 'index.dart'; // Imports other custom widgets

// ======================= DashboardPageView (FULL FILE) =======================
//
// v6 — "Focus" home, now ROLE-AGNOSTIC.
//
// WHAT CHANGED FROM v5 (agreed in design review):
//   • "Needs you" stat number is now TEAL (was clay/orange).
//   • "Active builds" counts OWNED + SHARED builds. "On track" / "Needs you"
//     are unchanged (still derived from the owner's own active projects).
//   • Copy: "Building Projects" → "Home Builds" everywhere (My / Shared /
//     Archived), "New project" → "New home build", signed-out headline →
//     "Sign in to manage your home builds".
//   • PROJECT FEED signals on the cards: the hero shows a one-line "last
//     activity" (bolt + summary · relative time); each condensed row shows a
//     teal unread dot + the same summary when the build has recent activity.
//     Reads two OPTIONAL project-doc fields written by the Project Feed:
//        lastActivity   : String     — e.g. "Snag added", "Timeline updated"
//        lastActivityAt : Timestamp  — drives the relative time ("2h ago")
//     Missing ⇒ no activity line (safe).
//   • ROLE-AGNOSTIC empty handling. The screen no longer assumes the viewer is
//     an owner:
//        - Owned builds exist            → owner layout (My Home Builds) as before.
//        - No owned builds, shared exist → SHARED-PRIMARY layout: the builds
//          they were added to (e.g. an electrician) become the main list.
//        - No owned, no shared           → ONE unified empty state ("Your home
//          builds live here") with a primary "Start a home build" AND a
//          Directory card. The Directory card is listing-aware:
//             • no listing  → "Create a listing in the Directory…" (→ add listing)
//             • has listing → "You're listed in the Directory…"   (→ edit listing)
//     Role is implicit (owner of builds you create, collaborator on builds you
//     were added to) — no stored user role / signup question required.
//
// PRESERVED: every constructor param (used + legacy), _safeNavigate /
// _goToProject / _goToAddProject, the active-projects query, the archived
// query, the shared-projects resolver, the listing-exists check, route
// fallbacks, and date formatting.
//
// PROJECT DOC FIELDS READ (all optional, safe fallbacks):
//   name, city, province, status, updatedAt        (as before)
//   progress       : num — 0..1 OR 0..100, drives the bar. Missing ⇒ 0%.
//   lastActivity   : String     — feed summary (NEW).
//   lastActivityAt : Timestamp  — feed time    (NEW).

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

    /// Listing management routes — USED by the Directory card in the empty state
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

  // USED for the Directory listing card (empty state)
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
  static const Color _ink =
      Color(0xFF28333E); // text, chrome, dark surfaces (slate)
  static const Color _inkMute = Color(0xFF5A6675);
  static const Color _faint = Color(0xFF93A0B0); // muted labels, chevrons
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFEEF1F4);
  static const Color _hairline = Color(0xFFEEF1F2);

  // Accents
  static const Color _yellow = Color(0xFFB1C984); // sage — "on site" / on track
  static const Color _teal = Color(0xFF319DA3); // info / shared / "needs you"
  static const Color _ringTrack = Color(0xFFEEF2F7);
  static const Color _orange = Color(0xFFAB6455); // attention / snagging (clay)
  static const Color _orangeTint = Color(0xFFF3E7E2);
  static const Color _orangeBorder = Color(0xFFE8CFC7);
  static const Color _orangeText = Color(0xFFAB6455);
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

  // Listing exists (drives the Directory card in the empty state, + Directory nav)
  bool _hasListing = false;
  bool _listingCheckInFlight = false;
  int _lastListingCheckMs = 0;

  // Shared-build count — keeps the "Active builds" stat (owned + shared) in
  // sync once the async shared loader resolves.
  int _sharedCount = 0;

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

  // "2h ago" / "3d ago" — for the Project Feed activity lines.
  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final w = (diff.inDays / 7).floor();
    return '${w}w ago';
  }

  // Builds the feed activity line for a project, or null when there's nothing
  // recent. Reads lastActivity (summary) + lastActivityAt (time).
  String? _activityFor(Map<String, dynamic> data) {
    final s = (data['lastActivity'] as String?)?.trim() ?? '';
    if (s.isEmpty) return null;
    final ts = data['lastActivityAt'];
    DateTime? dt;
    if (ts is Timestamp) {
      dt = ts.toDate();
    } else if (ts is DateTime) {
      dt = ts;
    }
    return dt != null ? '$s · ${_relativeTime(dt)}' : s;
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

  // Activity line — on the sage hero (ink) vs on a condensed row (teal).
  TextStyle get _heroActivityStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _ink,
      );

  TextStyle get _rowActivityStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _teal,
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
  void _goToMore() => _openMore();

  void _openMore() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MorePageView()),
    );
  }

  // The Directory card's add-vs-edit decision (empty state). A user must create
  // a listing before a project manager can add them to a build.
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

  // Archived projects (archived == true).
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
  // Listing exists for current user (debounced + only setState on change).
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
          Expanded(child: Text('My Home Builds', style: _stepHeadlineStyle)),
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
  // BODY — owner layout · shared-primary · or unified empty (role-agnostic)
  // =====================================================================
  Widget _buildBody() {
    final q = _activeProjectsQuery();

    if (q == null) {
      // No authenticated user → Create account / Log in.
      return Padding(
        padding: const EdgeInsets.fromLTRB(_hPad, 18, _hPad, 0),
        child: _buildSignedOut(),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          // Can't read owned projects → fall through to the role-agnostic path.
          return _buildNoOwnedProjects();
        }

        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return _bodyShell(child: _loadingList());
        }

        final docs = snap.data?.docs ?? const [];

        // No owned builds → decide between shared-primary and the empty state.
        if (docs.isEmpty) {
          return _buildNoOwnedProjects();
        }

        // ── OWNER layout ───────────────────────────────────────────────
        // Stats: "Active builds" = owned + shared; "On track" / "Needs you"
        // stay derived from the owner's own active projects (unchanged).
        final ownedActive = docs.length;
        int needs = 0;
        for (final d in docs) {
          final s = (d.data()['status'] as String?)?.trim() ?? '';
          if (_needsAttention(s)) needs++;
        }
        final onTrack = ownedActive - needs;
        final displayedActive = ownedActive + _sharedCount;

        // Focus layout: most-recent (updatedAt desc) is the hero; the rest are
        // condensed quick-list rows.
        final feat = docs.first;
        final rest = docs.skip(1).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(_hPad, 18, _hPad, 0),
              child: _statStrip(displayedActive, onTrack, needs),
            ),
            const SizedBox(height: 28),
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

            // Shared with me — read-only projects (also keeps _sharedCount fresh).
            _buildSharedSection(),

            // Archived Building Projects.
            _buildArchivedSection(),
          ],
        );
      },
    );
  }

  // No owned builds: show the shared builds as the primary list if any exist,
  // otherwise the unified (role-agnostic) empty state.
  Widget _buildNoOwnedProjects() {
    if (currentUserReference == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(_hPad, 18, _hPad, 0),
        child: _buildSignedOut(),
      );
    }
    return FutureBuilder<List<_SharedProject>>(
      future: _loadSharedProjects(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return _bodyShell(child: _loadingList());
        }
        final shared = (snap.data ?? const <_SharedProject>[]).toList();

        // keep the count in sync (used elsewhere if owned arrives later)
        if (_sharedCount != shared.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _sharedCount = shared.length);
          });
        }

        if (shared.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(_hPad, 18, _hPad, 0),
            child: _buildEmptyState(),
          );
        }
        return _buildSharedPrimary(shared);
      },
    );
  }

  // -----------------------------
  // SHARED-PRIMARY layout — for users (e.g. a tradesperson) whose builds are
  // all builds they were ADDED to. The shared list becomes the main content.
  // -----------------------------
  Widget _buildSharedPrimary(List<_SharedProject> shared) {
    // Most-recent first.
    shared.sort((a, b) {
      final ad = _updatedAt(a.data);
      final bd = _updatedAt(b.data);
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });

    final active = shared.length;
    int needs = 0;
    for (final sp in shared) {
      final s = (sp.data['status'] as String?)?.trim() ?? '';
      if (_needsAttention(s)) needs++;
    }
    final onTrack = active - needs;

    final feat = shared.first;
    final rest = shared.skip(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(_hPad, 18, _hPad, 0),
          child: _statStrip(active, onTrack, needs, activeLabel: 'On builds'),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _hPad),
          child: _sharedSectionHeader(),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _hPad),
          child: Text(
            "Builds you've been added to.",
            style: _tileSubtitleStyle.copyWith(fontSize: 12),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _hPad),
          child: _sharedHeroCard(feat),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _hPad),
          child: Column(
            children: [
              for (final sp in rest) _sharedPrimaryRow(sp),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Building your own home?',
                  style: TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _faint,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _secondaryButton(
                label: 'Start your own build',
                icon: Icons.add_rounded,
                onTap: _goToAddProject,
              ),
            ],
          ),
        ),
      ],
    );
  }

  DateTime? _updatedAt(Map<String, dynamic> data) {
    final v = data['updatedAt'];
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  Widget _sharedHeroCard(_SharedProject sp) {
    final data = sp.data;
    final name = (data['name'] as String?)?.trim() ?? '';
    final city = (data['city'] as String?)?.trim() ?? '';
    final province = (data['province'] as String?)?.trim() ?? '';
    final status = (data['status'] as String?)?.trim() ?? '';
    final loc = [city, province].where((x) => x.isNotEmpty).join(', ');
    final pm = sp.pmName.trim();
    final progress = _progress(data);
    final pct = (progress * 100).round();
    final act = _activityFor(data);

    return InkWell(
      onTap: () => _goToProject(sp.ref),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: _yellow,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SHARED WITH YOU',
                style: TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: _ink,
                )),
            const SizedBox(height: 6),
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
              style: const TextStyle(
                fontFamily: _bodyFont,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _inkMute,
              ),
            ),
            if (pm.isNotEmpty) ...[
              const SizedBox(height: 7),
              Row(
                children: [
                  const Icon(Icons.ios_share_rounded, size: 13, color: _teal),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Shared by $pm',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _inkMute,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (status.isNotEmpty) ...[
              const SizedBox(height: 11),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _ink,
                  borderRadius: BorderRadius.circular(_rSmall),
                ),
                child: Text(
                  _capitalize(status),
                  style: const TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _paper,
                  ),
                ),
              ),
            ],
            if (act != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.bolt, size: 15, color: _ink),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(act,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _heroActivityStyle),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      height: 8,
                      color: _paper,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(color: _ink),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('$pct%', style: _ringPctStyle.copyWith(fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sharedPrimaryRow(_SharedProject sp) {
    final data = sp.data;
    final name = (data['name'] as String?)?.trim() ?? '';
    final city = (data['city'] as String?)?.trim() ?? '';
    final province = (data['province'] as String?)?.trim() ?? '';
    final pm = sp.pmName.trim();
    final loc = [city, province].where((x) => x.isNotEmpty).join(', ');
    final sub = [loc, pm].where((x) => x.isNotEmpty).join(' · ');
    final progress = _progress(data);
    final pct = (progress * 100).round();
    final act = _activityFor(data);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _goToProject(sp.ref),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _hairline),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
                          sub.isEmpty ? 'Shared with you' : sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _tileSubtitleStyle,
                        ),
                        if (act != null) ...[
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                    color: _teal, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(act,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _rowActivityStyle),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded,
                      size: 20, color: Color(0xFFCDD6E2)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        height: 7,
                        color: _paper,
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(color: _ink),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('$pct%', style: _ringPctStyle.copyWith(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
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

        // Keep the "Active builds" stat (owned + shared) in sync.
        if (_sharedCount != docs.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _sharedCount = docs.length);
          });
        }

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
                "Added to the Project Team.",
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
          _accentMarker(_teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Shared Home Builds', style: _stepHeadlineStyle),
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
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E7EE)),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: _surface,
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
                          size: 13, color: _teal),
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
              'Archived Home Builds',
              style: _stepHeadlineStyle.copyWith(color: _inkMute),
            ),
          ),
        ],
      );

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
  Widget _statStrip(int active, int onTrack, int needs,
          {String activeLabel = 'Active builds'}) =>
      Row(
        children: [
          Expanded(child: _statTile('$active', activeLabel, dark: true)),
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
    final Color bg = dark ? _ink : (attention ? _surface : _yellow);
    // "Needs you" number is TEAL (was clay/orange).
    final Color numColor = dark ? _paper : (attention ? _teal : _ink);
    final Color labelColor =
        dark ? Colors.white.withOpacity(0.7) : (attention ? _inkMute : _ink);

    return Container(
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(11),
        border: attention ? Border.all(color: const Color(0xFFE2E7EE)) : null,
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
  // Focus layout — hero card (most recent owned project)
  // -----------------------------
  Widget _heroCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final name = (data['name'] as String?)?.trim() ?? '';
    final city = (data['city'] as String?)?.trim() ?? '';
    final province = (data['province'] as String?)?.trim() ?? '';
    final status = (data['status'] as String?)?.trim() ?? '';
    final loc = [city, province].where((x) => x.isNotEmpty).join(', ');
    final progress = _progress(data);
    final pct = (progress * 100).round();
    final act = _activityFor(data);

    return InkWell(
      onTap: () => _goToProject(doc.reference),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          // MOST RECENT card — sage-TINT to match the ProjectDetail "Manage"
          // module tiles (was solid _yellow).
          color: const Color(0xFFEDF2DE),
          border: Border.all(color: const Color(0xFFDCE9B0)),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('MOST RECENT',
                style: TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: _ink,
                )),
            const SizedBox(height: 6),
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
              style: const TextStyle(
                fontFamily: _bodyFont,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _inkMute,
              ),
            ),
            if (status.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _ink,
                  borderRadius: BorderRadius.circular(_rSmall),
                ),
                child: Text(
                  _capitalize(status),
                  style: const TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _paper,
                  ),
                ),
              ),
            ],
            if (act != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.bolt, size: 15, color: _ink),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(act,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _heroActivityStyle),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      height: 8,
                      color: _paper,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(color: _ink),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('$pct%', style: _ringPctStyle.copyWith(fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
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
  // Focus layout — condensed quick-list row (owned)
  // -----------------------------
  Widget _condensedRow(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final name = (data['name'] as String?)?.trim() ?? '';
    final city = (data['city'] as String?)?.trim() ?? '';
    final province = (data['province'] as String?)?.trim() ?? '';
    final loc = [city, province].where((x) => x.isNotEmpty).join(', ');
    final progress = _progress(data);
    final pct = (progress * 100).round();
    final act = _activityFor(data);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _goToProject(doc.reference),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _hairline),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
                        if (act != null) ...[
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                    color: _teal, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(act,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _rowActivityStyle),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded,
                      size: 20, color: Color(0xFFCDD6E2)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        height: 7,
                        color: _paper,
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(color: _ink),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('$pct%', style: _ringPctStyle.copyWith(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
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
  // New build button
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
                'New home build',
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
  // Signed-out (not authenticated) empty state.
  // -----------------------------
  Widget _buildSignedOut() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        const Text(
          'Sign in to manage your home builds',
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
        const SizedBox(height: 28),
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
        _primaryButton(
          label: 'Create account',
          icon: Icons.person_add_alt_1_rounded,
          onTap: _goToCreateAccount,
        ),
        const SizedBox(height: 10),
        _secondaryButton(
          label: 'Log in',
          icon: Icons.login_rounded,
          onTap: _goToLogin,
        ),
      ],
    );
  }

  // -----------------------------
  // Unified, ROLE-AGNOSTIC empty state (no owned builds, no shared builds).
  // Serves both a would-be owner and a tradesperson waiting to be added:
  //   • Primary "Start a home build" (owner path).
  //   • Directory card (listing-aware): a tradesperson must list themselves in
  //     the Directory before a PM can add them to a build.
  // -----------------------------
  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _yellow,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.construction, size: 32, color: _paper),
        ),
        const SizedBox(height: 20),
        const Text(
          'Your home builds live here',
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
        const Text(
          "Start your own home build below — or join a build you're "
          'working on for someone else.',
          style: TextStyle(
            fontFamily: _bodyFont,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.5,
            color: _inkMute,
          ),
        ),
        const SizedBox(height: 28),
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
        _primaryButton(
          label: 'Start a home build',
          icon: Icons.add_rounded,
          onTap: _goToAddProject,
        ),
        const SizedBox(height: 14),
        _orDivider(),
        const SizedBox(height: 14),
        _directoryListingCard(),
      ],
    );
  }

  Widget _orDivider() => Row(
        children: [
          const Expanded(child: Divider(color: _hairline, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'OR',
              style: TextStyle(
                fontFamily: _bodyFont,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _faint,
              ),
            ),
          ),
          const Expanded(child: Divider(color: _hairline, height: 1)),
        ],
      );

  // Listing-aware Directory card. A tradesperson lists themselves so PMs can
  // find and add them; once listed, this reassures instead of re-prompting.
  Widget _directoryListingCard() {
    final IconData icon = _hasListing ? Icons.verified : Icons.storefront;
    final String title = _hasListing
        ? "You're listed in the Directory"
        : 'Working on builds for others?';
    final String body = _hasListing
        ? "Project managers can find and add you. Builds you're added to "
            'appear here automatically.'
        : 'Create a listing in the Directory so project managers can find and '
            'add you to their builds.';

    return InkWell(
      onTap: _goToListing,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E7EE)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _paper,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: _teal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: _bodyFont,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: const TextStyle(
                      fontFamily: _bodyFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: _inkMute,
                    ),
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Dark (black) status-bar icons over the white dashboard. Because the
      // visible route's AnnotatedRegion wins, this reasserts dark icons the
      // moment ProjectDetailPageView (which forces light) is popped.
      value: SystemUiOverlayStyle.dark,
      child: Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? double.infinity,
        color: _paper,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildWelcomeHeader(),
              _buildBody(),
              // Clear the overlaid MainBottomNav (72) + breathing room (28)
              // + system gesture inset.
              SizedBox(height: 72 + 28 + MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// Capability chip — the soft pills in the empty states (Plans, Budget…).
// =====================================================================
class _CapabilityChip extends StatelessWidget {
  const _CapabilityChip(this.label);

  final String label;

  static const Color _tealTint = Color(0xFFEDF2DE);
  static const Color _tealText = Color(0xFF28333E);

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

    final markPaint = Paint()
      ..color = peak
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Roof — filled triangle.
    final roof = Path()
      ..moveTo(p(32, 11).dx, p(32, 11).dy)
      ..lineTo(p(51.2, 28.4).dx, p(51.2, 28.4).dy)
      ..lineTo(p(12.8, 28.4).dx, p(12.8, 28.4).dy)
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
// shared it — used by the Dashboard's "Shared Home Builds" rows.
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
