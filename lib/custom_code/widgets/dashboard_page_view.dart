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

import 'package:flutter/services.dart'; // SystemUiOverlayStyle (reassert dark status bar on return)

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
import 'package:shared_preferences/shared_preferences.dart';

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
    this.snagDetailRouteName, // deep-link a single snag from the feed
    this.taskDetailRouteName, // deep-link a single task from the feed

    /// Quote invites (trade side) — tapping a pending invite opens
    /// QuoteRequestView. Listing owners see invites here BEFORE they have
    /// project access.
    this.quoteRequestRouteName,

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
  final String? snagDetailRouteName;
  final String? taskDetailRouteName;
  final String? quoteRequestRouteName;

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
      Color(0xFF29343A); // text, chrome, dark surfaces (slate)
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC); // muted labels, chevrons
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _hairline = Color(0xFFEAEEF0);
  static const Color _heroBg = Color(0xFF455861); // welcome header background

  // Accents
  static const Color _yellow = Color(0xFF5D737E); // sage — "on site" / on track
  static const Color _teal = Color(0xFF5D737E); // info / shared / "needs you"
  static const Color _ringTrack = Color(0xFFECF0F2);
  static const Color _orange = Color(0xFF566670); // attention / snagging (clay)
  static const Color _orangeTint = Color(0xFFE7EDF0);
  static const Color _orangeBorder = Color(0xFFCBD8DD);
  static const Color _orangeText = Color(0xFF566670);
  static const Color _projTint = Color(0xFFECF0F2); // add / empty card fill

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
  static const String _fallbackQuoteRequestRoute = 'QuoteRequest';
  static const String _kActiveQuotePath = 'subby_active_quote_path';

  // Listing exists (drives the Directory card in the empty state, + Directory nav)
  bool _hasListing = false;
  bool _listingCheckInFlight = false;
  int _lastListingCheckMs = 0;

  // Shared-build count — keeps the "Active builds" stat (owned + shared) in
  // sync once the async shared loader resolves.
  int _sharedCount = 0;
  bool _archivedExpanded = false;

  // ─── CACHED STREAMS / FUTURES ──────────────────────────────────────
  // These are created ONCE and reused across rebuilds. Previously each of
  // these was built inline in the widget tree (e.g. `.snapshots()` directly
  // in a StreamBuilder's `stream:`), so every rebuild produced a NEW
  // Stream/Future instance. StreamBuilder/FutureBuilder treat a new instance
  // as a fresh subscription: they reset to ConnectionState.waiting with null
  // data, so the section blanks out for a frame — the "flicker then it
  // disappears" behaviour — and (combined with the post-frame setState calls
  // in build) could keep re-resetting so the content never settled. Caching
  // hands the SAME instance back each build, so the sections stay stable.
  Stream<QuerySnapshot<Map<String, dynamic>>>? _quoteInvitesStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _activeProjectsStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _archivedProjectsStream;
  Future<List<_SharedProject>>? _sharedProjectsFuture;
  // Guards a rebuild if the signed-in user changes (login/logout) — the cached
  // streams above are keyed to whoever was signed in when they were created.
  DocumentReference? _cachedForUser;

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
        fontSize: 22,
        fontWeight: FontWeight.w900,
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
        color: _yellow,
      );

  TextStyle get _rowActivityStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _yellow,
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
  // Cached stream / future accessors (see the CACHED STREAMS block above for
  // why these exist). Each builds its underlying query/future only once and
  // returns the same instance on every rebuild. If the signed-in user changes,
  // the caches are dropped so the new user's data loads.
  // -----------------------------
  void _resetCachesIfUserChanged() {
    final me = currentUserReference;
    if (me?.path != _cachedForUser?.path) {
      _cachedForUser = me;
      _quoteInvitesStream = null;
      _activeProjectsStream = null;
      _archivedProjectsStream = null;
      _sharedProjectsFuture = null;
      _sharedCount = 0;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>? _quoteInvitesStreamCached(
      DocumentReference me) {
    return _quoteInvitesStream ??= FirebaseFirestore.instance
        .collectionGroup('quotes')
        .where('providerRef', isEqualTo: me)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>? _activeProjectsStreamCached() {
    if (_activeProjectsStream != null) return _activeProjectsStream;
    final q = _activeProjectsQuery();
    if (q == null) return null;
    return _activeProjectsStream = q.snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>? _archivedProjectsStreamCached() {
    if (_archivedProjectsStream != null) return _archivedProjectsStream;
    final q = _archivedProjectsQuery();
    if (q == null) return null;
    return _archivedProjectsStream = q.snapshots();
  }

  Future<List<_SharedProject>> _sharedProjectsFutureCached() {
    return _sharedProjectsFuture ??= _loadSharedProjects();
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

  // Activity-line attention — a snag/attention feed summary paints the card's
  // activity line clay (attention) instead of the default green; routine
  // updates (timeline, quotes, docs…) stay green.
  bool _activityNeedsAttention(Map<String, dynamic> data) {
    final s = (data['lastActivity'] as String?)?.trim().toLowerCase() ?? '';
    return s.contains('snag') ||
        s.contains('attention') ||
        s.contains('overdue') ||
        s.contains('block') ||
        s.contains('delay');
  }

  Color _activityColor(Map<String, dynamic> data) =>
      _activityNeedsAttention(data) ? _orange : _yellow;

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
  // QUOTE INVITES (trade side) — invites this user received across ALL
  // projects via collectionGroup('quotes') on providerRef. Shown so a listing
  // owner can respond BEFORE they are granted access to the project. Only
  // pending states (invited / viewed / submitted) surface here; renders
  // nothing when there are none.
  // =====================================================================
  Future<void> _openQuoteInvite(DocumentReference quoteRef) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kActiveQuotePath, quoteRef.path);
    if (!mounted) return;
    _safeNavigate(widget.quoteRequestRouteName,
        fallbackRoute: _fallbackQuoteRequestRoute);
  }

  Widget _buildQuoteInvites() {
    final me = currentUserReference;
    if (me == null) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _quoteInvitesStreamCached(me),
      builder: (context, snap) {
        // Surface the failure instead of hiding it. The usual cause is a
        // missing COLLECTION_GROUP index on quotes.providerRef (see
        // firestore.indexes.json) or the collection-group security rule —
        // without either, this query throws and the whole section silently
        // vanished, which is exactly the "invites don't show" symptom.
        if (snap.hasError) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: _hPad, vertical: 16),
            child: Text(
                'Couldn\'t load quote invites. Check the collection-group rule and the providerRef index on "quotes".',
                style: _tileSubtitleStyle),
          );
        }
        final all = snap.data?.docs ?? [];
        const pending = ['invited', 'viewed', 'quoting', 'submitted'];
        final docs = all
            .where((d) =>
                pending.contains((d.data()['status'] ?? 'invited').toString()))
            .toList();
        if (docs.isEmpty) return const SizedBox.shrink();
        // Newest-action first: invited, then viewed, then submitted.
        int rank(String s) =>
            s == 'invited' ? 0 : (s == 'viewed' ? 1 : (s == 'quoting' ? 2 : 3));
        docs.sort((a, b) => rank((a.data()['status'] ?? 'invited').toString())
            .compareTo(rank((b.data()['status'] ?? 'invited').toString())));
        final actionable = docs
            .where((d) => ['invited', 'viewed', 'quoting']
                .contains((d.data()['status'] ?? '').toString()))
            .length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _hPad),
              child: Row(children: [
                _accentMarker(_teal),
                const SizedBox(width: 10),
                Expanded(
                    child: Text('Quote invites', style: _stepHeadlineStyle)),
                if (actionable > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                        color: const Color(0xFFE7E247),
                        borderRadius: BorderRadius.circular(_rPill)),
                    child: Text('$actionable new',
                        style: const TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _ink)),
                  ),
              ]),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _hPad),
              child: Text(
                  'Projects that invited you to quote. Open one to view the drawings and respond — no project access needed.',
                  style: _tileSubtitleStyle),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _hPad),
              child:
                  Column(children: [for (final d in docs) _quoteInviteRow(d)]),
            ),
          ],
        );
      },
    );
  }

  Widget _quoteInviteRow(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final status = (d['status'] ?? 'invited').toString();
    final projectRef = doc.reference.parent.parent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_rLarge),
        child: InkWell(
          onTap: () => _openQuoteInvite(doc.reference),
          borderRadius: BorderRadius.circular(_rLarge),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: _paper,
                borderRadius: BorderRadius.circular(_rLarge),
                border: Border.all(color: _hairline)),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(_rLarge)),
                child: const Icon(Icons.request_quote_outlined,
                    size: 22, color: _ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: projectRef?.get(),
                  builder: (context, ps) {
                    final pd = ps.data?.data() ?? const <String, dynamic>{};
                    final pname = (pd['name'] ??
                            pd['projectName'] ??
                            pd['title'] ??
                            'Project')
                        .toString();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _tileTitleStyle),
                        const SizedBox(height: 3),
                        Text(_inviteStatusText(status),
                            style: _tileSubtitleStyle),
                      ],
                    );
                  },
                ),
              ),
              _inviteStatusPill(status),
            ]),
          ),
        ),
      ),
    );
  }

  String _inviteStatusText(String s) {
    switch (s) {
      case 'viewed':
        return 'Viewed · continue your quote';
      case 'quoting':
        return 'Accepted · continue your quote';
      case 'submitted':
        return 'Quote submitted · awaiting decision';
      default:
        return 'New request · tap to view';
    }
  }

  Widget _inviteStatusPill(String status) {
    Color fg = _faint, bg = _surface;
    String label = 'Invited';
    if (status == 'viewed') {
      fg = _teal;
      bg = _orangeTint;
      label = 'Viewed';
    } else if (status == 'quoting') {
      fg = _teal;
      bg = _orangeTint;
      label = 'Accepted';
    } else if (status == 'submitted') {
      fg = _teal;
      bg = _orangeTint;
      label = 'Submitted';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(_rPill)),
      child: Text(label,
          style: TextStyle(
              fontFamily: _bodyFont,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: fg)),
    );
  }

  // =====================================================================
  // WELCOME — big & minimal
  // =====================================================================
  Widget _buildWelcomeHeader() {
    final topInset = MediaQuery.of(context).padding.top;
    final name = currentUserDisplayName.trim();
    final hasName = name.isNotEmpty;
    final firstName = hasName ? name.split(RegExp(r'\s+')).first : '';
    final now = DateTime.now();

    return Column(
      children: [
        Container(height: topInset, color: _heroBg),
        Container(
          width: double.infinity,
          color: _heroBg,
          padding: const EdgeInsets.fromLTRB(_hPad, 14, _hPad, 24),
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
              Text(_eyebrowDate(now),
                  style:
                      _eyebrowStyle.copyWith(color: _paper.withOpacity(0.55))),
              const SizedBox(height: 6),
              Text(
                hasName ? '${_greeting()},\n$firstName' : _greeting(),
                style: _greetingStyle.copyWith(color: _paper),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Icon-only mark — bold, no wordmark.
  // Loads the green Subby house PNG from FlutterFlow asset storage; falls back to
  // the painted _SubbyMarkPainter if the network image fails (offline / cold
  // start) so the logo never renders blank.
  static const String _logoUrl =
      'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/winston-9dy48u/assets/vkvx0d5tvzte/subby_logo_white.png';

  // Non-square mark: anchor on height (36) and leave width unconstrained so
  // the image renders at its natural aspect ratio rather than being squeezed
  // into a square box. The 36px height keeps the header's vertical rhythm.
  Widget _logo() => SizedBox(
        height: 36,
        child: Image.network(
          _logoUrl,
          height: 36,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => CustomPaint(
            size: const Size(36, 36),
            painter: const _SubbyMarkPainter(
              peak: Color(0xFF5D737E), // Subby brand green
              base: Color(0xFF5D737E),
            ),
          ),
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
    final stream = _activeProjectsStreamCached();

    if (stream == null) {
      // No authenticated user → Create account / Log in.
      return Padding(
        padding: const EdgeInsets.fromLTRB(_hPad, 18, _hPad, 0),
        child: _buildSignedOut(),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 22),
            // Unified build grid: owned builds (the most-recent one rendered
            // as a FULL-GREEN featured tile), followed by SHARED builds (no
            // separate heading — each carries a share marker), and a trailing
            // "New home build" add tile that matches the project-tile size.
            // Shared loads async, so the grid is wrapped in a FutureBuilder
            // and rebuilds (also keeping _sharedCount fresh) once it resolves.
            FutureBuilder<List<_SharedProject>>(
              future: _sharedProjectsFutureCached(),
              builder: (context, sharedSnap) {
                final rawShared = sharedSnap.data ?? const <_SharedProject>[];
                // De-dupe: a build the viewer OWNS can also come back as a
                // shared build (they have a listing added to their own build).
                // Drop those so each project renders exactly one tile.
                final ownedPaths = docs.map((d) => d.reference.path).toSet();
                final shared = rawShared
                    .where((sp) => !ownedPaths.contains(sp.ref.path))
                    .toList();
                if (_sharedCount != shared.length) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _sharedCount = shared.length);
                  });
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 14),
                      child: Row(
                        children: [
                          _accentMarker(_ink),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('Home Build Projects',
                                style: _stepHeadlineStyle),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: _hPad),
                      child: _buildsGrid(docs, shared),
                    ),
                    // Projects Feed — real activity log, grouped by day,
                    // scoped to owned + shared builds.
                    _buildActivityFeed(docs, shared),
                  ],
                );
              },
            ),
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
      future: _sharedProjectsFutureCached(),
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
          // Empty state — but archived builds remain visible if any exist.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(_hPad, 18, _hPad, 0),
                child: _buildEmptyState(),
              ),
            ],
          );
        }
        // Shared-primary layout — also keep the archived section below it.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSharedPrimary(shared),
          ],
        );
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

    final feat = shared.first;
    final rest = shared.skip(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
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
          // SHARED hero — tint surface (matches the tint project tiles).
          color: const Color(0xFFF4F2D2),
          border: Border.all(color: const Color(0xFFF4F2D2)),
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
                color: _ink,
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
                        color: _ink,
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
                  Icon(Icons.bolt, size: 15, color: _activityColor(data)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(act,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _heroActivityStyle.copyWith(
                            color: _activityColor(data))),
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
            // SHARED primary row — muted yellow (matches owner tint tiles).
            color: const Color(0xFFF4F2D2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF4F2D2)),
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
                          style: _tileSubtitleStyle.copyWith(color: _ink),
                        ),
                        if (act != null) ...[
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                    color: _activityColor(data),
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(act,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _rowActivityStyle.copyWith(
                                        color: _activityColor(data))),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded,
                      size: 20, color: _ink),
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
  // Archived builds — collapsed by default, pinned to the bottom. Reuses the
  // archived query + _archivedRow. Renders nothing (no toggle) when empty.
  Widget _buildArchivedCollapsible() {
    final stream = _archivedProjectsStreamCached();
    if (stream == null) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        final docs = snap.data?.docs ?? const [];
        if (docs.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _hPad),
              child: InkWell(
                onTap: () =>
                    setState(() => _archivedExpanded = !_archivedExpanded),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      _accentMarker(_faint),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('Archived Home Builds',
                            style: _stepHeadlineStyle),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: _hairline,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('${docs.length}',
                            style: const TextStyle(
                              fontFamily: _bodyFont,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: _inkMute,
                            )),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _archivedExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 22,
                        color: _faint,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_archivedExpanded) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: Column(
                  children: [for (final d in docs) _archivedRow(d)],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // ignore: unused_element
  Widget _buildArchivedSection() {
    final stream = _archivedProjectsStreamCached();
    if (stream == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
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

  // RETAINED — shared builds now render inline in the main grid (no separate
  // heading); this standalone section is kept for reference.
  // ignore: unused_element
  Widget _buildSharedSection() {
    if (currentUserReference == null) return const SizedBox.shrink();
    return FutureBuilder<List<_SharedProject>>(
      future: _sharedProjectsFutureCached(),
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
          border: Border.all(color: const Color(0xFFDCE3E6)),
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
                size: 20, color: Color(0xFFCBD8DD)),
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
                size: 20, color: Color(0xFFCBD8DD)),
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
    // Active builds → ORANGE fill (white text, soft shadow).
    // On track     → YELLOW fill (white text).
    // Needs you    → surface fill, teal (amber) number.
    final Color bg = dark ? _yellow : (attention ? _surface : _teal);
    final Color numColor = attention ? const Color(0xFF566670) : _paper;
    final Color labelColor =
        attention ? _inkMute : Colors.white.withOpacity(0.85);

    return Container(
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(11),
        border: attention ? Border.all(color: const Color(0xFFDCE3E6)) : null,
        boxShadow: null,
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
              fontWeight: FontWeight.w700,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // SAGE GRID — builds rendered as 2-up percentage-lead tiles.
  // ===================================================================
  Widget _buildsGrid(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    List<_SharedProject> shared,
  ) {
    // One tile per build: owned first (index 0 = featured FULL-GREEN tile),
    // then shared builds (share marker, no heading), then the add tile.
    final tiles = <Widget>[];
    for (int i = 0; i < docs.length; i++) {
      tiles.add(
          _buildGridTile(docs[i].data(), docs[i].reference, featured: i == 0));
    }
    for (final sp in shared) {
      tiles.add(_buildGridTile(sp.data, sp.ref, sharedBy: sp.pmName.trim()));
    }
    tiles.add(_addTile());

    final children = <Widget>[];
    for (int i = 0; i < tiles.length; i++) {
      children.add(tiles[i]);
      if (i != tiles.length - 1) children.add(const SizedBox(height: 12));
    }
    return Column(children: children);
  }

  // A single build tile. `featured` paints it as a full-green fill (white
  // text) — used for the most-recent owned build. `sharedBy` (non-null) marks
  // it as a shared build: it shows a share glyph and a "Shared by …" subtitle.
  Widget _buildGridTile(
    Map<String, dynamic> data,
    DocumentReference ref, {
    bool featured = false,
    String? sharedBy,
  }) {
    final bool shared = sharedBy != null;
    final name = (data['name'] as String?)?.trim() ?? '';
    final city = (data['city'] as String?)?.trim() ?? '';
    final province = (data['province'] as String?)?.trim() ?? '';
    final loc = [city, province].where((x) => x.isNotEmpty).join(', ');
    final progress = _progress(data);
    final pct = (progress * 100).round();

    // Slate featured tile (white text) + tint tiles (ink text).
    final Color bg =
        featured ? const Color(0xFFE7E247) : const Color(0xFFF4F2D2);
    final Color border =
        featured ? const Color(0xFFE7E247) : const Color(0xFFF4F2D2);
    final Color numColor = _ink;
    final Color subColor = featured ? _inkMute : _ink;

    final String sub = shared
        ? (sharedBy!.isNotEmpty ? 'Shared by $sharedBy' : 'Shared with you')
        : (loc.isEmpty ? 'No location set' : loc);

    return InkWell(
      onTap: () => _goToProject(ref),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 84,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            Text('$pct%',
                style: TextStyle(
                  fontFamily: _displayFont,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  color: numColor,
                )),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name.isEmpty ? 'Untitled' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: _displayFont,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: numColor,
                      )),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (shared) ...[
                        Icon(Icons.ios_share_rounded,
                            size: 13, color: subColor),
                        const SizedBox(width: 5),
                      ],
                      Flexible(
                        child: Text(sub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: _bodyFont,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: subColor,
                            )),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right_rounded,
                size: 22, color: featured ? _inkMute : _faint),
          ],
        ),
      ),
    );
  }

  // "New home build" add tile — same size/shape as a project tile, neutral
  // surface fill with a centred add affordance.
  Widget _addTile() => InkWell(
        onTap: _goToAddProject,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 84,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F2D2),
            border: Border.all(color: const Color(0xFFF4F2D2), width: 1.4),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, size: 26, color: Color(0xFF55656E)),
              SizedBox(width: 10),
              Text('New home build',
                  style: TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF55656E),
                  )),
            ],
          ),
        ),
      );

  // ===================================================================
  // PROJECTS FEED — aggregated activity across all builds (rail).
  // ===================================================================
  // ignore: unused_element
  Widget _buildDashboardFeed(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final items = <Widget>[];
    for (final d in docs) {
      final data = d.data();
      final act = _activityFor(data); // "summary · 2h ago" or null
      if (act == null) continue;
      final name = (data['name'] as String?)?.trim() ?? 'Untitled';
      items.add(_dashFeedRow(name, act));
    }
    if (items.isEmpty) return const SizedBox.shrink();
    final count = items.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _hPad),
          child: Row(
            children: [
              _accentMarker(_yellow),
              const SizedBox(width: 10),
              Expanded(child: Text('Projects Feed', style: _stepHeadlineStyle)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF5D737E).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt, size: 13, color: Color(0xFF5D737E)),
                    const SizedBox(width: 4),
                    Text('$count today',
                        style: const TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF5D737E),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.fromLTRB(38, 0, _hPad, 0),
          child: Text('Latest across all your builds.',
              style: const TextStyle(
                fontFamily: _bodyFont,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _faint,
              )),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _hPad),
          child: Stack(
            children: [
              Positioned(
                left: 14,
                top: 8,
                bottom: 8,
                child: Container(width: 2, color: const Color(0xFFDCE3E6)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: items,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _dashFeedRow(String project, String activity) {
    final parts = activity.split(' · ');
    final title = parts.isNotEmpty ? parts.first : activity;
    final time = parts.length > 1 ? parts.last : '';
    final meta = time.isEmpty ? project : '$project · $time';
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE7EDF0),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFCBD8DD), width: 1.5),
            ),
            child: const Icon(Icons.bolt, size: 16, color: Color(0xFF5D737E)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: _displayFont,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.1,
                      color: _ink,
                    )),
                const SizedBox(height: 3),
                Text(meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: _bodyFont,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _inkMute,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // PROJECTS FEED — real activity log, grouped by day.
  // Streams the top-level `activity` collection scoped to the
  // viewer's owned + shared builds, groups events by calendar day
  // (device-local), and collapses same-type repeats per project per
  // day into one counted row ("Snag recorded x3").
  //
  // Each activity doc is fully denormalised (zero lookups):
  //   projectRef, type, title, actorName, createdAt
  //
  // Requires composite index: activity(projectRef ASC, createdAt DESC).
  // whereIn caps at 30 refs — for >30 builds the 30 most-recent are used.
  // =========================================================
  Widget _buildActivityFeed(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> owned,
    List<_SharedProject> shared,
  ) {
    final refs = <DocumentReference>[];
    final seen = <String>{};
    final names = <String, String>{}; // projectRef.path -> name (row subtitle)

    for (final d in owned) {
      final r = d.reference;
      if (seen.add(r.path)) {
        refs.add(r);
        names[r.path] = (d.data()['name'] as String?)?.trim() ?? 'Untitled';
      }
    }
    for (final sp in shared) {
      if (seen.add(sp.ref.path)) {
        refs.add(sp.ref);
        names[sp.ref.path] = (sp.data['name'] as String?)?.trim() ?? 'Untitled';
      }
    }
    if (refs.isEmpty) return const SizedBox.shrink();

    // whereIn supports up to 30 values; owned are already most-recent first.
    final queryRefs = refs.length > 30 ? refs.sublist(0, 30) : refs;

    final q = FirebaseFirestore.instance
        .collection('activity')
        .where('projectRef', whereIn: queryRefs)
        .orderBy('createdAt', descending: true)
        .limit(60);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const SizedBox.shrink();

        // Group by day, collapse per (project + type) within each day.
        final dayOrder = <String>[];
        final dayRows = <String, List<_FeedRow>>{};
        final collapse = <String, _FeedRow>{}; // 'day|projPath|type' -> row

        for (final doc in docs) {
          final data = doc.data();
          final ts = data['createdAt'];
          if (ts is! Timestamp) continue; // pending serverTimestamp
          final dt = ts.toDate();
          final dayKey = _dayKey(dt);
          final type = (data['type'] as String?) ?? '';
          final pr = data['projectRef'];
          final projPath = (pr is DocumentReference) ? pr.path : '';
          final projName = names[projPath] ?? 'A build';
          final title = (data['title'] as String?)?.trim() ?? '';

          if (!dayRows.containsKey(dayKey)) {
            dayRows[dayKey] = <_FeedRow>[];
            dayOrder.add(dayKey);
          }

          final cKey = '$dayKey|$projPath|$type';
          final existing = collapse[cKey];
          if (existing == null) {
            final tref = data['targetRef'];
            final row = _FeedRow(
              type: type,
              project: projName,
              title: title,
              latest: dt,
              count: 1,
              targetRef: tref is DocumentReference ? tref : null,
              projectRef: pr is DocumentReference ? pr : null,
            );
            collapse[cKey] = row;
            dayRows[dayKey]!.add(row);
          } else {
            existing.count += 1;
            if (dt.isAfter(existing.latest)) existing.latest = dt;
          }
        }

        final children = <Widget>[
          const SizedBox(height: 30),
          _feedHeader(docs.length),
        ];

        for (final dayKey in dayOrder) {
          children.add(Padding(
            padding: const EdgeInsets.fromLTRB(_hPad, 16, _hPad, 8),
            child: Text(
              _dayLabel(dayKey),
              style: const TextStyle(
                fontFamily: _bodyFont,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: _faint,
              ),
            ),
          ));
          children.add(Padding(
            padding: const EdgeInsets.symmetric(horizontal: _hPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final r in dayRows[dayKey]!) _activityRow(r)],
            ),
          ));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        );
      },
    );
  }

  Widget _feedHeader(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _hPad),
      child: Row(
        children: [
          _accentMarker(_yellow),
          const SizedBox(width: 10),
          Expanded(child: Text('Projects Feed', style: _stepHeadlineStyle)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: _surface, // standard grey pill (matches other counts)
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt, size: 13, color: _inkMute),
                const SizedBox(width: 4),
                Text('$count recent',
                    style: const TextStyle(
                      fontFamily: _bodyFont,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: _inkMute,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityRow(_FeedRow r) {
    final collapsed = r.count > 1;
    final String label;
    if (collapsed) {
      // Many same-type events on one build in a day -> "Task added x3".
      label = '${_activityTypeLabel(r.type)} \u00d7${r.count}';
    } else if (r.title.isEmpty) {
      label = _activityTypeLabel(r.type);
    } else if (r.type == 'snag_status') {
      // snag_status titles already read "<snag> - <status>" -> no verb prefix.
      label = r.title;
    } else {
      // Lead with the action so the row reads "Document uploaded: <name>".
      label = '${_activityTypeLabel(r.type)}: ${r.title}';
    }
    final sub = '${r.project} \u00b7 ${_relativeTime(r.latest)}';
    return InkWell(
        onTap: () => _openActivityTarget(r),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7EDF0),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: const Color(0xFFCBD8DD), width: 1.5),
                ),
                child: Icon(_activityIcon(r.type),
                    size: 16, color: const Color(0xFF5D737E)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: _displayFont,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.1,
                          color: _ink,
                        )),
                    const SizedBox(height: 3),
                    Text(sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _inkMute,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  // Open the snag/task an activity row points at. Single events deep-link to
  // their detail page (mirrors SnagList/ToDoList); collapsed rows, document
  // uploads, and older events with no targetRef fall back to the project.
  void _openActivityTarget(_FeedRow r) {
    final target = r.targetRef;
    final isSnag = r.type == 'snag_recorded' || r.type == 'snag_status';
    final isTask = r.type == 'task_added' || r.type == 'task_completed';

    if (r.count == 1 && target != null && isSnag) {
      final route = (widget.snagDetailRouteName ?? '').trim();
      if (route.isNotEmpty) {
        context.pushNamed(route, queryParameters: {
          'snagRef': serializeParam(target, ParamType.DocumentReference),
        });
        return;
      }
    }
    if (r.count == 1 && target != null && isTask) {
      final route = (widget.taskDetailRouteName ?? '').trim();
      if (route.isNotEmpty) {
        context.pushNamed(route, queryParameters: {
          'taskRef': serializeParam(target, ParamType.DocumentReference),
        });
        return;
      }
    }
    final pr = r.projectRef;
    if (pr != null) _goToProject(pr);
  }

  String _activityTypeLabel(String type) {
    switch (type) {
      case 'snag_recorded':
        return 'Snag recorded';
      case 'task_added':
        return 'Task added';
      case 'task_completed':
        return 'Task completed';
      case 'snag_status':
        return 'Snag updated';
      case 'document_uploaded':
        return 'Document uploaded';
      case 'quote_requested':
        return 'Quote requested';
      case 'quote_submitted':
        return 'Quote received';
      case 'quote_accepted':
        return 'Quote accepted';
      case 'quote_declined':
        return 'Quote declined';
      case 'cost_updated':
        return 'Costs updated';
      case 'programme_updated':
        return 'Timeline updated';
      case 'site_note_added':
        return 'Site note';
      default:
        return 'Activity';
    }
  }

  IconData _activityIcon(String type) {
    switch (type) {
      case 'snag_recorded':
        return Icons.report_outlined;
      case 'task_added':
        return Icons.add_task;
      case 'task_completed':
        return Icons.check_circle_outline;
      case 'snag_status':
        return Icons.sync;
      case 'document_uploaded':
        return Icons.description_outlined;
      case 'quote_requested':
        return Icons.outgoing_mail;
      case 'quote_submitted':
        return Icons.request_quote_outlined;
      case 'quote_accepted':
        return Icons.verified_outlined;
      case 'quote_declined':
        return Icons.do_not_disturb_on_outlined;
      case 'cost_updated':
        return Icons.payments_outlined;
      case 'programme_updated':
        return Icons.timeline;
      case 'site_note_added':
        return Icons.menu_book_outlined;
      default:
        return Icons.bolt;
    }
  }

  // Calendar-day key in device-local time: 'yyyy-mm-dd'.
  String _dayKey(DateTime dt) {
    final l = dt.toLocal();
    final m = l.month.toString().padLeft(2, '0');
    final d = l.day.toString().padLeft(2, '0');
    return '${l.year}-$m-$d';
  }

  // Human day label: TODAY / YESTERDAY / 'WED 25 JUN'.
  String _dayLabel(String dayKey) {
    final p = dayKey.split('-');
    final dt = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(dt).inDays;
    if (diff == 0) return 'TODAY';
    if (diff == 1) return 'YESTERDAY';
    const wd = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    const mo = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];
    return '${wd[dt.weekday - 1]} ${dt.day} ${mo[dt.month - 1]}';
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
          // MOST RECENT card — sage-yellow tint (matches the ProjectDetail
          // "Manage" module tiles + the rest of the project cards).
          color: const Color(0xFFE7EDF0),
          border: Border.all(color: const Color(0xFFCBD8DD)),
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
                color: _ink,
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
                  Icon(Icons.bolt, size: 15, color: _activityColor(data)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(act,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _heroActivityStyle.copyWith(
                            color: _activityColor(data))),
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
            // Owned project rows — sage-yellow tint (matches the Manage tiles).
            color: const Color(0xFFE7EDF0),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFCBD8DD)),
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
                          style: _tileSubtitleStyle.copyWith(color: _ink),
                        ),
                        if (act != null) ...[
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                    color: _activityColor(data),
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(act,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _rowActivityStyle.copyWith(
                                        color: _activityColor(data))),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded,
                      size: 20, color: _ink),
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
  // RETAINED — superseded by the in-grid _addTile(); kept for reference.
  // ignore: unused_element
  Widget _newProjectButton() => InkWell(
        onTap: _goToAddProject,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFCBD8DD), width: 1.4),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, size: 18, color: Color(0xFF55656E)),
              SizedBox(width: 8),
              Text(
                'New home build',
                style: TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF55656E),
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
            color: const Color(0xFFAC0C0C),
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
            color: const Color(0xFFAC0C0C),
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
          border: Border.all(color: const Color(0xFFDCE3E6)),
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
                size: 20, color: Color(0xFFCBD8DD)),
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
            border: Border.all(color: const Color(0xFFCBD8DD), width: 1.4),
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
    // Drop cached streams/futures if the signed-in user changed.
    _resetCachesIfUserChanged();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshHasListing(); // keep listing state fresh on return
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Dark (black) status-bar icons over the white dashboard. Because the
      // visible route's AnnotatedRegion wins, this reasserts dark icons the
      // moment ProjectDetailPageView (which forces light) is popped.
      value: SystemUiOverlayStyle.light,
      child: Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? double.infinity,
        color: _paper,
        // Welcome header is PINNED (fixed) — only the body below it scrolls.
        child: Column(
          children: [
            _buildWelcomeHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildQuoteInvites(),
                    _buildBody(),
                    // Archived builds — collapsed, pinned to the bottom.
                    _buildArchivedCollapsible(),
                    // Clear the overlaid MainBottomNav (72) + breathing room
                    // (28) + system gesture inset.
                    SizedBox(
                        height:
                            72 + 28 + MediaQuery.of(context).padding.bottom),
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

// =====================================================================
// Capability chip — the soft pills in the empty states (Plans, Budget…).
// =====================================================================
class _CapabilityChip extends StatelessWidget {
  const _CapabilityChip(this.label);

  final String label;

  static const Color _tealTint = Color(0xFFE7EDF0);
  static const Color _tealText = Color(0xFF29343A);

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
// NOTE: retained for reference — the logo now renders from a PNG asset
// (assets/images/subby-mark-green.png). Kept so the painted mark can be restored.
// ignore: unused_element
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

// One collapsed feed row: all events of the same type on the same project
// within one calendar day fold into a single row carrying a count.
class _FeedRow {
  _FeedRow({
    required this.type,
    required this.project,
    required this.title,
    required this.latest,
    required this.count,
    this.targetRef,
    this.projectRef,
  });
  final String type;
  final String project;
  final String title;
  DateTime latest;
  int count;
  final DocumentReference? targetRef;
  final DocumentReference? projectRef;
}
