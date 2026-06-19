// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// ======================= DashboardPageView (FULL FILE) =======================
//
// v4 — "Portfolio overview" home, big & minimal welcome.
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
  static const Color _ink = Color(0xFF16202E); // text, chrome, dark surfaces
  static const Color _inkMute = Color(0xFF5A6675);
  static const Color _faint = Color(0xFF93A0B0); // muted labels, chevrons
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFEEF1F4);
  static const Color _hairline = Color(0xFFEEF1F2);

  // Accents
  static const Color _yellow =
      Color(0xFF0D9488); // deep teal — "on site" / on track
  static const Color _ringTrack = Color(0xFFEEF2F7);
  static const Color _orange = Color(0xFFFF6A2B); // attention / snagging
  static const Color _orangeTint = Color(0xFFFFE7DA);
  static const Color _orangeBorder = Color(0xFFFFD9C6);
  static const Color _orangeText = Color(0xFFC2693F);
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

    context.pushNamed(
      target,
      extra: <String, dynamic>{
        kTransitionInfoKey: const TransitionInfo(
          hasTransition: true,
          transitionType: PageTransitionType.rightToLeft,
          duration: Duration(milliseconds: 260),
        ),
      },
    );
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

  // Top-right menu button → the More hub (Manage · Support · Legal).
  // Presented as a right-anchored slide-over panel: it slides in from the
  // right, can be swept right (or flung) to dismiss, and also closes on a
  // back gesture / barrier tap. Rendering MorePageView directly removes the
  // dependency on a named FF route (the old push silently no-op'd when the
  // route name didn't match).
  void _goToMore() => _openMorePanel();

  void _openMorePanel() {
    final Size size = MediaQuery.sizeOf(context);

    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        fullscreenDialog: true,
        barrierColor: Colors.black.withOpacity(0.28),
        barrierDismissible: true,
        barrierLabel: 'More',
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (ctx, _, __) => Align(
          alignment: Alignment.centerRight,
          child: _MoreSlidePanel(
            child: Material(
              type: MaterialType.transparency,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: const MorePageView(),
              ),
            ),
          ),
        ),
        transitionsBuilder: (ctx, anim, _, child) {
          final curved = CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        },
      ),
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
        kTransitionInfoKey: const TransitionInfo(
          hasTransition: true,
          transitionType: PageTransitionType.rightToLeft,
          duration: Duration(milliseconds: 260),
        ),
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
          Expanded(child: Text('Home Projects', style: _stepHeadlineStyle)),
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
      padding: EdgeInsets.fromLTRB(_hPad, topInset + 16, _hPad, 6),
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
      return Padding(
        padding: const EdgeInsets.fromLTRB(_hPad, 18, _hPad, 0),
        child: _buildOnboarding(),
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
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _hPad),
              child: Column(
                children: [
                  for (final d in docs) ...[
                    _projectCard(d),
                    const SizedBox(height: 10),
                  ],
                  _newProjectButton(),
                ],
              ),
            ),
          ],
        );
      },
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
  // Project card (progress ring)
  // -----------------------------
  Widget _projectCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
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
      borderRadius: BorderRadius.circular(_radius),
      child: Container(
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: _hairline),
        ),
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            _progressRing(progress, attention),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name.isEmpty ? 'Untitled project' : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _tileTitleStyle,
                        ),
                      ),
                      if (status.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _miniPill(status, attention),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
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

  Widget _progressRing(double progress, bool attention) {
    final Color arc = attention ? _orange : _ink;
    final Color track = attention ? _orangeTint : _ringTrack;
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 5,
              strokeCap: StrokeCap.round,
              backgroundColor: track,
              valueColor: AlwaysStoppedAnimation<Color>(arc),
            ),
          ),
          Text('${(progress * 100).round()}%', style: _ringPctStyle),
        ],
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
        children: [
          _skeletonCard(),
          const SizedBox(height: 10),
          _skeletonCard(),
        ],
      );

  Widget _skeletonCard() => Container(
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: _hairline),
        ),
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, width: 140, color: _surface),
                  const SizedBox(height: 8),
                  Container(height: 10, width: 100, color: _surface),
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
  static const Color _tealText = Color(0xFF0D6B62);

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

// =====================================================================
// More slide-over: follows the finger on a rightward drag and pops when
// dragged past ~30% of the screen width (or flung right). Self-contained —
// no shared statics with the state class above (file-scope class scoping).
// Vertical scrolling inside the child is unaffected; only horizontal drags
// are claimed here.
// =====================================================================
class _MoreSlidePanel extends StatefulWidget {
  const _MoreSlidePanel({required this.child});

  final Widget child;

  @override
  State<_MoreSlidePanel> createState() => _MoreSlidePanelState();
}

class _MoreSlidePanelState extends State<_MoreSlidePanel> {
  double _dragX = 0; // rightward offset, >= 0

  void _onUpdate(DragUpdateDetails d) {
    setState(() {
      _dragX = (_dragX + d.delta.dx).clamp(0.0, double.infinity);
    });
  }

  void _onEnd(DragEndDetails d) {
    final double width = MediaQuery.sizeOf(context).width;
    final double v = d.primaryVelocity ?? 0;
    final bool close = _dragX > width * 0.30 || v > 700;
    if (close) {
      Navigator.of(context).maybePop();
    } else {
      setState(() => _dragX = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onHorizontalDragUpdate: _onUpdate,
      onHorizontalDragEnd: _onEnd,
      child: Transform.translate(
        offset: Offset(_dragX, 0),
        child: widget.child,
      ),
    );
  }
}

// Subby peak mark — bold, icon only (viewBox 0 0 64 64):
//   peak  : polyline 12,40 → 32,18 → 52,40
//   base  : line     14,50 → 50,50 (teal)
class _SubbyMarkPainter extends CustomPainter {
  final Color peak;
  final Color base;
  const _SubbyMarkPainter({required this.peak, required this.base});

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 64.0;
    Offset p(double x, double y) => Offset(x * s, y * s);

    final peakPaint = Paint()
      ..color = peak
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(p(12, 40).dx, p(12, 40).dy)
      ..lineTo(p(32, 18).dx, p(32, 18).dy)
      ..lineTo(p(52, 40).dx, p(52, 40).dy);
    canvas.drawPath(path, peakPaint);

    final basePaint = Paint()
      ..color = base
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(p(14, 50), p(50, 50), basePaint);
  }

  @override
  bool shouldRepaint(covariant _SubbyMarkPainter old) =>
      old.peak != peak || old.base != base;
}
