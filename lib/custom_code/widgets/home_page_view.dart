// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/auth/firebase_auth/auth_util.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePageView extends StatefulWidget {
  const HomePageView({
    super.key,
    this.width,
    this.height,

    /// ✅ Route name for Add Listing page (no params)
    /// Defaults to 'addListingPage' (matches your FlutterFlow page route)
    this.addListingRouteName,

    /// ✅ Route name for Edit Listing page (expects a listingRef param)
    /// Defaults to 'editListingPage'
    this.editListingRouteName,

    /// ✅ Param name on Edit Listing page that receives the listing reference
    /// Defaults to 'listingRef'
    this.editListingParamName,

    /// ✅ Route name for Listing Results page (no params required)
    /// Defaults to 'ListingResultsPage' (override to 'listingResultsPage' if needed)
    this.listingResultsRouteName,

    /// ✅ Route name for Location Select page (returns Map {province, region})
    /// Defaults to 'LocationSelectPage' (override to 'locationSelectPage' if needed)
    this.locationSelectRouteName,

    /// ✅ Listings collection name
    /// Defaults to 'subby_listings'
    this.listingCollectionName,

    /// ✅ Field name on listing docs that stores the owner as a DocumentReference (recommended)
    /// Defaults to 'ownerRef'
    this.listingOwnerRefField,

    /// ✅ Field name on listing docs that stores the owner as a String uid (fallback)
    /// Defaults to 'ownerId'
    this.listingOwnerIdField,

    /// ✅ Route name to send unregistered / no-profile users to create account
    /// Defaults to 'createAccountPage'
    this.createAccountRouteName,

    /// ✅ Users collection name for profile existence check
    /// Defaults to 'users'
    this.usersCollectionName,

    /// ✅ NEW: Dashboard route (no params)
    /// Defaults to 'dashboardPage'
    this.dashboardRouteName,
  });

  final double? width;
  final double? height;

  /// ✅ Route name override (optional)
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
  static const double _hPad = 24;
  static const double _vPad = 24;

  // ✅ Shared prefs keys (Home + Explore use same)
  static const String _kProvince = 'subby_app_province';
  static const String _kCity = 'subby_app_city';
  static const String _kCategory = 'subby_app_category';

  int _selectedMainTabIndex = 0;
  int _previousTabIndex = 0; // for directional animation

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final List<GlobalKey> _tabKeys = List.generate(4, (_) => GlobalKey());

  String _selectedProvince = 'Gauteng';
  String _selectedRegion = 'Johannesburg';

  // These placeholders MUST match what ListingResultsPageView treats as non-meaningful
  static const String _placeholderProvince = 'Select province';
  static const String _placeholderRegion = 'Select region';

  // ✅ Listing ownership state (kept for future, but header button removed)
  bool _checkingListing = true;
  DocumentReference? _myListingRef;

  // =========================================================
  // ✅ TYPOGRAPHY (CONSISTENT: token + explicit family, color only)
  // =========================================================
  TextStyle _appTitleStyle(FlutterFlowTheme theme) {
    return theme.titleLarge.copyWith(
      fontWeight: FontWeight.w900, // 🔥 Extra bold
      letterSpacing: 0.2,
    );
  }

  TextStyle _appSubtitleStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: t.bodySmallFamily,
        color: t.secondaryText,
      );

  TextStyle _welcomeStyle(FlutterFlowTheme t) => t.headlineSmall.override(
        fontFamily: t.headlineSmallFamily,
      );

  TextStyle _tabTextStyle(FlutterFlowTheme t, {required bool selected}) =>
      t.labelMedium.override(
        fontFamily: t.labelMediumFamily,
        color: selected ? Colors.white : t.secondaryText,
      );

  // ✅ Filters / dropdowns use ONE token everywhere in app (match this in Explore too)
  TextStyle _dropdownTextStyle(FlutterFlowTheme t) => t.titleMedium.override(
        fontFamily: t.titleMediumFamily,
        color: t.primaryText,
      );

  TextStyle _searchTextStyle(FlutterFlowTheme t) => t.bodyMedium.override(
        fontFamily: t.bodyMediumFamily,
      );

  TextStyle _searchHintStyle(FlutterFlowTheme t) => t.bodyMedium.override(
        fontFamily: t.bodyMediumFamily,
        color: t.secondaryText,
      );

  TextStyle _sectionTitleStyle(FlutterFlowTheme t) => t.titleMedium.override(
        fontFamily: t.titleMediumFamily,
      );

  TextStyle _gridTileLabelStyle(FlutterFlowTheme t) => t.labelMedium.override(
        fontFamily: t.labelMediumFamily,
      );
  // =========================================================

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

  // ----------------------------
  // Slug helper (index strategy)
  // ----------------------------
  String _slugify(String input) {
    var s = input.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'\(.*?\)'), '');
    s = s.replaceAll('&', 'and');
    s = s.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    s = s.replaceAll(' ', '-');
    s = s.replaceAll(RegExp(r'-+'), '-');
    s = s.replaceAll(RegExp(r'^-+|-+$'), '');
    return s;
  }

  String get _provinceSlug => _slugify(_selectedProvince);
  String get _categorySlug => _slugify(_selectedCategoryLabel);

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

  IconData _iconForSubcategory(String category, String sub) {
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
  // ✅ SharedPreferences sync
  // =========================
  Future<void> _loadPersistedHomeState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prov = (prefs.getString(_kProvince) ?? '').trim();
      final city = (prefs.getString(_kCity) ?? '').trim();
      final cat = (prefs.getString(_kCategory) ?? '').trim();

      if (!mounted) return;

      // Province/City
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

      // Category -> tab index (optional but keeps Home/Explore aligned)
      if (cat.isNotEmpty) {
        final idx = ['Professionals', 'Trades', 'Suppliers', 'Associations']
            .indexOf(cat);
        if (idx >= 0 && idx != _selectedMainTabIndex) {
          setState(() {
            _previousTabIndex = _selectedMainTabIndex;
            _selectedMainTabIndex = idx;
          });
        }
      }
    } catch (_) {
      // ignore
    }
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

  // =========================================================
  // ✅ Check if current user has a listing (kept for future use)
  // =========================================================
  Future<void> _checkUserListing() async {
    try {
      final userRef = currentUserReference;
      final uid = currentUserUid;

      // If not logged in, no listing
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

      // 1) Try ownerRef == currentUserReference
      if (userRef != null && ownerRefField.isNotEmpty) {
        final snap = await colRef
            .where(ownerRefField, isEqualTo: userRef)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) foundRef = snap.docs.first.reference;
      }

      // 2) Fallback: ownerId == currentUserUid
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

  // =========================================================
  // ✅ Back to Dashboard (TimelineHomePageView style: POP reveal)
  // - POP if possible (true uncover)
  // - otherwise replace to dashboard with leftToRight transition
  // =========================================================
  void _goBackToDashboard() {
    final nav = Navigator.of(context);

    // ✅ Best case: this page was pushed from Dashboard -> pop reveals it.
    if (nav.canPop()) {
      nav.pop();
      return;
    }

    final target = (widget.dashboardRouteName ?? 'dashboardPage').trim();

    // Fallback: if route name is weird/empty, just safePop
    if (target.isEmpty) {
      context.safePop();
      return;
    }

    // ✅ If we can't pop, don't "push" dashboard on top — replace instead.
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

  // =========================================================
  // ✅ Guard: must be logged in AND have users/<uid> profile doc
  // If not, redirect to createAccountPage
  // =========================================================
  Future<bool> _ensureRegisteredProfile() async {
    final String createRoute =
        (widget.createAccountRouteName ?? 'createAccountPage').trim();
    final String usersColl = (widget.usersCollectionName ?? 'users').trim();

    // 1) Must be logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (createRoute.isNotEmpty) context.pushNamed(createRoute);
      return false;
    }

    // 2) Must have profile document
    try {
      final doc = await FirebaseFirestore.instance
          .collection(usersColl)
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        if (createRoute.isNotEmpty) context.pushNamed(createRoute);
        return false;
      }
    } catch (_) {
      // If we cannot verify, treat as not registered
      if (createRoute.isNotEmpty) context.pushNamed(createRoute);
      return false;
    }

    return true;
  }

  // =========================================================
  // Location select page (returns {province, region})
  // =========================================================
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

  @override
  void initState() {
    super.initState();

    // ✅ Load shared Home/Explore state
    _loadPersistedHomeState();

    // ✅ Check if user has a listing (kept, but header button removed)
    _checkUserListing();

    // Ensure region valid for default province
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
    final theme = FlutterFlowTheme.of(context);

    final double width = widget.width ?? MediaQuery.sizeOf(context).width;
    final double height = widget.height ?? MediaQuery.sizeOf(context).height;

    return SizedBox(
      width: width,
      height: height,
      child: SafeArea(
        child: Container(
          color: theme.primaryBackground,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- TOP BAR ----------
              Padding(
                padding: const EdgeInsets.fromLTRB(_hPad, _vPad, _hPad, 12),
                child: Row(
                  children: [
                    // ✅ Back (to DashboardPage) - based on ProjectDetailPageView
                    InkWell(
                      onTap: _goBackToDashboard,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.primaryBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: theme.alternate.withOpacity(0.9)),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 22,
                          color: theme.primaryText,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: theme.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.construction,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Subby', style: _appTitleStyle(theme)),
                        const SizedBox(height: 2),
                        Text(
                          'Home building directory',
                          style: _appSubtitleStyle(theme),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // ✅ REMOVED: Add Listing / Edit Listing button in header
                  ],
                ),
              ),

              // ---------- EDGE-TO-EDGE PRIMARY BLOCK ----------
              _buildPrimaryLocationSearchBar(),

              const SizedBox(height: 14),

              // ---------- WELCOME TEXT ----------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: Text(
                  'Welcome, how can we help you?',
                  style: _welcomeStyle(theme),
                ),
              ),

              const SizedBox(height: 14),

              // ---------- MAIN TABS ----------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: _buildMainTabs(),
              ),

              const SizedBox(height: 12),

              // ---------- SUB-CATEGORY ----------
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    final bool slideLeft =
                        _selectedMainTabIndex > _previousTabIndex;
                    final offsetAnimation = Tween<Offset>(
                      begin: slideLeft
                          ? const Offset(1.0, 0.0)
                          : const Offset(-1.0, 0.0),
                      end: Offset.zero,
                    ).animate(animation);

                    return SlideTransition(
                      position: offsetAnimation,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<int>(_selectedMainTabIndex),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return _buildSubcategoryTwoRowGrid(
                            constraints.maxHeight);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // PRIMARY BLOCK - DROPDOWNS + SEARCH
  // =========================================================
  Widget _buildPrimaryLocationSearchBar() {
    final theme = FlutterFlowTheme.of(context);
    final regions = _regionsByProvince[_selectedProvince] ?? const <String>[];
    final regionItems =
        regions.isNotEmpty ? regions : <String>[_placeholderRegion];

    Widget plainWhiteDropdown({
      required String value,
      required List<String> items,
      required ValueChanged<String?> onChanged,
      required IconData icon,
    }) {
      return Row(
        children: [
          Icon(icon, size: 18, color: theme.primaryText),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: theme.primary,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: theme.primaryText,
                ),
                style: _dropdownTextStyle(theme),
                items: items.map((s) {
                  return DropdownMenuItem<String>(
                    value: s,
                    child: Text(
                      s,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: _dropdownTextStyle(theme),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      color: theme.primary,
      padding: const EdgeInsets.fromLTRB(_hPad, 14, _hPad, 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: plainWhiteDropdown(
                  value: _selectedProvince,
                  items: _provinces,
                  icon: Icons.location_on_outlined,
                  onChanged: (v) async {
                    if (v == null) return;
                    setState(() {
                      _selectedProvince = v;
                      final newRegions =
                          _regionsByProvince[_selectedProvince] ??
                              const <String>[];
                      _selectedRegion = newRegions.isNotEmpty
                          ? newRegions.first
                          : _placeholderRegion;
                    });
                    await _persistLocation();
                  },
                ),
              ),
              Container(
                width: 1,
                height: 22,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: theme.primaryText.withOpacity(0.35),
              ),
              Expanded(
                child: plainWhiteDropdown(
                  value: regionItems.contains(_selectedRegion)
                      ? _selectedRegion
                      : regionItems.first,
                  items: regionItems,
                  icon: Icons.place_outlined,
                  onChanged: (v) async {
                    if (v == null) return;
                    setState(() => _selectedRegion = v);
                    await _persistLocation();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSearchFieldWhite(),
        ],
      ),
    );
  }

  Widget _buildSearchFieldWhite() {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(Icons.search, color: theme.secondaryText),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: _searchTextStyle(theme),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: 'Search for a trade, contractor or supplier',
                hintStyle: _searchHintStyle(theme),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _goToResultsFromSearch(),
            ),
          ),
          IconButton(
            icon: Icon(Icons.tune, size: 20, color: theme.secondaryText),
            onPressed: () async {
              await _openLocationSelect(searchText: _searchController.text);
            },
          ),
        ],
      ),
    );
  }

  // =========================================================
  // MAIN TABS
  // =========================================================
  Widget _buildMainTabs() {
    final theme = FlutterFlowTheme.of(context);
    final tabs = ['Professionals', 'Trades', 'Suppliers', 'Associations'];

    return SizedBox(
      height: 42,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (index) {
            final selected = _selectedMainTabIndex == index;

            return Padding(
              padding: EdgeInsets.only(right: index == tabs.length - 1 ? 0 : 8),
              child: GestureDetector(
                onTap: () async {
                  if (_selectedMainTabIndex == index) return;
                  setState(() {
                    _previousTabIndex = _selectedMainTabIndex;
                    _selectedMainTabIndex = index;
                  });
                  await _persistCategory();

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final ctx = _tabKeys[index].currentContext;
                    if (ctx != null) {
                      Scrollable.ensureVisible(
                        ctx,
                        duration: const Duration(milliseconds: 200),
                        alignment: 0.5,
                      );
                    }
                  });
                },
                child: AnimatedContainer(
                  key: _tabKeys[index],
                  duration: const Duration(milliseconds: 160),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: selected ? theme.primary : theme.primaryBackground,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected ? theme.primary : theme.alternate,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    tabs[index],
                    style: _tabTextStyle(theme, selected: selected),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // =========================================================
  // SUB-CATEGORY GRID
  // =========================================================
  Widget _buildSubcategoryTwoRowGrid(double maxHeight) {
    final theme = FlutterFlowTheme.of(context);
    final category = _selectedCategoryLabel;
    final items = _subcategories[category] ?? const <String>[];

    // ✅ FIX: give the 2-row grid enough vertical room so labels never overflow
    final double availableForGrid = (maxHeight - 64).clamp(220, 280);

    const double tileWidth = 92;
    const double hGap = 12;
    const double vGap = 12;

    Widget tile(String sub) {
      final icon = _iconForSubcategory(category, sub);
      final specialitySlug = _slugify(sub);
      final resultsRoute =
          (widget.listingResultsRouteName ?? 'ListingResultsPage').trim();

      return GestureDetector(
        onTap: () async {
          await _persistLocation();
          await _persistCategory();

          context.pushNamed(
            resultsRoute,
            queryParameters: {
              'provinceSlug': serializeParam(_provinceSlug, ParamType.String),
              'categorySlug': serializeParam(_categorySlug, ParamType.String),
              'specialitySlug':
                  serializeParam(specialitySlug, ParamType.String),
              'category': serializeParam(category, ParamType.String),
              'speciality': serializeParam(sub, ParamType.String),
              'province': serializeParam(_selectedProvince, ParamType.String),
              'city': serializeParam(_selectedRegion, ParamType.String),
              'initialProvince':
                  serializeParam(_selectedProvince, ParamType.String),
              'initialRegion':
                  serializeParam(_selectedRegion, ParamType.String),
            }.withoutNulls,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.alternate, width: 1),
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                offset: const Offset(0, 4),
                color: Colors.black.withOpacity(0.03),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.secondaryBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.alternate, width: 1),
                ),
                child: Icon(icon, size: 19, color: theme.primary),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  sub,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: _gridTileLabelStyle(theme),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _hPad),
          child: Text('Browse $category', style: _sectionTitleStyle(theme)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: availableForGrid,
          child: GridView.builder(
            clipBehavior: Clip.none,
            padding: const EdgeInsets.fromLTRB(_hPad, 10, _hPad, 10),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: hGap,
              crossAxisSpacing: vGap,
              mainAxisExtent: tileWidth,
            ),
            itemBuilder: (context, index) => tile(items[index]),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
