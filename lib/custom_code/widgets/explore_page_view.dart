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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExplorePageView extends StatefulWidget {
  const ExplorePageView({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<ExplorePageView> createState() => _ExplorePageViewState();
}

class _ExplorePageViewState extends State<ExplorePageView> {
  // ─── SUBBY PALETTE — DIRECTORY (Get-Quotes system) ─────────────────
  static const Color _ink = Color(0xFF1E282E);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _steel = Color(0xFF3A5966);
  static const Color _lime = Color(0xFFE7E247);
  static const Color _slate = Color(0xFF5D737E);
  static const Color _hairline = Color(0xFFEAEEF0);
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const double _hPad = 22;

  static const String _kProvince = 'subby_app_province';
  static const String _kCity = 'subby_app_city';
  static const String _kCategory = 'subby_app_category';
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
    if (v is List && v.isNotEmpty) return (v.first ?? '').toString().trim();
    return '';
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
      return v.whereType<DocumentReference>().map((r) => r.path).toSet();
    }
    return <String>{};
  }

  void _showBookmarkSnack({required bool wasSaved}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        backgroundColor: _ink,
        content: Text(
            wasSaved ? 'Saved to bookmarks' : 'Removed from bookmarks',
            style: const TextStyle(
                fontFamily: _bodyFont,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        duration: const Duration(milliseconds: 1400),
      ));
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
          const SnackBar(content: Text('Could not update bookmark.')));
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
          citiesMap.putIfAbsent(p, () => <String>{}).add(c);
        }
        if (ca.isNotEmpty && sp.isNotEmpty) {
          specsMap.putIfAbsent(ca, () => <String>{}).add(sp);
        }
      }

      final provinces = provSet.toList()..sort();
      final categories = catSet.toList()..sort();
      final specialities = specSet.toList()..sort();

      _citiesByProvince.clear();
      for (final entry in citiesMap.entries) {
        _citiesByProvince[entry.key] = entry.value.toList()..sort();
      }
      _specialitiesByCategory.clear();
      for (final entry in specsMap.entries) {
        _specialitiesByCategory[entry.key] = entry.value.toList()..sort();
      }

      var filteredSpecs = _category.isNotEmpty
          ? (_specialitiesByCategory[_category] ?? const <String>[])
          : specialities;
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
      if (_city.isNotEmpty && !nextCities.contains(_city)) _city = '';
    });
    await _persistProvinceCity();
  }

  void _onCategoryChanged(String v) async {
    final nextCategory = v.trim();
    var nextSpecs = nextCategory.isNotEmpty
        ? (_specialitiesByCategory[nextCategory] ?? const <String>[])
        : _specialities;
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

  String _titleFrom(Map<String, dynamic> d) => _s(d['listingName']).isNotEmpty
      ? _s(d['listingName'])
      : _s(d['name']).isNotEmpty
          ? _s(d['name'])
          : _s(d['title']).isNotEmpty
              ? _s(d['title'])
              : _s(d['company']).isNotEmpty
                  ? _s(d['company'])
                  : 'Listing';

  String _subtitleFrom(Map<String, dynamic> d) {
    final parts = <String>[
      if (_s(d['suburb']).isNotEmpty) _s(d['suburb']),
      if (_s(d['city']).isNotEmpty) _s(d['city']),
      if (_s(d['province']).isNotEmpty) _s(d['province']),
    ];
    return parts.isEmpty ? '' : parts.join(' • ');
  }

  double? _ratingFrom(Map<String, dynamic> d) {
    final r = d['rating'];
    if (r is num) return r.toDouble() > 0 ? r.toDouble() : null;
    final parsed = double.tryParse(_s(r));
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

  Future<String?> _pickFromSheet(
      String title, List<String> items, String current,
      {String allLabel = 'Any'}) {
    final options = <String>[allLabel, ...items];
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: _paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
              child: Text(title,
                  style: const TextStyle(
                    fontFamily: _displayFont,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: _ink,
                  )),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: options.map((e) {
                  final isAll = e == allLabel;
                  final selected = isAll ? current.isEmpty : e == current;
                  return InkWell(
                    onTap: () => Navigator.of(ctx).pop(isAll ? '' : e),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFF3F6F7)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Text(e,
                              style: TextStyle(
                                fontFamily: _bodyFont,
                                fontSize: 16,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: selected ? _ink : _inkMute,
                              )),
                        ),
                        if (selected)
                          const Icon(Icons.check_circle_rounded,
                              color: _ink, size: 20),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = widget.width ?? MediaQuery.sizeOf(context).width;
    final double height = widget.height ?? MediaQuery.sizeOf(context).height;
    final double topInset = MediaQuery.of(context).padding.top;

    final userRef = _currentUserRefOrNull();
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        color: _steel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _masthead(topInset),
            Expanded(
              child: Container(
                color: _paper,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(_hPad, 22, _hPad, 0),
                        child: _loadingFilters
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Row(children: [
                                  SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: _ink)),
                                  SizedBox(width: 10),
                                  Text('Loading filters…',
                                      style: TextStyle(
                                          fontFamily: _bodyFont,
                                          fontSize: 14,
                                          color: _inkMute)),
                                ]),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _uLabel('FILTERS'),
                                  const SizedBox(height: 10),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: _paper,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: _hairline),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Column(children: [
                                      _selectRow(
                                        icon: Icons.location_on_outlined,
                                        label: 'Province',
                                        value: _province,
                                        hint: 'Any province',
                                        divider: true,
                                        onTap: () async {
                                          final v = await _pickFromSheet(
                                              'Province', _provinces, _province,
                                              allLabel: 'Any province');
                                          if (v != null) _onProvinceChanged(v);
                                        },
                                      ),
                                      _selectRow(
                                        icon: Icons.category_outlined,
                                        label: 'Category',
                                        value: _category,
                                        hint: 'Any category',
                                        onTap: () async {
                                          final v = await _pickFromSheet(
                                              'Category',
                                              _categories,
                                              _category,
                                              allLabel: 'Any category');
                                          if (v != null) _onCategoryChanged(v);
                                        },
                                      ),
                                    ]),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 13),
                                    decoration: BoxDecoration(
                                      color: _paper,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: _hairline),
                                    ),
                                    child: Row(children: [
                                      const Icon(Icons.search,
                                          size: 20, color: _slate),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextField(
                                          controller: _searchController,
                                          focusNode: _searchFocusNode,
                                          cursorColor: _ink,
                                          style: const TextStyle(
                                              fontFamily: _bodyFont,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: _ink),
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.zero,
                                            hintText: 'Trade, contractor…',
                                            hintStyle: TextStyle(
                                                fontFamily: _bodyFont,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: _faint),
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: _clearFilters,
                                        child: const Text('Clear',
                                            style: TextStyle(
                                                fontFamily: _bodyFont,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: _slate)),
                                      ),
                                    ]),
                                  ),
                                  const SizedBox(height: 22),
                                  _uLabel('LISTINGS'),
                                  const SizedBox(height: 10),
                                ],
                              ),
                      ),
                    ),
                    StreamBuilder<DocumentSnapshot>(
                      stream: userRef?.snapshots(),
                      builder: (context, userSnap) {
                        final userData =
                            (userSnap.data?.data() as Map<String, dynamic>?) ??
                                <String, dynamic>{};
                        final savedPaths = _savedPathsFromUserDoc(userData);

                        return StreamBuilder<
                            QuerySnapshot<Map<String, dynamic>>>(
                          stream: _buildQuery().snapshots(),
                          builder: (context, snap) {
                            if (!snap.hasData) {
                              return const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.all(40),
                                  child: Center(
                                      child: CircularProgressIndicator(
                                          color: _ink)),
                                ),
                              );
                            }
                            var docs = snap.data!.docs;
                            final q =
                                _searchController.text.trim().toLowerCase();
                            if (q.isNotEmpty) {
                              docs = docs.where((d) {
                                final data = d.data();
                                return _titleFrom(data)
                                        .toLowerCase()
                                        .contains(q) ||
                                    _s(data['category'])
                                        .toLowerCase()
                                        .contains(q) ||
                                    _s(data['speciality'])
                                        .toLowerCase()
                                        .contains(q) ||
                                    _s(data['city']).toLowerCase().contains(q);
                              }).toList();
                            }
                            if (docs.isEmpty) {
                              return const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(24, 30, 24, 30),
                                  child: Column(children: [
                                    Icon(Icons.search_off_rounded,
                                        color: _faint, size: 40),
                                    SizedBox(height: 12),
                                    Text('No listings found',
                                        style: TextStyle(
                                            fontFamily: _displayFont,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: _ink)),
                                  ]),
                                ),
                              );
                            }
                            return SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                  _hPad, 0, _hPad, bottomInset + 24),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, i) {
                                    final doc = docs[i];
                                    final data = doc.data();
                                    final img =
                                        _s(data['heroPhotoUrl']).isNotEmpty
                                            ? _s(data['heroPhotoUrl'])
                                            : _firstPhotoUrl(data['photoUrls']);
                                    final listingRef = doc.reference;
                                    final isSaved =
                                        savedPaths.contains(listingRef.path);
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: _listingCard(
                                        title: _titleFrom(data),
                                        category: _s(data['category']),
                                        speciality: _s(data['speciality']),
                                        subtitle: _subtitleFrom(data),
                                        rating: _ratingFrom(data),
                                        img: img,
                                        isVerified: data['isVerified'] == true,
                                        isSaved: isSaved,
                                        onTap: () => _openListing(listingRef),
                                        onToggleSaved: () => _toggleSaved(
                                          listingRef: listingRef,
                                          isSaved: isSaved,
                                        ),
                                      ),
                                    );
                                  },
                                  childCount: docs.length,
                                ),
                              ),
                            );
                          },
                        );
                      },
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

  // =========================================================
  // UI helpers
  // =========================================================
  Widget _uLabel(String text) => Text(text,
      style: const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: _inkMute,
      ));

  Widget _masthead(double topInset) => Container(
        width: double.infinity,
        color: _steel,
        padding: EdgeInsets.fromLTRB(_hPad, topInset + 10, _hPad, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _circleButton(
                  Icons.arrow_back_ios_new_rounded, () => context.safePop()),
              Expanded(
                child: Center(
                  child: Text('EXPLORE',
                      style: TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: _paper.withOpacity(0.5),
                      )),
                ),
              ),
              const SizedBox(width: 38),
            ]),
            const SizedBox(height: 14),
            const Text('Explore',
                style: TextStyle(
                  fontFamily: _displayFont,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                  height: 1.08,
                  color: _paper,
                )),
            const SizedBox(height: 8),
            Text('Filter contractors near you.',
                style: TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _paper.withOpacity(0.55),
                )),
          ],
        ),
      );

  Widget _listingCard({
    required String title,
    required String category,
    required String speciality,
    required String subtitle,
    required double? rating,
    required String img,
    required bool isVerified,
    required bool isSaved,
    required VoidCallback onTap,
    required VoidCallback onToggleSaved,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _hairline),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 52,
            height: 52,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
                color: _surface, borderRadius: BorderRadius.circular(11)),
            child: img.isNotEmpty
                ? Image.network(img,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_not_supported_outlined,
                        color: _faint))
                : const Icon(Icons.handyman_rounded, color: _slate),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: _displayFont,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: _ink)),
                  ),
                  if (isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded, size: 15, color: _slate),
                  ],
                  const Spacer(),
                  if (rating != null) ...[
                    const Icon(Icons.star_rounded, size: 16, color: _slate),
                    const SizedBox(width: 3),
                    Text(rating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _ink)),
                  ],
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onToggleSaved,
                    customBorder: const CircleBorder(),
                    child: Icon(
                        isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 20,
                        color: isSaved ? _slate : const Color(0xFFC6D0D5)),
                  ),
                ]),
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  if (category.isNotEmpty) _pill(category),
                  if (speciality.isNotEmpty) _pill(speciality),
                ]),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: _faint),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: _bodyFont,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _faint)),
                    ),
                  ]),
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: _surface, borderRadius: BorderRadius.circular(999)),
        child: Text(text,
            style: const TextStyle(
                fontFamily: _bodyFont,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _inkMute)),
      );

  Widget _selectRow({
    required IconData icon,
    required String label,
    required String value,
    required String hint,
    required VoidCallback onTap,
    bool divider = false,
  }) {
    final empty = value.trim().isEmpty;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: divider
              ? const Border(bottom: BorderSide(color: _hairline))
              : null,
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: _slate),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _faint)),
                const SizedBox(height: 1),
                Text(empty ? hint : value,
                    style: TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 15,
                        fontWeight: empty ? FontWeight.w600 : FontWeight.w700,
                        color: empty ? _faint : _ink)),
              ],
            ),
          ),
          const Icon(Icons.expand_more_rounded, color: _faint),
        ]),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: _paper.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: _paper),
          ),
        ),
      );
}
