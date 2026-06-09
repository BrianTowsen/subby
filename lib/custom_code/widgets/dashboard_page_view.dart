// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// ======================= DashboardPageView (FULL FILE) =======================

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

    /// Routes
    this.directoryRouteName,
    this.timelineRouteName, // ✅ will now fallback to TimelineHomePage
    this.snagListRouteName,
    this.projectCostRouteName,
    this.getQuotesRouteName, // ✅ NEW
    this.projectsRouteName, // ✅ will now navigate to MyProjectsHomePage by default
    this.profileRouteName,

    /// ✅ Listing management routes (Dashboard controls listing)
    this.addListingRouteName, // optional
    this.editListingRouteName, // optional

    /// Footer menu routes
    this.termsRouteName,
    this.privacyRouteName,
    this.supportRouteName,

    /// Counts
    this.snagCount,
    this.myProjectsCount,
  });

  final double? width;
  final double? height;

  final String? directoryRouteName;
  final String? timelineRouteName;
  final String? snagListRouteName;
  final String? projectCostRouteName;
  final String? getQuotesRouteName; // ✅ NEW
  final String? projectsRouteName;
  final String? profileRouteName;

  final String? addListingRouteName; // ✅ NEW
  final String? editListingRouteName; // ✅ NEW

  final String? termsRouteName;
  final String? privacyRouteName;
  final String? supportRouteName;

  final int? snagCount;
  final int? myProjectsCount;

  @override
  State<DashboardPageView> createState() => _DashboardPageViewState();
}

class _DashboardPageViewState extends State<DashboardPageView> {
  static const double _hPad = 24;
  static const double _radius = 16;

  // ✅ Modern spacing rhythm
  static const double _sectionBreak = 38; // between steps
  static const double _titleToDesc = 8;
  static const double _descToTile = 16;
  static const double _betweenTiles = 12;
  static const double _gapAfterPM = 34; // big space before profile

  // ✅ NEW: tighter gap for Step 3 subtitle -> grid tiles
  static const double _pmDescToGrid = 10;

  // Tile heights
  static const double _tileH = 78; // standard tile (Group 2)
  static const double _tileHEmphasis = 88; // bigger tiles (Group 1)

  // ✅ Grid tile sizing (Step 3)
  static const double _pmGridTileH = 165;

  // Route fallbacks
  static const String _fallbackProfileRoute = 'profilePage';

  // ✅ UPDATED: Dashboard "My Projects" now navigates to your MyProjectsHomePage by default
  static const String _fallbackProjectsRoute = 'MyProjectsHomePage';

  // ✅ NEW: Timeline tile fallback to your TimelineHomePage (matches your page name)
  static const String _fallbackTimelineRoute = 'TimelineHomePage';

  static const String _fallbackGetQuotesRoute = 'quotesPage'; // ✅ NEW

  // ✅ Listing management fallbacks (change these to your real FF page names if needed)
  static const String _fallbackAddListingRoute = 'addListingPage';
  static const String _fallbackEditListingRoute = 'editListingPage';

  // Footer fallbacks
  static const String _fallbackTermsRoute = 'termsPage';
  static const String _fallbackPrivacyRoute = 'privacyPage';
  static const String _fallbackSupportRoute = 'supportPage';

  // ---- Reorder persistence (ONLY Group 2) ----
  static const String _kPrefsOrderKey = 'subby_dashboard_pm_tile_order_v1';

  // ✅ terms/privacy acceptance persistence
  static const String _kAcceptedTermsKey = 'subby_terms_accepted_v1';
  static const String _kAcceptedPrivacyKey = 'subby_privacy_accepted_v1';

  // Tile IDs
  static const String _tProjects = 'projects'; // Group 1 fixed
  static const String _tDirectory = 'directory'; // Group 1 fixed

  static const String _tTimeline = 'timeline'; // Group 2
  static const String _tProjectCost = 'projectCost';
  static const String _tGetQuotes = 'getQuotes';
  static const String _tSnag = 'snag';

  static const List<String> _defaultPMOrder = [
    _tTimeline,
    _tProjectCost,
    _tGetQuotes,
    _tSnag,
  ];

  List<String> _pmTileOrder = List<String>.from(_defaultPMOrder);

  // ✅ Terms/Privacy acceptance
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;

  // ✅ listing exists (to show Add / Edit)
  bool _hasListing = false;

  // ✅ robust prefs sync (handles FF keeping page alive)
  bool _prefsSyncInFlight = false;
  int _lastPrefsSyncMs = 0;

  // =========================================================
  // ✅ TYPOGRAPHY (LOCKED)
  // =========================================================

  TextStyle _appTitleStyle(FlutterFlowTheme theme) {
    return theme.titleLarge.copyWith(
      fontWeight: FontWeight.w900,
      letterSpacing: 0.2,
    );
  }

  TextStyle _appSubtitleStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: t.bodySmallFamily,
        color: t.secondaryText,
      );

  TextStyle _sectionTitleStyle(FlutterFlowTheme t) => t.titleMedium.override(
        fontFamily: t.titleMediumFamily,
        fontWeight: FontWeight.w900,
        color: t.primaryText,
      );

  TextStyle _tileTitleStyle(FlutterFlowTheme t) => t.titleLarge.override(
        fontFamily: t.titleLargeFamily,
      );

  TextStyle _tileSubtitleStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: t.bodySmallFamily,
        color: t.secondaryText,
      );

  TextStyle _badgeTextStyle(FlutterFlowTheme t) => t.labelSmall.override(
        fontFamily: t.labelSmallFamily,
        color: Colors.white,
      );

  TextStyle _footerRowTextStyle(FlutterFlowTheme t) => t.bodyMedium.override(
        fontFamily: t.bodyMediumFamily,
        color: t.secondaryText,
      );

  TextStyle _profileNameStyle(FlutterFlowTheme t) => t.titleMedium.override(
        fontFamily: t.titleMediumFamily,
        fontWeight: FontWeight.w900,
        color: t.primaryText,
      );

  TextStyle _profileMetaStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: t.bodySmallFamily,
        color: t.secondaryText,
      );

  TextStyle _stepHeadlineStyle(FlutterFlowTheme t) =>
      _appTitleStyle(t).copyWith(color: t.primaryText);

  TextStyle _stepDescStyle(FlutterFlowTheme t) => _appSubtitleStyle(t).copyWith(
        fontWeight: FontWeight.w600,
      );

  // =========================================================

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _initAll();
      await _syncPrefsFromStorage(force: true);
    });
  }

  Future<void> _initAll() async {
    await _initPMTileOrder();
    await _initLegalAcceptance();
    await _refreshHasListing();
  }

  // -----------------------------
  // ✅ Navigation
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

  // -----------------------------
  // ✅ PM Order normalization (ONLY Group 2)
  // -----------------------------
  List<String> _normalizePMOrder(List<String> input) {
    final seen = <String>{};
    final out = <String>[];

    for (final id in input) {
      if (_defaultPMOrder.contains(id) && !seen.contains(id)) {
        seen.add(id);
        out.add(id);
      }
    }
    for (final id in _defaultPMOrder) {
      if (!seen.contains(id)) out.add(id);
    }
    return out;
  }

  // -----------------------------
  // ✅ Robust pref sync (ONLY Group 2)
  // -----------------------------
  Future<void> _syncPrefsFromStorage({bool force = false}) async {
    if (_prefsSyncInFlight) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (!force && (nowMs - _lastPrefsSyncMs) < 350) return; // debounce
    _lastPrefsSyncMs = nowMs;

    _prefsSyncInFlight = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedOrder = prefs.getStringList(_kPrefsOrderKey);

      final nextOrder = (storedOrder != null && storedOrder.isNotEmpty)
          ? _normalizePMOrder(storedOrder)
          : List<String>.from(_defaultPMOrder);

      final changed = nextOrder.join('|') != _pmTileOrder.join('|');

      if (!mounted) return;
      if (changed) {
        setState(() => _pmTileOrder = nextOrder);
      }
    } catch (_) {
      // ignore
    } finally {
      _prefsSyncInFlight = false;
    }
  }

  // -----------------------------
  // Order persistence (ONLY Group 2)
  // -----------------------------
  Future<void> _initPMTileOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_kPrefsOrderKey);

      if (stored != null && stored.isNotEmpty) {
        setState(() => _pmTileOrder = _normalizePMOrder(stored));
      } else {
        setState(() => _pmTileOrder = List.from(_defaultPMOrder));
      }
    } catch (_) {
      setState(() => _pmTileOrder = List.from(_defaultPMOrder));
    }
  }

  // (kept for compatibility even if not used by UI)
  void _onPMReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final updated = List<String>.from(_pmTileOrder);
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);

    final normalized = _normalizePMOrder(updated);
    setState(() => _pmTileOrder = normalized);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kPrefsOrderKey, normalized);

    await _syncPrefsFromStorage(force: true);
  }

  // -----------------------------
  // ✅ Terms/Privacy acceptance
  // -----------------------------
  Future<void> _initLegalAcceptance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final t = prefs.getBool(_kAcceptedTermsKey) ?? false;
      final p = prefs.getBool(_kAcceptedPrivacyKey) ?? false;
      setState(() {
        _acceptedTerms = t;
        _acceptedPrivacy = p;
      });
    } catch (_) {
      setState(() {
        _acceptedTerms = false;
        _acceptedPrivacy = false;
      });
    }
  }

  Future<void> _setAcceptedTerms(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAcceptedTermsKey, v);
    if (!mounted) return;
    setState(() => _acceptedTerms = v);
  }

  Future<void> _setAcceptedPrivacy(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAcceptedPrivacyKey, v);
    if (!mounted) return;
    setState(() => _acceptedPrivacy = v);
  }

  // -----------------------------
  // Listing exists for current user (Add / Edit)
  // -----------------------------
  Future<void> _refreshHasListing() async {
    try {
      final userRef = currentUserReference;
      if (userRef == null) {
        setState(() => _hasListing = false);
        return;
      }

      final snap = await FirebaseFirestore.instance
          .collection('subby_listings')
          .where('ownerRef', isEqualTo: userRef)
          .limit(1)
          .get();

      if (!mounted) return;
      setState(() => _hasListing = snap.docs.isNotEmpty);
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasListing = false);
    }
  }

  // -----------------------------
  // Theme accents
  // -----------------------------
  Color _accentForTile(FlutterFlowTheme theme, String id) {
    switch (id) {
      case _tProjects:
        return theme.projectsColour;
      case _tTimeline:
        return theme.timelineColour;
      case _tProjectCost:
        return theme.projectCostColour;
      case _tGetQuotes:
        return theme.getQuotesColour;
      case _tSnag:
        return theme.snagListColour;
      case _tDirectory:
        return theme.primary;
      default:
        return theme.primary;
    }
  }

  // -----------------------------
  // ✅ Welcome header
  // -----------------------------
  Widget _buildWelcomeHeader(FlutterFlowTheme theme) {
    final topInset = MediaQuery.of(context).padding.top;

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
                  color: theme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.home_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to Subby',
                      style: _appTitleStyle(theme).copyWith(
                        color: theme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your home building super power.',
                      style: _appSubtitleStyle(theme),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 1,
            width: double.infinity,
            color: theme.alternate.withOpacity(0.55),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ✅ SECTION
  // ---------------------------------------------------------------------------
  Widget _buildStepSection(
    FlutterFlowTheme theme, {
    required int step,
    required Color accent,
    required String title,
    required String subtitle,
    required Widget child,
    bool showLine = true,
    double topPadding = 0,
    double bottomPadding = 0,
    double? descToChildGap,
  }) {
    final gap = descToChildGap ?? _descToTile;

    return Padding(
      padding: EdgeInsets.fromLTRB(_hPad, topPadding, _hPad, bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _stepHeadlineStyle(theme)),
          const SizedBox(height: _titleToDesc),
          Text(subtitle, style: _stepDescStyle(theme)),
          SizedBox(height: gap),
          child,
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ✅ TILE
  // ---------------------------------------------------------------------------
  Widget _tile({
    required FlutterFlowTheme theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
    int? count,
    double height = _tileH,
    bool showDragHandle = false,
    int dragIndex = 0,
    bool emphasized = false,
    bool grid = false,
  }) {
    final fg = theme.tertiaryText;
    final overlay = Colors.white.withOpacity(0.18);
    final overlayBorder = Colors.white.withOpacity(0.22);

    if (grid) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: Container(
            color: accent,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: overlay,
                          borderRadius: BorderRadius.circular(_radius),
                          border: Border.all(color: overlayBorder),
                        ),
                        child: Icon(icon, size: 22, color: fg),
                      ),
                      const Spacer(),
                      if ((count ?? 0) > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: overlay,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: overlayBorder),
                          ),
                          child: Text(
                            '$count',
                            style: _badgeTextStyle(theme).copyWith(
                              color: fg,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _tileTitleStyle(theme).copyWith(
                      color: fg,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _tileSubtitleStyle(theme).copyWith(
                      color: fg.withOpacity(0.90),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(Icons.chevron_right_rounded, color: fg),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_radius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Container(
          height: height,
          color: accent,
          child: Row(
            children: [
              const SizedBox(width: 12),
              if (showDragHandle) ...[
                ReorderableDragStartListener(
                  index: dragIndex,
                  child: Icon(
                    Icons.drag_handle_rounded,
                    size: 22,
                    color: fg,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Container(
                width: emphasized ? 48 : 44,
                height: emphasized ? 48 : 44,
                decoration: BoxDecoration(
                  color: overlay,
                  borderRadius: BorderRadius.circular(_radius),
                  border: Border.all(color: overlayBorder),
                ),
                child: Icon(
                  icon,
                  size: emphasized ? 24 : 22,
                  color: fg,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: _tileTitleStyle(theme).copyWith(
                          color: fg,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: _tileSubtitleStyle(theme).copyWith(
                          color: fg.withOpacity(0.90),
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              if ((count ?? 0) > 0)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: overlay,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: overlayBorder),
                  ),
                  child: Text(
                    '$count',
                    style: _badgeTextStyle(theme).copyWith(
                      color: fg,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              Icon(Icons.chevron_right_rounded, color: fg),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ✅ Directory tile
  // ---------------------------------------------------------------------------
  Widget _directoryTile({
    required FlutterFlowTheme theme,
    required Color accent,
    required VoidCallback onNavigateDirectory,
    bool emphasized = false,
  }) {
    final fg = theme.tertiaryText;
    final overlay = Colors.white.withOpacity(0.18);
    final overlayBorder = Colors.white.withOpacity(0.22);

    Widget pillButton({
      required String label,
      required VoidCallback onTap,
      IconData? icon,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: overlay,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: overlayBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: theme.labelMedium.override(
                  fontFamily: theme.labelMediumFamily,
                  fontWeight: FontWeight.w900,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: Container(
        color: accent,
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
                      Container(
                        width: emphasized ? 48 : 44,
                        height: emphasized ? 48 : 44,
                        decoration: BoxDecoration(
                          color: overlay,
                          borderRadius: BorderRadius.circular(_radius),
                          border: Border.all(color: overlayBorder),
                        ),
                        child: Icon(
                          Icons.home_work_outlined,
                          size: 22,
                          color: fg,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Directory',
                              style: _tileTitleStyle(theme).copyWith(
                                color: fg,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Find trades, compare options, manage your listing',
                              style: _tileSubtitleStyle(theme).copyWith(
                                color: fg.withOpacity(0.90),
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: fg),
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
      ),
    );
  }

  // -----------------------------
  // Step 1 + Step 2
  // -----------------------------
  Widget _buildStep1And2(FlutterFlowTheme theme) {
    final projectsAccent = _accentForTile(theme, _tProjects);
    final directoryAccent = _accentForTile(theme, _tDirectory);

    return Column(
      children: [
        _buildStepSection(
          theme,
          step: 1,
          accent: projectsAccent,
          title: 'Add your home building projects',
          subtitle:
              'Create a project to store plans, photos, notes & key contacts.',
          showLine: true,
          child: _tile(
            theme: theme,
            title: 'My Projects',
            subtitle: 'Store plans, files, notes & key contacts',
            icon: Icons.folder_open_rounded,
            accent: projectsAccent,
            count: widget.myProjectsCount,
            emphasized: true,
            height: _tileHEmphasis,
            onTap: () => _safeNavigate(
              widget.projectsRouteName,
              fallbackRoute: _fallbackProjectsRoute,
            ),
          ),
        ),
        const SizedBox(height: _sectionBreak),
        _buildStepSection(
          theme,
          step: 2,
          accent: directoryAccent,
          title: 'Find and shortlist trades & suppliers',
          subtitle:
              'Browse the directory, compare options, and add the right pros.',
          showLine: true,
          child: _directoryTile(
            theme: theme,
            accent: directoryAccent,
            emphasized: true,
            onNavigateDirectory: () => _safeNavigate(widget.directoryRouteName),
          ),
        ),
      ],
    );
  }

  // -----------------------------
  // Step 3 (2-column GRID)
  // -----------------------------
  Widget _buildPMSection(FlutterFlowTheme theme) {
    return _buildStepSection(
      theme,
      step: 3,
      accent: theme.timelineColour, // ✅ removed todoColour dependency
      title: 'Manage your build day-by-day',
      subtitle:
          'Track tasks, timeline, budget, quotes & snag items in one place.',
      showLine: false,
      topPadding: _sectionBreak,
      descToChildGap: _pmDescToGrid,
      child: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: LayoutBuilder(
          builder: (context, c) {
            final gridW = c.maxWidth;
            final itemW = (gridW - _betweenTiles) / 2;
            final aspect = itemW / _pmGridTileH;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pmTileOrder.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: _betweenTiles,
                mainAxisSpacing: _betweenTiles,
                childAspectRatio: aspect,
              ),
              itemBuilder: (context, index) {
                final id = _pmTileOrder[index];
                return _buildPMTileByIdGrid(theme, id);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPMTileByIdGrid(FlutterFlowTheme theme, String id) {
    final accent = _accentForTile(theme, id);

    switch (id) {
      case _tTimeline:
        return _tile(
          theme: theme,
          title: 'Timeline',
          subtitle: 'Plan dates & milestones',
          icon: Icons.timeline_rounded,
          accent: accent,
          grid: true,
          onTap: () => _safeNavigate(
            widget.timelineRouteName,
            fallbackRoute: _fallbackTimelineRoute,
          ),
        );

      case _tProjectCost:
        return _tile(
          theme: theme,
          title: 'Project Cost',
          subtitle: 'Budget, quotes & spend tracking',
          icon: Icons.calculate_outlined,
          accent: accent,
          grid: true,
          onTap: () => _safeNavigate(widget.projectCostRouteName),
        );

      case _tGetQuotes:
        return _tile(
          theme: theme,
          title: 'Quotes',
          subtitle: 'Request pricing from pros',
          icon: Icons.request_quote_outlined,
          accent: accent,
          grid: true,
          onTap: () => _safeNavigate(
            widget.getQuotesRouteName,
            fallbackRoute: _fallbackGetQuotesRoute,
          ),
        );

      case _tSnag:
        return _tile(
          theme: theme,
          title: 'Snag List',
          subtitle: 'Capture defects and sign-offs',
          icon: Icons.fact_check_outlined,
          accent: accent,
          count: widget.snagCount,
          grid: true,
          onTap: () => _safeNavigate(widget.snagListRouteName),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // -----------------------------
  // Profile section
  // -----------------------------
  Widget _buildProfileSection(FlutterFlowTheme theme) {
    final email = (currentUserEmail).trim();
    final name = (currentUserDisplayName).trim();

    final displayName = name.isNotEmpty ? name : 'My Profile';
    final subtitle =
        email.isNotEmpty ? email : 'Manage your account & dashboard';

    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 10),
      child: Container(
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: theme.alternate.withOpacity(0.9)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.secondaryBackground,
                    border: Border.all(color: theme.alternate),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: theme.secondaryText,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName, style: _profileNameStyle(theme)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: _profileMetaStyle(theme)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () => _safeNavigate(
                    widget.profileRouteName,
                    fallbackRoute: _fallbackProfileRoute,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: theme.secondaryBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.alternate),
                    ),
                    child: Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                      color: theme.secondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -----------------------------
  // Footer
  // -----------------------------
  Widget _footerMenu(FlutterFlowTheme theme) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    Widget linkRow({
      required String label,
      required IconData icon,
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 18, color: theme.secondaryText),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: _footerRowTextStyle(theme).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.secondaryText,
              ),
            ],
          ),
        ),
      );
    }

    Widget acceptRow({
      required bool value,
      required ValueChanged<bool> onChanged,
      required String label,
    }) {
      final showRequired = !value;

      return Container(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              activeColor: theme.primary,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.bodySmall.override(
                      fontFamily: theme.bodySmallFamily,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryText,
                    ),
                  ),
                  if (showRequired) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 14,
                          color: theme.error,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Not accepted',
                          style: theme.labelSmall.override(
                            fontFamily: theme.labelSmallFamily,
                            fontWeight: FontWeight.w800,
                            color: theme.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(_hPad, 0, _hPad, 18 + bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resources', style: _sectionTitleStyle(theme)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(color: theme.alternate.withOpacity(0.9)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_radius),
              child: Column(
                children: [
                  linkRow(
                    label: 'Terms of Use',
                    icon: Icons.description_outlined,
                    onTap: () => _safeNavigate(
                      widget.termsRouteName,
                      fallbackRoute: _fallbackTermsRoute,
                    ),
                  ),
                  acceptRow(
                    value: _acceptedTerms,
                    onChanged: (v) => _setAcceptedTerms(v),
                    label: 'I accept the Terms of Use',
                  ),
                  Divider(height: 1, color: theme.alternate.withOpacity(0.75)),
                  linkRow(
                    label: 'Privacy Policy',
                    icon: Icons.privacy_tip_outlined,
                    onTap: () => _safeNavigate(
                      widget.privacyRouteName,
                      fallbackRoute: _fallbackPrivacyRoute,
                    ),
                  ),
                  acceptRow(
                    value: _acceptedPrivacy,
                    onChanged: (v) => _setAcceptedPrivacy(v),
                    label: 'I accept the Privacy Policy',
                  ),
                  Divider(height: 1, color: theme.alternate.withOpacity(0.75)),
                  linkRow(
                    label: 'NHBRC & Building Regulations',
                    icon: Icons.rule_outlined,
                    onTap: () async {
                      await launchURL('https://www.nhbrc.org.za');
                    },
                  ),
                  Divider(height: 1, color: theme.alternate.withOpacity(0.75)),
                  linkRow(
                    label: 'Help & Support',
                    icon: Icons.help_outline_rounded,
                    onTap: () => _safeNavigate(
                      widget.supportRouteName,
                      fallbackRoute: _fallbackSupportRoute,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncPrefsFromStorage();
    });

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: theme.primaryBackground,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildWelcomeHeader(theme),
            _buildStep1And2(theme),
            _buildPMSection(theme),
            const SizedBox(height: _gapAfterPM),
            _buildProfileSection(theme),
            _footerMenu(theme),
          ],
        ),
      ),
    );
  }
}
