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
// v3 — simplified entry page. Two sections only:
//   1) My Projects  — horizontal rail of the user's live projects + Add card.
//                      Accent = ORANGE (light + dark).
//   2) Directory    — browse trades/suppliers + manage own listing.
//                      Accent = YELLOW.
//
// Removed in v3: the project-management grid (Timeline / Project Cost / Quotes /
// Snag) — those now live INSIDE a project — and the Resources / legal footer,
// which is moving to its own page. Profile/account access moved to a button in
// the welcome header so the body is exactly the two sections.
//
// NOTE on widget params: the legacy route params (timeline / snag / projectCost /
// getQuotes / terms / privacy / support) and the snag/myProjects counts are kept
// on the constructor so the existing FlutterFlow component instance does NOT
// break. They are no longer used by this screen and can be deleted from the FF
// widget definition whenever convenient. Two new optional params were added:
// projectDetailRouteName, addProjectsRouteName, projectParamName.

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
    this.projectDetailRouteName, // ✅ NEW — open a single project
    this.addProjectsRouteName, // ✅ NEW — create a new project
    this.projectParamName, // ✅ NEW — param name for the project ref (default "projectRef")

    /// Listing management routes (Directory tile) — USED
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
  final String? projectDetailRouteName;
  final String? addProjectsRouteName;
  final String? projectParamName;
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
  static const Color _ink = Color(
      0xFF14243F); // unified navy — text, chrome, projects card, on-yellow content
  static const Color _inkMute = Color(0xFF6B7280);
  static const Color _paper = Color(0xFFFFFFFF); // White
  static const Color _surface = Color(0xFFE3E4E8);
  static const Color _hairline = Color(0xFFE3E4E8);

  // ── TWO-SECTION CARD SYSTEM ────────────────────────────────────────
  // Both cards live in the ink family so the darks never fight.
  //  • PROJECTS = dark "ink-lifted" block, WHITE content
  //    (white text, white-translucent chip + white icon, white-translucent
  //     status pill + white text).
  //  • DIRECTORY = yellow block, INK content
  //    (ink text, ink chip + white icon, ink pill + white text).

  // Accent — MY PROJECTS = INK (dark card = ink, one unified dark)
  static const Color _projBg =
      _ink; // same as ink — never a second competing dark
  static final Color _onDarkSub =
      Colors.white.withOpacity(0.82); // secondary text on dark card
  static const Color _projTint = Color(0xFFE8EAEF); // pale navy — add-card fill
  // (icon chip + status pill on the dark card use _yellow / _ink — see below)

  // Accent — DIRECTORY = YELLOW (ink content)
  static const Color _yellow = Color(0xFFFFE74C); // yellow card background
  static const Color _onYellowChip = _ink; // ink chip + white icon
  static const Color _onYellowSub = _ink; // secondary text on yellow

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
  static const double _sectionBreak = 56;
  static const double _titleToDesc = 8;
  static const double _descToTile = 16;

  // Directory tile heights
  static const double _tileH = 78;
  static const double _tileHEmphasis = 88;

  // Projects rail
  static const double _railH = 152;
  static const double _cardW = 224;
  static const double _addCardW = 152;
  static const double _betweenCards = 12;

  // Route fallbacks
  static const String _fallbackProfileRoute = 'profilePage';
  static const String _fallbackProjectsRoute = 'MyProjectsHomePage';
  static const String _fallbackProjectDetailRoute = 'ProjectDetailPage';
  static const String _fallbackAddProjectsRoute = 'addProjectsPage';
  static const String _fallbackAddListingRoute = 'addListingPage';
  static const String _fallbackEditListingRoute = 'editListingPage';

  // Listing exists (drives Add / Edit on the Directory tile)
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

  String _fmtDate(DateTime? d) {
    if (d == null) return '';
    final dd = d.day.toString().padLeft(2, '0');
    return '$dd ${_months[d.month - 1]} ${d.year}';
  }

  // =========================================================
  // TYPOGRAPHY
  // =========================================================
  TextStyle get _appTitleStyle => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        height: 1.05,
        color: _ink,
      );

  TextStyle get _appSubtitleStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 12,
        color: _inkMute,
      );

  TextStyle get _stepHeadlineStyle => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        height: 1.05,
        color: _ink,
      );

  TextStyle get _stepDescStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: _inkMute,
      );

  TextStyle get _tileTitleStyle => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: _ink,
      );

  TextStyle get _tileSubtitleStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _inkMute,
      );

  TextStyle get _metaStyle => const TextStyle(
        fontFamily: _monoFont,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: _inkMute,
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
  // Listing exists for current user (Directory Add / Edit label)
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
  // Small shared bits
  // -----------------------------
  Widget _accentMarker(Color c) => Container(
        width: 10,
        height: 18,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(3),
        ),
      );

  // -----------------------------
  // Welcome header (personalised) + account button
  // -----------------------------
  Widget _buildWelcomeHeader(FlutterFlowTheme theme) {
    final topInset = MediaQuery.of(context).padding.top;
    final name = currentUserDisplayName.trim();
    final firstName = name.isNotEmpty ? name.split(' ').first : '';
    final hasName = firstName.isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(_hPad, topInset + 14, _hPad, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _ink,
                  borderRadius: BorderRadius.circular(_rMed),
                ),
                child: const Icon(Icons.home_rounded, size: 20, color: _paper),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasName) ...[
                      Text('Welcome back', style: _appSubtitleStyle),
                      const SizedBox(height: 1),
                      Text(
                        firstName,
                        style: _appTitleStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else
                      Text(
                        'Welcome to Subby',
                        style: _appTitleStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _accountButton(),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, width: double.infinity, color: _hairline),
        ],
      ),
    );
  }

  Widget _accountButton() => InkWell(
        onTap: () => _safeNavigate(
          widget.profileRouteName,
          fallbackRoute: _fallbackProfileRoute,
        ),
        borderRadius: BorderRadius.circular(_rPill),
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _projTint,
          ),
          child: const Icon(Icons.person_rounded, size: 20, color: _ink),
        ),
      );

  // =====================================================================
  // SECTION 1 — MY PROJECTS (orange) — horizontal rail
  // =====================================================================
  Widget _buildProjectsSection(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _accentMarker(_projBg),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text('Home Building Projects',
                          style: _stepHeadlineStyle)),
                ],
              ),
              const SizedBox(height: _titleToDesc),
              Text(
                'Open a project to manage its plans, timeline, budget, quotes & snags.',
                style: _stepDescStyle,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _projectsRail(theme),
      ],
    );
  }

  Widget _projectsRail(FlutterFlowTheme theme) {
    final q = _activeProjectsQuery();

    if (q == null) {
      // Not signed in / no user ref — show the create prompt.
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: _hPad),
        child: _emptyProjectsCard(),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: _hPad),
            child: _emptyProjectsCard(),
          );
        }

        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return SizedBox(height: _railH, child: _railLoading());
        }

        final docs = snap.data?.docs ?? const [];

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: _hPad),
            child: _emptyProjectsCard(),
          );
        }

        return SizedBox(
          height: _railH,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: _hPad),
            itemCount: docs.length + 1, // + Add card
            separatorBuilder: (_, __) => const SizedBox(width: _betweenCards),
            itemBuilder: (context, i) {
              if (i == docs.length) return _addProjectCard();
              return _projectCard(docs[i]);
            },
          ),
        );
      },
    );
  }

  Widget _railLoading() => ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _hPad),
        children: [
          _skeletonCard(),
          const SizedBox(width: _betweenCards),
          _skeletonCard(),
        ],
      );

  Widget _skeletonCard() => Container(
        width: _cardW,
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: _hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(_rMed),
                ),
              ),
              const SizedBox(height: 14),
              Container(height: 12, width: 130, color: _surface),
              const SizedBox(height: 8),
              Container(height: 10, width: 90, color: _surface),
            ],
          ),
        ),
      );

  Widget _statusPill(String status) {
    final label =
        status.isEmpty ? '' : status[0].toUpperCase() + status.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _yellow,
        borderRadius: BorderRadius.circular(_rPill),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: _bodyFont,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _ink,
        ),
      ),
    );
  }

  Widget _projectCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final name = (data['name'] as String?)?.trim() ?? '';
    final city = (data['city'] as String?)?.trim() ?? '';
    final province = (data['province'] as String?)?.trim() ?? '';
    final status = (data['status'] as String?)?.trim() ?? '';
    final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();
    final loc = [city, province].where((x) => x.isNotEmpty).join(', ');

    return InkWell(
      onTap: () => _goToProject(doc.reference),
      borderRadius: BorderRadius.circular(_radius),
      child: Container(
        width: _cardW,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _projBg,
          borderRadius: BorderRadius.circular(_radius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _yellow,
                            borderRadius: BorderRadius.circular(_rMed),
                          ),
                          child: const Icon(
                            Icons.folder_rounded,
                            size: 20,
                            color: _ink,
                          ),
                        ),
                        const Spacer(),
                        if (status.isNotEmpty) _statusPill(status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      name.isEmpty ? 'Untitled project' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _tileTitleStyle.copyWith(color: _paper),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      loc.isEmpty ? 'No location set' : loc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _tileSubtitleStyle.copyWith(color: _onDarkSub),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            updatedAt == null
                                ? ''
                                : 'Updated ${_fmtDate(updatedAt)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _metaStyle.copyWith(color: _onDarkSub),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: _paper,
                        ),
                      ],
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

  Widget _addProjectCard() => InkWell(
        onTap: _goToAddProject,
        borderRadius: BorderRadius.circular(_radius),
        child: Container(
          width: _addCardW,
          decoration: BoxDecoration(
            color: _projTint,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: _projBg, width: 1.4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _projBg,
                  borderRadius: BorderRadius.circular(_rMed),
                ),
                child: const Icon(Icons.add_rounded, size: 24, color: _paper),
              ),
              const SizedBox(height: 10),
              const Text(
                'New Project',
                style: TextStyle(
                  fontFamily: _displayFont,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _projBg,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Start a build',
                style: TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 11,
                  color: _projBg.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _emptyProjectsCard() => InkWell(
        onTap: _goToAddProject,
        borderRadius: BorderRadius.circular(_radius),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _projTint,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: _projBg, width: 1.4),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _projBg,
                    borderRadius: BorderRadius.circular(_rMed),
                  ),
                  child: const Icon(Icons.add_rounded, size: 26, color: _paper),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create your first project',
                        style: _tileTitleStyle.copyWith(color: _projBg),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Store plans, photos, notes, timeline, budget & key contacts.',
                        style: _tileSubtitleStyle.copyWith(
                          color: _projBg.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: _projBg),
              ],
            ),
          ),
        ),
      );

  // =====================================================================
  // SECTION 2 — DIRECTORY (yellow)
  // =====================================================================
  Widget _buildDirectorySection(FlutterFlowTheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _accentMarker(_yellow),
              const SizedBox(width: 10),
              Expanded(
                  child: Text('Home Building Directory',
                      style: _stepHeadlineStyle)),
            ],
          ),
          const SizedBox(height: _titleToDesc),
          Text(
            'Browse trades & suppliers, compare options, and manage your own listing.',
            style: _stepDescStyle,
          ),
          const SizedBox(height: _descToTile),
          _directoryTile(
            theme: theme,
            onNavigateDirectory: () => _safeNavigate(widget.directoryRouteName),
          ),
        ],
      ),
    );
  }

  Widget _directoryTile({
    required FlutterFlowTheme theme,
    required VoidCallback onNavigateDirectory,
    bool emphasized = true,
  }) {
    Widget pillButton({
      required String label,
      required VoidCallback onTap,
      IconData? icon,
    }) {
      // Primary action on a yellow card = ink button, white content.
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_rMed),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: _ink,
            borderRadius: BorderRadius.circular(_rMed),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: _paper),
                const SizedBox(width: 8),
              ],
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
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _yellow,
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onNavigateDirectory,
            child: SizedBox(
              height: emphasized ? _tileHEmphasis : _tileH,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
                child: Row(
                  children: [
                    // Ink chip + white icon on the yellow card
                    Container(
                      width: emphasized ? 48 : 44,
                      height: emphasized ? 48 : 44,
                      decoration: BoxDecoration(
                        color: _onYellowChip,
                        borderRadius: BorderRadius.circular(_rMed),
                      ),
                      child: const Icon(
                        Icons.home_work_rounded,
                        size: 22,
                        color: _paper,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // No "Directory" here — the section header already
                          // says it. Lead with the value instead.
                          Text('Browse trades & suppliers',
                              style: _tileTitleStyle.copyWith(color: _ink)),
                          const SizedBox(height: 4),
                          Text(
                            'Compare options & manage your listing',
                            style: _tileSubtitleStyle.copyWith(
                                color: _onYellowSub),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: _ink),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: pillButton(
                    label: _hasListing ? 'Edit Listing' : 'Add Listing',
                    icon: _hasListing
                        ? Icons.edit_outlined
                        : Icons.add_circle_outline_rounded,
                    onTap: () {
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
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // BUILD
  // =====================================================================
  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshHasListing(); // keep Add/Edit label fresh on return
    });

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: _paper,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildWelcomeHeader(theme),
            _buildProjectsSection(theme),
            const SizedBox(height: _sectionBreak),
            _buildDirectorySection(theme),
            SizedBox(height: 28 + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
