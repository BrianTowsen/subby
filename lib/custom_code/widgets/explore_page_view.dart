// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExplorePageView extends StatefulWidget {
  const ExplorePageView({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<ExplorePageView> createState() => _ExplorePageViewState();
}

class _ExplorePageViewState extends State<ExplorePageView> {
  static const double _hPad = _pageHPad;
  static const double _vPad = 24;
  static const double _radius = _rLarge;

  // ✅ Shared prefs keys (Home + Explore use same)
  static const String _kProvince = 'subby_app_province';
  static const String _kCity = 'subby_app_city';
  static const String _kCategory = 'subby_app_category';

  // ✅ Saved listing refs field on users/<uid>
  static const String _kSavedField = 'savedListingRefs';

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _province = '';
  String _city = '';
  String _category = '';
  String _speciality = '';

  bool _loadingFilters = true;

  List<String> _provinces = const [];
  List<String> _categories = const [];
  List<String> _specialities = const [];

  List<String> _citiesForSelectedProvince = const [];
  final Map<String, List<String>> _citiesByProvince = {};

  List<String> _specialitiesForSelectedCategory = const [];
  final Map<String, List<String>> _specialitiesByCategory = {};

  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  // less-is-more system · ported from Clutch Putt · lime → yellow.
  // Inline = authoritative for this file. Grep `SUBBY PALETTE (LOCK)` to sync.
  //
  // The filter band + sheet were a saturated brand fill; per the system a
  // saturated band becomes a neutral contained surface, so foreground flips
  // to ink. Yellow (_spark) is reserved for the "Show results" CTA only.
  //
  // Neutrals
  static const Color _ink = Color(0xFF14243F);
  static const Color _inkMute = Color(0xFF6B7280);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFE3E4E8);
  static const Color _hairline = Color(0xFFE3E4E8);
  static const Color _hairlineOnSurface = Color(0xFFD0D2D8);
  // Brand accent — YELLOW. Always ink foreground, never white.
  static const Color _spark = Color(0xFFFFE74C); // primary CTA / ranked accent
  static const Color _sparkInk = Color(0xFF14243F);
  // Status
  static const Color _live = Color(0xFFFFB000); // gold — live / open-now
  static const Color _coral = Color(0xFFC8102E); // legacy red — error
  // Geometry
  static const double _rSmall = 6;
  static const double _rMed = 8;
  static const double _rLarge = 12;
  static const double _rPill = 999;
  static const double _pageHPad = 20;
  static const double _sectionGap = 32;
  static const double _navReserve = 96;
  // Type
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const String _monoFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  // ==========================================================
  // ✅ TYPOGRAPHY (locked palette — explicit family + colour)
  //    Signatures unchanged so all call sites compile as-is.
  // ==========================================================
  TextStyle _appTitleStyle(FlutterFlowTheme theme) => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        height: 1.05,
        color: _ink,
      );

  // used in build() header ("Explore")
  TextStyle _pageTitle(FlutterFlowTheme theme) => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        height: 1.05,
        color: _ink,
      );

  TextStyle _pageSubtitle(FlutterFlowTheme t) => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 13,
        color: _inkMute,
      );

  TextStyle _sectionTitle(FlutterFlowTheme t) => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: _ink,
      );

  TextStyle _filterText(FlutterFlowTheme t, Color color) => TextStyle(
        fontFamily: _bodyFont,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      );

  TextStyle _filterHint(FlutterFlowTheme t, Color color) => TextStyle(
        fontFamily: _bodyFont,
        fontSize: 14,
        color: color,
      );

  TextStyle _searchText(FlutterFlowTheme t) => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 14,
        color: _ink,
      );

  TextStyle _searchHint(FlutterFlowTheme t) => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 14,
        color: _inkMute,
      );

  TextStyle _cardTitle(FlutterFlowTheme t) => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: _ink,
      );

  TextStyle _cardBody(FlutterFlowTheme t) => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 13,
        color: _inkMute,
      );

  TextStyle _chipText(FlutterFlowTheme t) => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _ink,
      );

  TextStyle _snackText(FlutterFlowTheme t) => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 13,
        color: _ink,
      );

  TextStyle get _ratingNumStyle => const TextStyle(
        fontFamily: _monoFont,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: _ink,
        fontFeatures: [FontFeature.tabularFigures()],
      );
  // ==========================================================

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String _s(dynamic v) => (v ?? '').toString().trim();

  String _firstPhotoUrl(dynamic v) {
    if (v is List && v.isNotEmpty) {
      final f = v.first;
      return (f ?? '').toString().trim();
    }
    return '';
  }

  void _showBookmarkSnack({required bool wasSaved}) {
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
            borderRadius: BorderRadius.circular(_rMed),
            side: BorderSide(color: _hairline, width: 1),
          ),
          duration: const Duration(milliseconds: 1400),
          content: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _ink.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  wasSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  size: 16,
                  color: _ink,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  wasSaved ? 'Saved to bookmarks' : 'Removed from bookmarks',
                  style: _snackText(theme),
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ===========================
  // AUTH + SAVED (BOOKMARKS)
  // ===========================
  DocumentReference? _currentUserRefOrNull() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(user.uid);
  }

  Set<String> _savedPathsFromUserDoc(Map<String, dynamic> userData) {
    final v = userData[_kSavedField];
    if (v is List) {
      final refs = v.whereType<DocumentReference>().toList();
      return refs.map((r) => r.path).toSet();
    }
    return <String>{};
  }

  Future<void> _toggleSaved({
    required DocumentReference listingRef,
    required bool isSaved,
  }) async {
    final userRef = _currentUserRefOrNull();
    if (userRef == null) {
      context.pushNamed('loginPage');
      return;
    }

    try {
      await userRef.set(
        {
          _kSavedField: isSaved
              ? FieldValue.arrayRemove([listingRef])
              : FieldValue.arrayUnion([listingRef]),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      _showBookmarkSnack(wasSaved: !isSaved);
    } catch (e) {
      debugPrint('⚠️ toggleSaved failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update bookmark.')),
      );
    }
  }

  Future<void> _persistProvinceCity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kProvince, _province.trim());
      await prefs.setString(_kCity, _city.trim());
    } catch (_) {}
  }

  Future<void> _persistCategory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCategory, _category.trim());
    } catch (_) {}
  }

  Future<void> _clearPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kProvince);
      await prefs.remove(_kCity);
      await prefs.remove(_kCategory);
    } catch (_) {}
  }

  Future<void> _applyPersistedAfterLoad() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prov = (prefs.getString(_kProvince) ?? '').trim();
      final city = (prefs.getString(_kCity) ?? '').trim();
      final cat = (prefs.getString(_kCategory) ?? '').trim();

      if (!mounted) return;

      bool changed = false;

      if (prov.isNotEmpty && _provinces.contains(prov)) {
        _province = prov;
        _citiesForSelectedProvince =
            _citiesByProvince[_province] ?? const <String>[];
        changed = true;
      }

      if (_province.isNotEmpty &&
          city.isNotEmpty &&
          _citiesForSelectedProvince.contains(city)) {
        _city = city;
        changed = true;
      }

      if (cat.isNotEmpty && _categories.contains(cat)) {
        _category = cat;
        _specialitiesForSelectedCategory =
            _specialitiesByCategory[_category] ?? const <String>[];
        if (_specialitiesForSelectedCategory.isEmpty) {
          _specialitiesForSelectedCategory = _specialities;
        }
        if (_speciality.isNotEmpty &&
            !_specialitiesForSelectedCategory.contains(_speciality)) {
          _speciality = '';
        }
        changed = true;
      } else {
        _specialitiesForSelectedCategory = _category.isNotEmpty
            ? (_specialitiesByCategory[_category] ?? const <String>[])
            : _specialities;
        if (_specialitiesForSelectedCategory.isEmpty) {
          _specialitiesForSelectedCategory = _specialities;
        }
      }

      if (changed) setState(() {});
    } catch (_) {}
  }

  Future<void> _loadFilterOptions() async {
    setState(() => _loadingFilters = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('subby_listings')
          .limit(800)
          .get();

      final provSet = <String>{};
      final catSet = <String>{};
      final specSet = <String>{};

      final Map<String, Set<String>> citiesMap = {};
      final Map<String, Set<String>> specsMap = {};

      for (final doc in snap.docs) {
        final d = doc.data();

        final p = _s(d['province']);
        final c = _s(d['city']);
        final ca = _s(d['category']);
        final sp = _s(d['speciality']);

        if (p.isNotEmpty) provSet.add(p);
        if (ca.isNotEmpty) catSet.add(ca);
        if (sp.isNotEmpty) specSet.add(sp);

        if (p.isNotEmpty && c.isNotEmpty) {
          citiesMap.putIfAbsent(p, () => <String>{});
          citiesMap[p]!.add(c);
        }

        if (ca.isNotEmpty && sp.isNotEmpty) {
          specsMap.putIfAbsent(ca, () => <String>{});
          specsMap[ca]!.add(sp);
        }
      }

      final provinces = provSet.toList()..sort();
      final categories = catSet.toList()..sort();
      final specialities = specSet.toList()..sort();

      _citiesByProvince.clear();
      for (final entry in citiesMap.entries) {
        final list = entry.value.toList()..sort();
        _citiesByProvince[entry.key] = list;
      }

      _specialitiesByCategory.clear();
      for (final entry in specsMap.entries) {
        final list = entry.value.toList()..sort();
        _specialitiesByCategory[entry.key] = list;
      }

      var filteredSpecs = _category.isNotEmpty
          ? (_specialitiesByCategory[_category] ?? const <String>[])
          : specialities;

      // ✅ Safety fallback (prevents empty speciality dropdown)
      if (filteredSpecs.isEmpty) filteredSpecs = specialities;

      if (!mounted) return;
      setState(() {
        _provinces = provinces;
        _categories = categories;
        _specialities = specialities;

        _citiesForSelectedProvince = _province.isNotEmpty
            ? (_citiesByProvince[_province] ?? const [])
            : const [];

        _specialitiesForSelectedCategory = filteredSpecs;

        if (_speciality.isNotEmpty &&
            !_specialitiesForSelectedCategory.contains(_speciality)) {
          _speciality = '';
        }

        _loadingFilters = false;
      });

      // ✅ Apply persisted Home state AFTER lists exist
      await _applyPersistedAfterLoad();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _provinces = const [];
        _categories = const [];
        _specialities = const [];
        _citiesForSelectedProvince = const [];
        _citiesByProvince.clear();

        _specialitiesForSelectedCategory = const [];
        _specialitiesByCategory.clear();

        _loadingFilters = false;
      });
    }
  }

  void _clearFilters() async {
    setState(() {
      _province = '';
      _city = '';
      _category = '';
      _speciality = '';
      _searchController.clear();
      _citiesForSelectedProvince = const [];
      _specialitiesForSelectedCategory = _specialities;
    });

    await _clearPersisted();
    _searchFocusNode.unfocus();
  }

  void _onProvinceChanged(String v) async {
    final nextProvince = v.trim();
    final nextCities = nextProvince.isNotEmpty
        ? (_citiesByProvince[nextProvince] ?? const <String>[])
        : const <String>[];

    setState(() {
      _province = nextProvince;
      _citiesForSelectedProvince = nextCities;

      if (_city.isNotEmpty && !nextCities.contains(_city)) {
        _city = '';
      }
    });

    await _persistProvinceCity();
  }

  void _onCategoryChanged(String v) async {
    final nextCategory = v.trim();
    var nextSpecs = nextCategory.isNotEmpty
        ? (_specialitiesByCategory[nextCategory] ?? const <String>[])
        : _specialities;

    // ✅ Safety fallback (prevents empty speciality dropdown)
    if (nextSpecs.isEmpty) nextSpecs = _specialities;

    setState(() {
      _category = nextCategory;
      _specialitiesForSelectedCategory = nextSpecs;

      if (_speciality.isNotEmpty && !nextSpecs.contains(_speciality)) {
        _speciality = '';
      }
    });

    await _persistCategory();
  }

  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> q =
        FirebaseFirestore.instance.collection('subby_listings');

    final p = _province.trim();
    final c = _city.trim();
    final cat = _category.trim();
    final sp = _speciality.trim();

    if (p.isNotEmpty) q = q.where('province', isEqualTo: p);
    if (c.isNotEmpty) q = q.where('city', isEqualTo: c);
    if (cat.isNotEmpty) q = q.where('category', isEqualTo: cat);
    if (sp.isNotEmpty) q = q.where('speciality', isEqualTo: sp);

    return q;
  }

  /// ✅ Filter dropdown row (THEME TOKEN ONLY)
  Widget _plainWhiteDropdown({
    required String hint,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    bool enabled = true,
  }) {
    final theme = FlutterFlowTheme.of(context);
    final onPrimary = _ink;

    final showHint = value.trim().isEmpty;
    final effectiveValue = showHint ? null : value;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Row(
        children: [
          Icon(icon, size: 18, color: onPrimary),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: effectiveValue,
                isExpanded: true,
                dropdownColor: _paper, // _paper popup
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: onPrimary),
                style: _filterText(theme, onPrimary),
                hint: Text(
                  hint,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: _filterHint(theme, onPrimary.withOpacity(0.85)),
                ),
                items: items.map((s) {
                  return DropdownMenuItem<String>(
                    value: s,
                    child: Text(
                      s,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: _filterText(theme, onPrimary),
                    ),
                  );
                }).toList(),
                onChanged: enabled ? onChanged : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _whitePillSearch({bool autoFocus = false}) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).requestFocus(_searchFocusNode),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _hairline, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Icon(Icons.search, color: _inkMute),
            const SizedBox(width: 8),
            Expanded(
              child: Theme(
                data: Theme.of(context).copyWith(
                  textSelectionTheme: TextSelectionThemeData(
                    cursorColor: _ink,
                    selectionColor: _ink.withOpacity(0.22),
                    selectionHandleColor: _ink,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  autofocus: autoFocus,
                  cursorColor: _ink,
                  onTap: () =>
                      FocusScope.of(context).requestFocus(_searchFocusNode),
                  style: _searchText(theme).copyWith(
                    color: _ink,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: 'Search for a trade, contractor or supplier',
                    hintStyle: _searchHint(theme),
                  ),
                  textInputAction: TextInputAction.search,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.clear, size: 20, color: _inkMute),
              onPressed: () {
                _searchController.clear();
                FocusScope.of(context).requestFocus(_searchFocusNode);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _expandedFilterContent() {
    final theme = FlutterFlowTheme.of(context);
    final onPrimary = _ink;

    if (_loadingFilters) {
      return Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: onPrimary),
          ),
          const SizedBox(width: 10),
          Text('Loading filters…', style: _filterText(theme, onPrimary)),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _plainWhiteDropdown(
                hint: 'Select province',
                value: _province,
                items: _provinces,
                icon: Icons.location_on_outlined,
                onChanged: (v) {
                  if (v == null) return;
                  _onProvinceChanged(v);
                },
              ),
            ),
            Container(
              width: 1,
              height: 22,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: onPrimary.withOpacity(0.25),
            ),
            Expanded(
              child: _plainWhiteDropdown(
                hint:
                    _province.isEmpty ? 'Select province first' : 'Select city',
                value: _city,
                items: _citiesForSelectedProvince,
                icon: Icons.place_outlined,
                enabled: _province.isNotEmpty,
                onChanged: (v) async {
                  if (v == null) return;
                  setState(() => _city = v);
                  await _persistProvinceCity();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _whitePillSearch(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _plainWhiteDropdown(
                hint: 'Category',
                value: _category,
                items: _categories,
                icon: Icons.category_outlined,
                onChanged: (v) {
                  if (v == null) return;
                  _onCategoryChanged(v);
                },
              ),
            ),
            Container(
              width: 1,
              height: 22,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: onPrimary.withOpacity(0.25),
            ),
            Expanded(
              child: _plainWhiteDropdown(
                hint: _category.isEmpty
                    ? 'Speciality'
                    : 'Speciality (${_specialitiesForSelectedCategory.length})',
                value: _speciality,
                items: _category.isEmpty
                    ? _specialities
                    : _specialitiesForSelectedCategory,
                icon: Icons.handyman_outlined,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _speciality = v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: _clearFilters,
            child: Text(
              'Clear filters',
              style: theme.bodySmall.override(
                fontFamily: theme.bodySmallFamily,
                color: onPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _filtersSummary() {
    final parts = <String>[];
    if (_province.trim().isNotEmpty) parts.add(_province.trim());
    if (_city.trim().isNotEmpty) parts.add(_city.trim());
    if (_category.trim().isNotEmpty) parts.add(_category.trim());
    if (_speciality.trim().isNotEmpty) parts.add(_speciality.trim());
    return parts.isEmpty ? 'No filters selected' : parts.join(' • ');
  }

  void _openFiltersSheet() {
    final theme = FlutterFlowTheme.of(context);
    final onPrimary = _ink;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface, // _surface
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(_rLarge)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void sync(VoidCallback fn) {
              if (mounted) setState(fn);
              setModalState(() {});
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: _hPad,
                  right: _hPad,
                  top: 14,
                  bottom: 14 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: onPrimary.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text(
                            'Filters',
                            style: theme.titleMedium.override(
                              fontFamily: theme.titleMediumFamily,
                              color: onPrimary,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close_rounded, color: onPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_loadingFilters)
                        Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: onPrimary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Loading filters…',
                              style: _filterText(theme, onPrimary),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _plainWhiteDropdown(
                                    hint: 'Select province',
                                    value: _province,
                                    items: _provinces,
                                    icon: Icons.location_on_outlined,
                                    onChanged: (v) {
                                      if (v == null) return;
                                      _onProvinceChanged(v);
                                      setModalState(() {});
                                    },
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 22,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  color: onPrimary.withOpacity(0.25),
                                ),
                                Expanded(
                                  child: _plainWhiteDropdown(
                                    hint: _province.isEmpty
                                        ? 'Select province first'
                                        : 'Select city',
                                    value: _city,
                                    items: _citiesForSelectedProvince,
                                    icon: Icons.place_outlined,
                                    enabled: _province.isNotEmpty,
                                    onChanged: (v) async {
                                      if (v == null) return;
                                      sync(() => _city = v);
                                      await _persistProvinceCity();
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _whitePillSearch(autoFocus: false),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _plainWhiteDropdown(
                                    hint: 'Category',
                                    value: _category,
                                    items: _categories,
                                    icon: Icons.category_outlined,
                                    onChanged: (v) {
                                      if (v == null) return;
                                      _onCategoryChanged(v);
                                      setModalState(() {});
                                    },
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 22,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  color: onPrimary.withOpacity(0.25),
                                ),
                                Expanded(
                                  child: _plainWhiteDropdown(
                                    hint: _category.isEmpty
                                        ? 'Speciality'
                                        : 'Speciality (${_specialitiesForSelectedCategory.length})',
                                    value: _speciality,
                                    items: _category.isEmpty
                                        ? _specialities
                                        : _specialitiesForSelectedCategory,
                                    icon: Icons.handyman_outlined,
                                    onChanged: (v) {
                                      if (v == null) return;
                                      sync(() => _speciality = v);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () => sync(_clearFilters),
                                child: Text(
                                  'Clear filters',
                                  style: theme.bodySmall.override(
                                    fontFamily: theme.bodySmallFamily,
                                    color: onPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _spark,
                            foregroundColor: _ink,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(_rMed),
                            ),
                          ),
                          child: Text(
                            'Show results',
                            style: _searchText(theme).copyWith(
                              fontWeight: FontWeight.w700,
                              color: _sparkInk,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _titleFrom(Map<String, dynamic> d) {
    return _s(d['listingName']).isNotEmpty
        ? _s(d['listingName'])
        : _s(d['name']).isNotEmpty
            ? _s(d['name'])
            : _s(d['title']).isNotEmpty
                ? _s(d['title'])
                : _s(d['company']).isNotEmpty
                    ? _s(d['company'])
                    : 'Listing';
  }

  String _subtitleFrom(Map<String, dynamic> d) {
    final addr = _s(d['address']);
    final suburb = _s(d['suburb']);
    final city = _s(d['city']);
    final prov = _s(d['province']);

    final parts = <String>[
      if (addr.isNotEmpty) addr,
      if (suburb.isNotEmpty) suburb,
      if (city.isNotEmpty) city,
      if (prov.isNotEmpty) prov,
    ];
    return parts.isEmpty ? '' : parts.join(' • ');
  }

  String _chipFrom(Map<String, dynamic> d) {
    final c = _s(d['category']);
    final s = _s(d['speciality']);
    if (c.isEmpty && s.isEmpty) return '';
    if (c.isNotEmpty && s.isNotEmpty) return '$c • $s';
    return c.isNotEmpty ? c : s;
  }

  double? _ratingFrom(Map<String, dynamic> d) {
    final r = d['rating'];
    if (r is num) {
      final v = r.toDouble();
      return v > 0 ? v : null;
    }
    final rs = _s(r);
    final parsed = rs.isEmpty ? null : double.tryParse(rs);
    return (parsed != null && parsed > 0) ? parsed : null;
  }

  void _openListing(DocumentReference ref) {
    context.pushNamed(
      'listingDetailPage',
      queryParameters: {
        'listingRef': serializeParam(ref, ParamType.DocumentReference),
      }.withoutNulls,
    );
  }

  int _headerRebuildToken() {
    return Object.hash(
      _loadingFilters,
      _province,
      _city,
      _category,
      _speciality,
      _searchController.text,
      _citiesForSelectedProvince.length,
      _specialitiesForSelectedCategory.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    final double width = widget.width ?? MediaQuery.sizeOf(context).width;
    final double height = widget.height ?? MediaQuery.sizeOf(context).height;

    // ✅ Remove SafeArea white bands: respect insets manually
    final insets = MediaQuery.of(context).padding;
    final topInset = insets.top;
    final bottomInset = insets.bottom;

    final headerMaxHeight = _loadingFilters ? 96.0 : 232.0;
    const headerMinHeight = 96.0;

    // ✅ Stream saved refs (once) and use across the list
    final userRef = _currentUserRefOrNull();

    return MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: SizedBox(
        width: width,
        height: height,
        child: Container(
          color: _paper,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      _hPad,
                      topInset + _vPad,
                      _hPad,
                      12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _ink, // _ink mark
                            borderRadius: BorderRadius.circular(_rMed),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: _paper,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Explore', style: _pageTitle(theme)),
                            const SizedBox(height: 2),
                            Text(
                              'Find contractors near you',
                              style: _pageSubtitle(theme),
                            ),
                          ],
                        ),
                        // ✅ Profile icon/link removed
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _ExploreFilterHeaderDelegate(
                    rebuildToken: _headerRebuildToken(),
                    hPad: _hPad,
                    minExtentHeight: headerMinHeight,
                    maxExtentHeight: headerMaxHeight,
                    buildExpanded: _expandedFilterContent,
                    buildCollapsed: () {
                      final t = FlutterFlowTheme.of(context);
                      final onPrimary = _ink;
                      return Row(
                        children: [
                          Expanded(child: _whitePillSearch()),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: _openFiltersSheet,
                            borderRadius: BorderRadius.circular(_rMed),
                            child: Container(
                              height: 46,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: onPrimary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(_rMed),
                                border: Border.all(
                                  color: onPrimary.withOpacity(0.18),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.tune_rounded,
                                      color: onPrimary, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Filters',
                                    style: t.titleMedium.override(
                                      fontFamily: t.titleMediumFamily,
                                      color: onPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    summaryText: _filtersSummary,
                    onTapSummary: _openFiltersSheet,
                    onClear: _clearFilters,
                    isLoading: () => _loadingFilters,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _hPad),
                    child: Text('Listings', style: _sectionTitle(theme)),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
              ];
            },
            body: StreamBuilder<DocumentSnapshot>(
              stream: userRef?.snapshots(),
              builder: (context, userSnap) {
                final userData =
                    (userSnap.data?.data() as Map<String, dynamic>?) ??
                        <String, dynamic>{};
                final savedPaths = _savedPathsFromUserDoc(userData);

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _buildQuery().snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return Center(
                        child: CircularProgressIndicator(color: _ink),
                      );
                    }

                    var docs = snap.data!.docs;

                    final q = _searchController.text.trim().toLowerCase();
                    if (q.isNotEmpty) {
                      docs = docs.where((d) {
                        final data = d.data();
                        final title = _titleFrom(data).toLowerCase();
                        final cat = _s(data['category']).toLowerCase();
                        final spec = _s(data['speciality']).toLowerCase();
                        final city = _s(data['city']).toLowerCase();
                        return title.contains(q) ||
                            cat.contains(q) ||
                            spec.contains(q) ||
                            city.contains(q);
                      }).toList();
                    }

                    if (docs.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          18,
                          18,
                          18,
                          bottomInset + 18,
                        ),
                        child: Center(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(_rLarge),
                              border: Border.all(color: _hairline),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off,
                                    color: _inkMute, size: 34),
                                const SizedBox(height: 10),
                                Text(
                                  'No listings found',
                                  style: _sectionTitle(theme),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Try clearing filters or searching a different keyword.',
                                  style: _cardBody(theme),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        24,
                        0,
                        24,
                        bottomInset + 110,
                      ),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final doc = docs[i];
                        final data = doc.data();

                        final title = _titleFrom(data);
                        final subtitle = _subtitleFrom(data);
                        final chip = _chipFrom(data);
                        final rating = _ratingFrom(data);

                        final img = _s(data['heroPhotoUrl']).isNotEmpty
                            ? _s(data['heroPhotoUrl'])
                            : _firstPhotoUrl(data['photoUrls']).isNotEmpty
                                ? _firstPhotoUrl(data['photoUrls'])
                                : _s(data['photoUrl']).isNotEmpty
                                    ? _s(data['photoUrl'])
                                    : _s(data['photo_url']).isNotEmpty
                                        ? _s(data['photo_url'])
                                        : _s(data['imageUrl']).isNotEmpty
                                            ? _s(data['imageUrl'])
                                            : _s(data['image_url']);

                        final listingRef = doc.reference;
                        final isSaved = savedPaths.contains(listingRef.path);

                        return InkWell(
                          onTap: () => _openListing(listingRef),
                          borderRadius: BorderRadius.circular(_radius),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _paper,
                              borderRadius: BorderRadius.circular(_radius),
                              border: Border.all(color: _hairline, width: 1),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 86,
                                  height: 86,
                                  margin: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(_rMed),
                                    color: _surface,
                                    border:
                                        Border.all(color: _hairline, width: 1),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: img.isNotEmpty
                                      ? Image.network(
                                          img,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(
                                            Icons.image_not_supported_outlined,
                                            color: _inkMute,
                                          ),
                                        )
                                      : Icon(Icons.image_outlined,
                                          color: _inkMute),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        0, 12, 12, 12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: _cardTitle(theme),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (rating != null)
                                              Row(
                                                children: [
                                                  Icon(Icons.star_rounded,
                                                      size: 18, color: _ink),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    rating.toStringAsFixed(1),
                                                    style: _ratingNumStyle,
                                                  ),
                                                ],
                                              ),
                                            const SizedBox(width: 6),
                                            InkWell(
                                              onTap: () async {
                                                await _toggleSaved(
                                                  listingRef: listingRef,
                                                  isSaved: isSaved,
                                                );
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              child: Container(
                                                width: 34,
                                                height: 34,
                                                decoration: BoxDecoration(
                                                  color: _surface,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: _hairline,
                                                    width: 1,
                                                  ),
                                                ),
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  isSaved
                                                      ? Icons.bookmark_rounded
                                                      : Icons
                                                          .bookmark_border_rounded,
                                                  size: 18,
                                                  color:
                                                      isSaved ? _ink : _inkMute,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (chip.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: _surface,
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              border: Border.all(
                                                  color: _hairline, width: 1),
                                            ),
                                            child: Text(
                                              chip,
                                              style: _chipText(theme),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                        if (subtitle.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            subtitle,
                                            style: _cardBody(theme),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ExploreFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  // This is a separate class, so it can't see the palette consts that live as
  // static members of _ExplorePageViewState — give it its own copies.
  static const Color _ink = Color(0xFF14243F);
  static const Color _surface = Color(0xFFE3E4E8);

  _ExploreFilterHeaderDelegate({
    required this.rebuildToken,
    required this.hPad,
    required this.minExtentHeight,
    required this.maxExtentHeight,
    required this.buildExpanded,
    required this.buildCollapsed,
    required this.summaryText,
    required this.onTapSummary,
    required this.onClear,
    required this.isLoading,
  });

  final int rebuildToken;
  final double hPad;
  final double minExtentHeight;
  final double maxExtentHeight;

  final Widget Function() buildExpanded;
  final Widget Function() buildCollapsed;

  final String Function() summaryText;
  final VoidCallback onTapSummary;
  final VoidCallback onClear;
  final bool Function() isLoading;

  @override
  double get minExtent => minExtentHeight;

  @override
  double get maxExtent => maxExtentHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = FlutterFlowTheme.of(context);

    final range = (maxExtent - minExtent).clamp(1.0, 9999.0);
    final t = (shrinkOffset / range).clamp(0.0, 1.0);

    final showExpanded = t < 0.55;
    final showCollapsed = t > 0.10;

    return Container(
      color: _surface, // _surface contained block
      padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 12),
      child: ClipRect(
        child: Stack(
          children: [
            if (showExpanded)
              Opacity(
                opacity: (1.0 - (t * 1.15)).clamp(0.0, 1.0),
                child: IgnorePointer(
                  ignoring: t > 0.35,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: buildExpanded(),
                  ),
                ),
              ),
            if (showCollapsed)
              Opacity(
                opacity: ((t - 0.10) * 1.25).clamp(0.0, 1.0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildCollapsed(),
                      const SizedBox(height: 8),
                      if (!isLoading())
                        GestureDetector(
                          onTap: onTapSummary,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  summaryText(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.bodySmall.override(
                                    fontFamily: theme.bodySmallFamily,
                                    color: _ink,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: onClear,
                                child: Text(
                                  'Clear',
                                  style: theme.bodySmall.override(
                                    fontFamily: theme.bodySmallFamily,
                                    color: _ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
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

  @override
  bool shouldRebuild(covariant _ExploreFilterHeaderDelegate oldDelegate) {
    return oldDelegate.rebuildToken != rebuildToken ||
        oldDelegate.maxExtentHeight != maxExtentHeight ||
        oldDelegate.minExtentHeight != minExtentHeight;
  }
}
