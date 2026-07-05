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
  // ─── SUBBY PALETTE — DIRECTORY (amber / sunshine) ──────────────────
  static const Color _amber = Color(0xFF29343A); // accent
  static const Color _inkMute = Color(0xFF566670); // labels
  static const Color _faint = Color(0xFF93A3AC); // subtitles / meta
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _orange = Color(
      0xFF5D737E); // DS green: leading icons / active bookmark (was orange #EB7A02)
  static const Color _green = Color(0xFF5D737E); // DS: verified / info
  static const Color _gold = Color(0xFF5D737E); // DS: rating stars
  static const Color _hairline = Color(0xFFEAEEF0);
  static const Color _rule = Color(0xFFDCE3E6);
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const double _hPad = 24;
  static const double _vPad = 14;

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

  TextStyle get _titleStyle => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 30,
        fontWeight: FontWeight.w900,
        color: _amber,
        height: 1.05,
      );

  TextStyle get _subtitleStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _faint,
      );

  TextStyle get _uLabelStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: _inkMute,
      );

  TextStyle get _valueStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: _amber,
      );

  TextStyle get _hintStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF93A3AC),
      );

  static const BoxDecoration _uRule = BoxDecoration(
    border: Border(bottom: BorderSide(color: _rule, width: 1)),
  );

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

  void _showBookmarkSnack({required bool wasSaved}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          backgroundColor: _amber,
          content: Text(
            wasSaved ? 'Saved to bookmarks' : 'Removed from bookmarks',
            style: const TextStyle(
              fontFamily: _bodyFont,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          duration: const Duration(milliseconds: 1400),
        ),
      );
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
    final suburb = _s(d['suburb']);
    final city = _s(d['city']);
    final prov = _s(d['province']);
    final parts = <String>[
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

  Future<String?> _pickFromSheet(
      String title, List<String> items, String current,
      {String allLabel = 'Any'}) {
    final options = <String>[allLabel, ...items];
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: _paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
              child: Text(title,
                  style: const TextStyle(
                    fontFamily: _displayFont,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _amber,
                  )),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: options.map((e) {
                  final isAll = e == allLabel;
                  final selected = isAll ? current.isEmpty : e == current;
                  return ListTile(
                    title: Text(e,
                        style: TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 16,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w600,
                          color: selected ? _amber : _inkMute,
                        )),
                    trailing: selected
                        ? const Icon(Icons.check_circle_rounded,
                            color: _amber, size: 20)
                        : null,
                    onTap: () => Navigator.of(ctx).pop(isAll ? '' : e),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = widget.width ?? MediaQuery.sizeOf(context).width;
    final double height = widget.height ?? MediaQuery.sizeOf(context).height;

    final userRef = _currentUserRefOrNull();
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        color: _paper,
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(_hPad, _vPad, _hPad, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _backButton(),
                      const SizedBox(height: 20),
                      Text('Explore', style: _titleStyle),
                      const SizedBox(height: 8),
                      Text('Find contractors near you.', style: _subtitleStyle),
                      const SizedBox(height: 26),
                      if (_loadingFilters)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: _amber),
                              ),
                              SizedBox(width: 10),
                              Text('Loading filters…',
                                  style: TextStyle(
                                    fontFamily: _bodyFont,
                                    fontSize: 14,
                                    color: _inkMute,
                                  )),
                            ],
                          ),
                        )
                      else ...[
                        _selectRow(
                          label: 'Province',
                          icon: Icons.location_on_outlined,
                          value: _province,
                          hint: 'Any province',
                          onTap: () async {
                            final v = await _pickFromSheet(
                                'Province', _provinces, _province,
                                allLabel: 'Any province');
                            if (v != null) _onProvinceChanged(v);
                          },
                        ),
                        _selectRow(
                          label: 'City',
                          icon: Icons.place_outlined,
                          value: _city,
                          hint: _province.isEmpty
                              ? 'Select province first'
                              : 'Any city',
                          onTap: _province.isEmpty
                              ? null
                              : () async {
                                  final v = await _pickFromSheet(
                                      'City', _citiesForSelectedProvince, _city,
                                      allLabel: 'Any city');
                                  if (v != null) {
                                    setState(() => _city = v);
                                    await _persistProvinceCity();
                                  }
                                },
                        ),
                        // search
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: _uRule,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SEARCH', style: _uLabelStyle),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.search,
                                      size: 19, color: _orange),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      focusNode: _searchFocusNode,
                                      cursorColor: _amber,
                                      style: _valueStyle,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                        hintText: 'Trade, contractor…',
                                        hintStyle: _hintStyle,
                                      ),
                                    ),
                                  ),
                                  if (_searchController.text.isNotEmpty)
                                    InkWell(
                                      onTap: () {
                                        _searchController.clear();
                                        setState(() {});
                                      },
                                      child: const Icon(Icons.clear,
                                          size: 19, color: _inkMute),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _selectRow(
                          label: 'Category',
                          icon: Icons.category_outlined,
                          value: _category,
                          hint: 'Any category',
                          onTap: () async {
                            final v = await _pickFromSheet(
                                'Category', _categories, _category,
                                allLabel: 'Any category');
                            if (v != null) _onCategoryChanged(v);
                          },
                        ),
                        _selectRow(
                          label: 'Speciality',
                          icon: Icons.handyman_outlined,
                          value: _speciality,
                          hint: 'Any speciality',
                          onTap: () async {
                            final list = _category.isEmpty
                                ? _specialities
                                : _specialitiesForSelectedCategory;
                            final v = await _pickFromSheet(
                                'Speciality', list, _speciality,
                                allLabel: 'Any speciality');
                            if (v != null) setState(() => _speciality = v);
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: _clearFilters,
                              child: const Text('Clear filters',
                                  style: TextStyle(
                                    fontFamily: _bodyFont,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _amber,
                                  )),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text('LISTINGS', style: _uLabelStyle),
                      ],
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

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _buildQuery().snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: CircularProgressIndicator(color: _amber),
                            ),
                          ),
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
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(24, 30, 24, 30),
                            child: Column(
                              children: [
                                Icon(Icons.search_off_rounded,
                                    color: _faint, size: 40),
                                SizedBox(height: 12),
                                Text('No listings found',
                                    style: TextStyle(
                                      fontFamily: _displayFont,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: _amber,
                                    )),
                              ],
                            ),
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
                              final title = _titleFrom(data);
                              final subtitle = _subtitleFrom(data);
                              final chip = _chipFrom(data);
                              final rating = _ratingFrom(data);

                              final img = _s(data['heroPhotoUrl']).isNotEmpty
                                  ? _s(data['heroPhotoUrl'])
                                  : _firstPhotoUrl(data['photoUrls']);

                              final listingRef = doc.reference;
                              final isSaved =
                                  savedPaths.contains(listingRef.path);

                              return _listingRow(
                                title: title,
                                chip: chip,
                                subtitle: subtitle,
                                rating: rating,
                                img: img,
                                isSaved: isSaved,
                                onTap: () => _openListing(listingRef),
                                onToggleSaved: () => _toggleSaved(
                                  listingRef: listingRef,
                                  isSaved: isSaved,
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
    );
  }

  Widget _listingRow({
    required String title,
    required String chip,
    required String subtitle,
    required double? rating,
    required String img,
    required bool isSaved,
    required VoidCallback onTap,
    required VoidCallback onToggleSaved,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: _uRule,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _hairline, width: 1),
              ),
              child: img.isNotEmpty
                  ? Image.network(img,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.image_not_supported_outlined,
                          color: _faint))
                  : const Icon(Icons.image_outlined, color: _faint),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _valueStyle),
                  if (chip.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(chip,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _inkMute,
                        )),
                  ],
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _faint,
                        )),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (rating != null) ...[
              const Icon(Icons.star_rounded, size: 16, color: _gold),
              const SizedBox(width: 3),
              Text(rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _amber,
                  )),
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
                color: isSaved ? _orange : _faint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectRow({
    required String label,
    required IconData icon,
    required String value,
    required String hint,
    required VoidCallback? onTap,
  }) {
    final empty = value.trim().isEmpty;
    return Opacity(
      opacity: onTap == null ? 0.55 : 1,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: _uRule,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: _uLabelStyle),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(icon, size: 19, color: _orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(empty ? hint : value,
                        style: empty ? _hintStyle : _valueStyle),
                  ),
                  const Icon(Icons.expand_more_rounded, color: _inkMute),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _backButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.safePop(),
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _surface,
            shape: BoxShape.circle,
            border: Border.all(color: _hairline),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 15, color: _inkMute),
        ),
      ),
    );
  }
}
