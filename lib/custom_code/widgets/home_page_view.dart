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

import '/flutter_flow/custom_functions.dart' as functions;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/auth/firebase_auth/auth_util.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePageView extends StatefulWidget {
  const HomePageView({
    super.key,
    this.width,
    this.height,
    this.addListingRouteName,
    this.editListingRouteName,
    this.editListingParamName,
    this.listingResultsRouteName,
    this.locationSelectRouteName,
    this.listingCollectionName,
    this.listingOwnerRefField,
    this.listingOwnerIdField,
    this.createAccountRouteName,
    this.usersCollectionName,
    this.dashboardRouteName,
  });

  final double? width;
  final double? height;

  final String? addListingRouteName;
  final String? editListingRouteName;
  final String? editListingParamName;
  final String? listingResultsRouteName;
  final String? locationSelectRouteName;
  final String? listingCollectionName;
  final String? listingOwnerRefField;
  final String? listingOwnerIdField;
  final String? createAccountRouteName;
  final String? usersCollectionName;
  final String? dashboardRouteName;

  @override
  State<HomePageView> createState() => _HomePageViewState();
}

class _HomePageViewState extends State<HomePageView> {
  // ─── SUBBY PALETTE — DIRECTORY (amber / sunshine) ──────────────────
  static const Color _amber = Color(0xFFE5771E); // accent
  static const Color _sunshine = Color(0xFFFDB617); // secondary highlight
  static const Color _inkMute = Color(0xFF5A6675); // labels
  static const Color _faint = Color(0xFF93A0B0); // subtitles / inactive
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFEEF1F4);
  static const Color _hairline = Color(0xFFEEF1F2);
  static const Color _rule = Color(0xFFE2E7EE);
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const double _hPad = 24;
  static const double _vPad = 14;
  static const double _navReserve = 96;

  static const String _kProvince = 'subby_app_province';
  static const String _kCity = 'subby_app_city';
  static const String _kCategory = 'subby_app_category';

  int _selectedMainTabIndex = 0;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _selectedProvince = 'Gauteng';
  String _selectedRegion = 'Johannesburg';

  static const String _placeholderRegion = 'Select region';

  bool _checkingListing = true;
  DocumentReference? _myListingRef;

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
        color: Color(0xFF94A0AD),
      );

  static const BoxDecoration _uRule = BoxDecoration(
    border: Border(bottom: BorderSide(color: _rule, width: 1)),
  );

  String get _selectedCategoryLabel {
    switch (_selectedMainTabIndex) {
      case 0:
        return 'Professionals';
      case 1:
        return 'Trades';
      case 2:
        return 'Suppliers';
      case 3:
      default:
        return 'Associations';
    }
  }

  String get _provinceSlug => functions.slugify(_selectedProvince);
  String get _categorySlug => functions.slugify(_selectedCategoryLabel);

  static const List<String> _provinces = [
    'Gauteng',
    'Western Cape',
    'KwaZulu-Natal',
    'Eastern Cape',
    'Free State',
    'North West',
    'Limpopo',
    'Mpumalanga',
    'Northern Cape',
  ];

  static const Map<String, List<String>> _regionsByProvince = {
    'Gauteng': [
      'Johannesburg',
      'Pretoria',
      'Centurion',
      'Midrand',
      'Sandton',
      'Soweto',
      'East Rand',
      'West Rand',
      'Vaal',
    ],
    'Western Cape': [
      'Cape Town',
      'Stellenbosch',
      'Somerset West',
      'Paarl',
      'George',
      'Knysna',
      'Hermanus',
    ],
    'KwaZulu-Natal': [
      'Durban',
      'Umhlanga',
      'Pietermaritzburg',
      'Ballito',
      'Richards Bay',
    ],
    'Eastern Cape': [
      'Gqeberha (Port Elizabeth)',
      'East London',
      'Mthatha',
    ],
    'Free State': [
      'Bloemfontein',
      'Welkom',
    ],
    'North West': [
      'Rustenburg',
      'Mahikeng',
      'Potchefstroom',
    ],
    'Limpopo': [
      'Polokwane',
      'Tzaneen',
      'Thohoyandou',
    ],
    'Mpumalanga': [
      'Nelspruit (Mbombela)',
      'Witbank (eMalahleni)',
      'Secunda',
    ],
    'Northern Cape': [
      'Kimberley',
      'Upington',
    ],
  };

  static const Map<String, List<String>> _subcategories = {
    'Professionals': [
      'Architect',
      'Structural engineer',
      'Quantity surveyor',
      'Interior designer',
      'Project manager',
      'Land surveyor',
    ],
    'Trades': [
      'Builder',
      'Electrician',
      'Plumber',
      'Tiler',
      'Painter',
      'Carpenter',
      'Roofer',
      'Glazier',
    ],
    'Suppliers': [
      'Building materials',
      'Hardware store',
      'Timber & roofing',
      'Windows & doors',
      'Kitchens & cupboards',
      'Paint & coatings',
      'Plumbing supplies',
    ],
    'Associations': [
      'Master Builders Association',
      'NHBRC',
      'Electrical Contractors Association',
      'Plumbing Industry Board',
    ],
  };

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Professionals':
        return Icons.assignment_ind_outlined;
      case 'Trades':
        return Icons.handyman_outlined;
      case 'Suppliers':
        return Icons.storefront_outlined;
      case 'Associations':
        return Icons.apartment_rounded;
      default:
        return Icons.category_outlined;
    }
  }

  // =========================
  // SharedPreferences sync
  // =========================
  Future<void> _loadPersistedHomeState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prov = (prefs.getString(_kProvince) ?? '').trim();
      final city = (prefs.getString(_kCity) ?? '').trim();
      final cat = (prefs.getString(_kCategory) ?? '').trim();

      if (!mounted) return;

      if (prov.isNotEmpty && _provinces.contains(prov)) {
        final regions = _regionsByProvince[prov] ?? const <String>[];
        setState(() {
          _selectedProvince = prov;
          if (city.isNotEmpty && regions.contains(city)) {
            _selectedRegion = city;
          } else {
            _selectedRegion =
                regions.isNotEmpty ? regions.first : _selectedRegion;
          }
        });
      }

      if (cat.isNotEmpty) {
        final idx = ['Professionals', 'Trades', 'Suppliers', 'Associations']
            .indexOf(cat);
        if (idx >= 0 && idx != _selectedMainTabIndex) {
          setState(() => _selectedMainTabIndex = idx);
        }
      }
    } catch (_) {}
  }

  Future<void> _persistLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kProvince, _selectedProvince.trim());
      await prefs.setString(_kCity, _selectedRegion.trim());
    } catch (_) {}
  }

  Future<void> _persistCategory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCategory, _selectedCategoryLabel.trim());
    } catch (_) {}
  }

  Future<void> _checkUserListing() async {
    try {
      final userRef = currentUserReference;
      final uid = currentUserUid;

      if (userRef == null && (uid == null || uid.isEmpty)) {
        if (!mounted) return;
        setState(() {
          _myListingRef = null;
          _checkingListing = false;
        });
        return;
      }

      final coll = (widget.listingCollectionName ?? 'subby_listings').trim();
      final ownerRefField = (widget.listingOwnerRefField ?? 'ownerRef').trim();
      final ownerIdField = (widget.listingOwnerIdField ?? 'ownerId').trim();

      final colRef = FirebaseFirestore.instance.collection(coll);

      DocumentReference? foundRef;

      if (userRef != null && ownerRefField.isNotEmpty) {
        final snap = await colRef
            .where(ownerRefField, isEqualTo: userRef)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) foundRef = snap.docs.first.reference;
      }

      if (foundRef == null && uid != null && uid.isNotEmpty) {
        final snap =
            await colRef.where(ownerIdField, isEqualTo: uid).limit(1).get();
        if (snap.docs.isNotEmpty) foundRef = snap.docs.first.reference;
      }

      if (!mounted) return;
      setState(() {
        _myListingRef = foundRef;
        _checkingListing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _myListingRef = null;
        _checkingListing = false;
      });
    }
  }

  void _goBackToDashboard() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    final target = (widget.dashboardRouteName ?? 'dashboardPage').trim();
    if (target.isEmpty) {
      context.safePop();
      return;
    }
    context.pushReplacementNamed(
      target,
      extra: {
        kTransitionInfoKey: const TransitionInfo(
          hasTransition: true,
          transitionType: PageTransitionType.leftToRight,
          duration: Duration(milliseconds: 260),
        ),
      },
    );
  }

  Future<void> _openLocationSelect({String? searchText}) async {
    final route =
        (widget.locationSelectRouteName ?? 'LocationSelectPage').trim();

    final result = await context.pushNamed(
      route,
      queryParameters: {
        'category': serializeParam(_selectedCategoryLabel, ParamType.String),
        if (searchText != null)
          'searchText': serializeParam(searchText, ParamType.String),
        'initialProvince': serializeParam(_selectedProvince, ParamType.String),
        'initialRegion': serializeParam(_selectedRegion, ParamType.String),
      }.withoutNulls,
    );

    if (!mounted) return;
    if (result is Map) {
      final prov = result['province']?.toString();
      final reg = result['region']?.toString();

      if (prov != null && prov.trim().isNotEmpty) {
        final regions = _regionsByProvince[prov.trim()] ?? const <String>[];
        setState(() {
          _selectedProvince = prov.trim();
          if (reg != null &&
              reg.trim().isNotEmpty &&
              regions.isNotEmpty &&
              regions.contains(reg.trim())) {
            _selectedRegion = reg.trim();
          } else {
            _selectedRegion =
                regions.isNotEmpty ? regions.first : _placeholderRegion;
          }
        });
        await _persistLocation();
      }
    }
  }

  void _goToResultsFromSearch() async {
    final route =
        (widget.listingResultsRouteName ?? 'ListingResultsPage').trim();
    final query = _searchController.text.trim();

    await _persistLocation();
    await _persistCategory();

    context.pushNamed(
      route,
      queryParameters: {
        'provinceSlug': serializeParam(_provinceSlug, ParamType.String),
        'categorySlug': serializeParam(_categorySlug, ParamType.String),
        'category': serializeParam(_selectedCategoryLabel, ParamType.String),
        'province': serializeParam(_selectedProvince, ParamType.String),
        'city': serializeParam(_selectedRegion, ParamType.String),
        if (query.isNotEmpty)
          'searchText': serializeParam(query, ParamType.String),
        'initialProvince': serializeParam(_selectedProvince, ParamType.String),
        'initialRegion': serializeParam(_selectedRegion, ParamType.String),
      }.withoutNulls,
    );
  }

  void _openSubcategory(String sub) async {
    final resultsRoute =
        (widget.listingResultsRouteName ?? 'ListingResultsPage').trim();
    final specialitySlug = functions.slugify(sub);

    await _persistLocation();
    await _persistCategory();

    context.pushNamed(
      resultsRoute,
      queryParameters: {
        'provinceSlug': serializeParam(_provinceSlug, ParamType.String),
        'categorySlug': serializeParam(_categorySlug, ParamType.String),
        'specialitySlug': serializeParam(specialitySlug, ParamType.String),
        'category': serializeParam(_selectedCategoryLabel, ParamType.String),
        'speciality': serializeParam(sub, ParamType.String),
        'province': serializeParam(_selectedProvince, ParamType.String),
        'city': serializeParam(_selectedRegion, ParamType.String),
        'initialProvince': serializeParam(_selectedProvince, ParamType.String),
        'initialRegion': serializeParam(_selectedRegion, ParamType.String),
      }.withoutNulls,
    );
  }

  void _selectProvince() async {
    final picked =
        await _pickFromSheet('Province', _provinces, _selectedProvince);
    if (picked == null) return;
    setState(() {
      _selectedProvince = picked;
      final newRegions =
          _regionsByProvince[_selectedProvince] ?? const <String>[];
      _selectedRegion =
          newRegions.isNotEmpty ? newRegions.first : _placeholderRegion;
    });
    await _persistLocation();
  }

  void _selectRegion() async {
    final regions = _regionsByProvince[_selectedProvince] ?? const <String>[];
    if (regions.isEmpty) return;
    final picked = await _pickFromSheet('Region', regions, _selectedRegion);
    if (picked == null) return;
    setState(() => _selectedRegion = picked);
    await _persistLocation();
  }

  Future<String?> _pickFromSheet(
      String title, List<String> items, String current) {
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
                children: items.map((e) {
                  final selected = e == current;
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
                    onTap: () => Navigator.of(ctx).pop(e),
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
  void initState() {
    super.initState();
    _loadPersistedHomeState();
    _checkUserListing();
    final regions = _regionsByProvince[_selectedProvince] ?? const <String>[];
    if (regions.isNotEmpty && !regions.contains(_selectedRegion)) {
      _selectedRegion = regions.first;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = widget.width ?? MediaQuery.sizeOf(context).width;
    final double height = widget.height ?? MediaQuery.sizeOf(context).height;

    final category = _selectedCategoryLabel;
    final subs = _subcategories[category] ?? const <String>[];
    final tabs = ['Professionals', 'Trades', 'Suppliers', 'Associations'];

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        color: _paper,
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(_hPad, _vPad, _hPad,
                _navReserve + MediaQuery.of(context).padding.bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _backButton(),
                const SizedBox(height: 20),
                Text('Subby Directory', style: _titleStyle),
                const SizedBox(height: 8),
                Text('Find trades, pros & suppliers near you.',
                    style: _subtitleStyle),
                const SizedBox(height: 26),

                _selectRow(
                  label: 'Province',
                  icon: Icons.location_on_outlined,
                  value: _selectedProvince,
                  onTap: _selectProvince,
                ),
                _selectRow(
                  label: 'Region',
                  icon: Icons.place_outlined,
                  value: _selectedRegion,
                  onTap: _selectRegion,
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
                          const Icon(Icons.search, size: 19, color: _amber),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              cursorColor: _amber,
                              style: _valueStyle,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _goToResultsFromSearch(),
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                hintText: 'Trade, contractor or supplier',
                                hintStyle: _hintStyle,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _openLocationSelect(
                                searchText: _searchController.text),
                            child: const Icon(Icons.tune_rounded,
                                size: 19, color: _inkMute),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // category tabs
                const SizedBox(height: 22),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(tabs.length, (index) {
                      final selected = _selectedMainTabIndex == index;
                      return Padding(
                        padding: EdgeInsets.only(
                            right: index == tabs.length - 1 ? 0 : 20),
                        child: GestureDetector(
                          onTap: () async {
                            if (_selectedMainTabIndex == index) return;
                            setState(() => _selectedMainTabIndex = index);
                            await _persistCategory();
                          },
                          child: Container(
                            padding: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: selected ? _amber : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              tabs[index],
                              style: TextStyle(
                                fontFamily: _bodyFont,
                                fontSize: 14,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: selected ? _amber : _faint,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 18),
                Text('BROWSE ${category.toUpperCase()} · ${subs.length}',
                    style: _uLabelStyle),

                // subcategory rows
                ...subs.map((sub) => InkWell(
                      onTap: () => _openSubcategory(sub),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: _uRule,
                        child: Row(
                          children: [
                            Icon(_iconForCategory(category),
                                size: 19, color: _amber),
                            const SizedBox(width: 10),
                            Expanded(child: Text(sub, style: _valueStyle)),
                            const Icon(Icons.chevron_right_rounded,
                                color: _rule),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectRow({
    required String label,
    required IconData icon,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
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
                Icon(icon, size: 19, color: _amber),
                const SizedBox(width: 10),
                Expanded(child: Text(value, style: _valueStyle)),
                const Icon(Icons.expand_more_rounded, color: _inkMute),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _backButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _goBackToDashboard,
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
