// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
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
import 'package:flutter/rendering.dart'; // ScrollDirection (hide/show the bottom nav on scroll)

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
  // ─── SUBBY PALETTE — DIRECTORY (Get-Quotes system) ─────────────────
  static const Color _ink = Color(0xFF1E282E); // titles / values
  static const Color _inkMute = Color(0xFF566670); // labels
  static const Color _faint = Color(0xFF93A3AC); // subtitles / inactive
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _steel = Color(0xFF2F3A4C); // masthead hero
  static const Color _lime = Color(0xFFE7E247); // primary accent
  static const Color _slate = Color(0xFF4E504F); // leading icons
  static const Color _hairline = Color(0xFFEAEEF0);
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  // Horizontal page padding — matches DashboardPageView (_pageHPad = 20) so the
  // masthead logo + menu button land at the identical left/right coordinates
  // on both screens.
  static const double _hPad = 20;

  // Menu-button geometry — matches DashboardPageView (_rLarge = 12).
  static const double _rLarge = 10;

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

  // Bottom-nav visibility — driven by scroll DIRECTION. Slides down off-screen
  // when the user scrolls the page up (reverse), back into view on scroll down
  // (forward). ValueNotifier so scrolling only rebuilds the nav.
  final ValueNotifier<bool> _navVisible = ValueNotifier<bool>(true);

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
    'Free State': ['Bloemfontein', 'Welkom'],
    'North West': ['Rustenburg', 'Mahikeng', 'Potchefstroom'],
    'Limpopo': ['Polokwane', 'Tzaneen', 'Thohoyandou'],
    'Mpumalanga': ['Nelspruit (Mbombela)', 'Witbank (eMalahleni)', 'Secunda'],
    'Northern Cape': ['Kimberley', 'Upington'],
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
          _selectedRegion = (city.isNotEmpty && regions.contains(city))
              ? city
              : (regions.isNotEmpty ? regions.first : _selectedRegion);
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
          _selectedRegion = (reg != null &&
                  reg.trim().isNotEmpty &&
                  regions.contains(reg.trim()))
              ? reg.trim()
              : (regions.isNotEmpty ? regions.first : _placeholderRegion);
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
                children: items.map((e) {
                  final selected = e == current;
                  return InkWell(
                    onTap: () => Navigator.of(ctx).pop(e),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFF3F6F7)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
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
    _navVisible.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = widget.width ?? MediaQuery.sizeOf(context).width;
    final double height = widget.height ?? MediaQuery.sizeOf(context).height;
    final double topInset = MediaQuery.of(context).padding.top;

    final category = _selectedCategoryLabel;
    final subs = _subcategories[category] ?? const <String>[];
    final tabs = ['Professionals', 'Trades', 'Suppliers', 'Associations'];

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        color: _steel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Steel masthead ──
            Container(
              width: double.infinity,
              color: _steel,
              // Top pad matches DashboardPageView (topInset + 14) so the logo +
              // menu button sit at the identical vertical position on both.
              padding: EdgeInsets.fromLTRB(_hPad, topInset + 14, _hPad, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo + menu button — matches DashboardPageView masthead.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _logo(),
                      _menuButton(),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text('Subby Network',
                      style: TextStyle(
                        fontFamily: _displayFont,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                        height: 1.08,
                        color: _paper,
                      )),
                  const SizedBox(height: 8),
                  Text('Find trades, pros & suppliers near you.',
                      style: TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _paper.withOpacity(0.55),
                      )),
                ],
              ),
            ),
            // ── White content block (flush, no radius) ──
            Expanded(
              child: Stack(
                children: [
                  Container(
                    color: _paper,
                    child: NotificationListener<UserScrollNotification>(
                      onNotification: (n) {
                        if (n.direction == ScrollDirection.reverse) {
                          _navVisible.value = false;
                        } else if (n.direction == ScrollDirection.forward) {
                          _navVisible.value = true;
                        }
                        return false;
                      },
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(_hPad, 22, _hPad,
                            24 + 72 + MediaQuery.of(context).padding.bottom),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _uLabel('LOCATION'),
                            const SizedBox(height: 10),
                            _card(Column(children: [
                              _selectRow(
                                icon: Icons.location_on_outlined,
                                label: 'Province',
                                value: _selectedProvince,
                                onTap: _selectProvince,
                                divider: true,
                              ),
                              _selectRow(
                                icon: Icons.place_outlined,
                                label: 'Region',
                                value: _selectedRegion,
                                onTap: _selectRegion,
                              ),
                            ])),
                            const SizedBox(height: 14),
                            _card(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 13),
                              Row(children: [
                                const Icon(Icons.search,
                                    size: 20, color: _slate),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    focusNode: _searchFocusNode,
                                    cursorColor: _ink,
                                    textInputAction: TextInputAction.search,
                                    onSubmitted: (_) =>
                                        _goToResultsFromSearch(),
                                    style: const TextStyle(
                                        fontFamily: _bodyFont,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: _ink),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                      hintText: 'Trade, contractor or supplier',
                                      hintStyle: TextStyle(
                                          fontFamily: _bodyFont,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: _faint),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _openLocationSelect(
                                      searchText: _searchController.text),
                                  child: const Icon(Icons.tune_rounded,
                                      size: 20, color: _inkMute),
                                ),
                              ]),
                            ),
                            const SizedBox(height: 22),
                            // ── Category pills ──
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List.generate(tabs.length, (index) {
                                  final selected =
                                      _selectedMainTabIndex == index;
                                  return Padding(
                                    padding: EdgeInsets.only(
                                        right:
                                            index == tabs.length - 1 ? 0 : 8),
                                    child: GestureDetector(
                                      onTap: () async {
                                        if (_selectedMainTabIndex == index)
                                          return;
                                        setState(() =>
                                            _selectedMainTabIndex = index);
                                        await _persistCategory();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 9),
                                        decoration: BoxDecoration(
                                          color: selected ? _lime : _surface,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          tabs[index],
                                          style: TextStyle(
                                            fontFamily: _bodyFont,
                                            fontSize: 13,
                                            fontWeight: selected
                                                ? FontWeight.w800
                                                : FontWeight.w700,
                                            color: selected ? _ink : _inkMute,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: 22),
                            _uLabel(
                                'BROWSE ${category.toUpperCase()} · ${subs.length}'),
                            const SizedBox(height: 10),
                            _card(
                              padding: EdgeInsets.zero,
                              Column(
                                children: [
                                  for (int i = 0; i < subs.length; i++)
                                    _subRow(subs[i], category,
                                        divider: i != subs.length - 1),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Bottom nav — only when signed in. Slides with scroll dir.
                  if (currentUserReference != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _navVisible,
                        builder: (context, visible, _) => AnimatedSlide(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          offset: Offset(0, visible ? 0 : 1),
                          child: MainBottomNav(
                            currentIndex: 1,
                            projectsRouteName: widget.dashboardRouteName,
                            accountRouteName: 'profilePage',
                          ),
                        ),
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

  Widget _card(Widget child, {EdgeInsets padding = const EdgeInsets.all(0)}) =>
      Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      );

  Widget _selectRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    bool divider = false,
  }) {
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
                Text(value,
                    style: const TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _ink)),
              ],
            ),
          ),
          const Icon(Icons.expand_more_rounded, color: _faint),
        ]),
      ),
    );
  }

  Widget _subRow(String sub, String category, {bool divider = true}) {
    return InkWell(
      onTap: () => _openSubcategory(sub),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          border: divider
              ? const Border(bottom: BorderSide(color: _hairline))
              : null,
        ),
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: _surface, borderRadius: BorderRadius.circular(10)),
            child: Icon(_iconForCategory(category), size: 18, color: _slate),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(sub,
                  style: const TextStyle(
                      fontFamily: _bodyFont,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _ink))),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFC6D0D5)),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // MASTHEAD LOGO + MENU — copied verbatim from DashboardPageView so the two
  // screens share an identical top-left mark and top-right menu affordance.
  // ─────────────────────────────────────────────────────────────────────
  //
  // Icon-only mark — bold, no wordmark. Loads the white Subby house PNG from
  // FlutterFlow asset storage; falls back to the painted _SubbyMarkPainter if
  // the network image fails (offline / cold start) so the logo never renders
  // blank.
  static const String _logoUrl =
      'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/winston-9dy48u/assets/vkvx0d5tvzte/subby_logo_white.png';

  // Non-square mark: anchor on height (36) and leave width unconstrained so the
  // image renders at its natural aspect ratio rather than being squeezed into a
  // square box. The 36px height keeps the header's vertical rhythm.
  Widget _logo() => SizedBox(
        height: 36,
        child: Image.network(
          _logoUrl,
          height: 36,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => CustomPaint(
            size: const Size(36, 36),
            painter: const _SubbyMarkPainter(
              peak: Color(0xFF4E504F), // Subby brand green
              base: Color(0xFF4E504F),
            ),
          ),
        ),
      );

  Widget _menuButton() => InkWell(
        onTap: _openMore,
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

  void _openMore() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MorePageView()),
    );
  }
}

// Subby mark — bold, icon only (viewBox 0 0 64 64):
//   roof  : filled triangle, peak (32,11), base from (12.8,28.4)-(51.2,28.4).
//   bars  : two full-width rounded bars beneath, matching the roof base width.
// Fallback for the masthead logo when the PNG asset fails to load. Mirrors the
// painter in DashboardPageView so both screens degrade identically.
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
