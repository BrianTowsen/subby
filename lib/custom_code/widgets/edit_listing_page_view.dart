// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:cloud_firestore/cloud_firestore.dart';
import '/auth/firebase_auth/auth_util.dart';

class EditListingPageView extends StatefulWidget {
  const EditListingPageView({
    super.key,
    this.width,
    this.height,

    /// ✅ Pass this from HomePage when user has a listing
    this.listingRef,

    /// ✅ Optional override if your collection name differs
    this.listingCollectionName,

    /// ✅ Ownership fields
    this.listingOwnerRefField,
    this.listingOwnerIdField,
  });

  final double? width;
  final double? height;

  final DocumentReference? listingRef;

  final String? listingCollectionName;
  final String? listingOwnerRefField;
  final String? listingOwnerIdField;

  @override
  State<EditListingPageView> createState() => _EditListingPageViewState();
}

class _EditListingPageViewState extends State<EditListingPageView> {
  static const double _hPad = 24;
  static const double _vPad = 24;

  // Match ListingDetailPageView card styling
  static const double _cardRadius = 16;

  List<BoxShadow> _subbyTileShadow() => [
        BoxShadow(
          blurRadius: 10,
          offset: const Offset(0, 4),
          color: Colors.black.withOpacity(0.03),
        ),
      ];

  BoxDecoration _subbyCardDecoration(
    FlutterFlowTheme theme, {
    Color? color,
    bool shadow = true,
  }) {
    return BoxDecoration(
      color: color ?? theme.primaryBackground,
      borderRadius: BorderRadius.circular(_cardRadius),
      border: Border.all(color: theme.alternate, width: 1),
      boxShadow: shadow ? _subbyTileShadow() : const [],
    );
  }

  // ---------------------------------------------------------
  // Form state (MATCH AddListing)
  // ---------------------------------------------------------
  int _selectedTabIndex = 0; // 0..3

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _aboutCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _whatsCtrl = TextEditingController();
  final TextEditingController _suburbCtrl = TextEditingController();

  String _selectedProvince = 'Select province';
  String _selectedRegion = 'Select region';
  String _selectedSpeciality = 'Select speciality';

  bool _saving = false;
  bool _didHydrate = false;

  // ---------------------------------------------------------
  // Typography (match AddListing)
  // ---------------------------------------------------------
  TextStyle _titleStyle(FlutterFlowTheme t) => t.titleLarge.override(
        fontFamily: t.titleLargeFamily,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.2,
      );

  TextStyle _subtitleStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: t.bodySmallFamily,
        color: t.secondaryText,
      );

  TextStyle _sectionTitleStyle(FlutterFlowTheme t) => t.titleMedium.override(
        fontFamily: t.titleMediumFamily,
      );

  // ✅ tabs readable on primary header + active tab obvious
  TextStyle _tabTextStyle(FlutterFlowTheme t, {required bool selected}) =>
      t.labelMedium.override(
        fontFamily: t.labelMediumFamily,
        color: selected ? t.primary : Colors.white,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
      );

  TextStyle _fieldTextStyle(FlutterFlowTheme t) => t.bodyMedium.override(
        fontFamily: t.bodyMediumFamily,
      );

  TextStyle _hintTextStyle(FlutterFlowTheme t) => t.bodyMedium.override(
        fontFamily: t.bodyMediumFamily,
        color: t.secondaryText,
      );

  TextStyle _primaryBtnTextStyle(FlutterFlowTheme t) => t.labelMedium.override(
        fontFamily: t.labelMediumFamily,
        color: Colors.white,
        fontWeight: FontWeight.w700,
      );

  // ---------------------------------------------------------
  // Listing type labels (match AddListing)
  // ---------------------------------------------------------
  String get _listingTypeLabel {
    switch (_selectedTabIndex) {
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

  // ---------------------------------------------------------
  // Dropdown data (same as AddListing)
  // ---------------------------------------------------------
  static const String _placeholderProvince = 'Select province';
  static const String _placeholderRegion = 'Select region';
  static const String _placeholderSpeciality = 'Select speciality';

  static const List<String> _provinces = [
    _placeholderProvince,
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

  List<String> get _currentRegions {
    if (_selectedProvince == _placeholderProvince) {
      return const <String>[_placeholderRegion];
    }
    final list = _regionsByProvince[_selectedProvince] ?? const <String>[];
    if (list.isEmpty) return const <String>[_placeholderRegion];
    return <String>[_placeholderRegion, ...list];
  }

  List<String> get _currentSpecialities {
    final label = _listingTypeLabel;
    final list = _subcategories[label] ?? const <String>[];
    if (list.isEmpty) return const <String>[_placeholderSpeciality];
    return <String>[_placeholderSpeciality, ...list];
  }

  // ---------------------------------------------------------
  // Firestore helpers
  // ---------------------------------------------------------
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

  // ✅ Toast matches ExplorePageView / Subby toast style
  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    final theme = FlutterFlowTheme.of(context);

    final IconData icon =
        error ? Icons.error_outline_rounded : Icons.check_rounded;

    final Color accent = error ? theme.error : theme.primary;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          elevation: 0,
          backgroundColor: theme.secondaryBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: error ? theme.error.withOpacity(0.35) : theme.alternate,
              width: 1,
            ),
          ),
          duration: const Duration(milliseconds: 1400),
          content: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: theme.bodySmall.override(
                    fontFamily: theme.bodySmallFamily,
                    color: theme.primaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<DocumentReference?> _findMyListingRef() async {
    final userRef = currentUserReference;
    final uid = currentUserUid;

    if (userRef == null && (uid == null || uid.isEmpty)) return null;

    final coll = (widget.listingCollectionName ?? 'subby_listings').trim();
    final ownerRefField = (widget.listingOwnerRefField ?? 'ownerRef').trim();
    final ownerIdField = (widget.listingOwnerIdField ?? 'ownerId').trim();

    final colRef = FirebaseFirestore.instance.collection(coll);

    if (userRef != null && ownerRefField.isNotEmpty) {
      final snap =
          await colRef.where(ownerRefField, isEqualTo: userRef).limit(1).get();
      if (snap.docs.isNotEmpty) return snap.docs.first.reference;
    }

    if (uid != null && uid.isNotEmpty && ownerIdField.isNotEmpty) {
      final snap =
          await colRef.where(ownerIdField, isEqualTo: uid).limit(1).get();
      if (snap.docs.isNotEmpty) return snap.docs.first.reference;
    }

    return null;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _loadListingDoc() async {
    DocumentReference? ref = widget.listingRef;
    ref ??= await _findMyListingRef();
    if (ref == null) return null;

    final snap = await ref.get();
    if (!snap.exists) return null;
    return snap as DocumentSnapshot<Map<String, dynamic>>;
  }

  int _tabIndexFromCategory(String category) {
    final c = category.trim();
    if (c == 'Professionals') return 0;
    if (c == 'Trades') return 1;
    if (c == 'Suppliers') return 2;
    if (c == 'Associations') return 3;
    return 0;
  }

  void _hydrateFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    if (_didHydrate) return;

    String s(dynamic v) => (v == null) ? '' : v.toString().trim();
    final data = doc.data() ?? <String, dynamic>{};

    final category = s(data['category']);
    _selectedTabIndex = _tabIndexFromCategory(category);

    _nameCtrl.text = s(data['name']);
    _aboutCtrl.text = s(data['about']);
    _phoneCtrl.text = s(data['phoneNumber']);
    _whatsCtrl.text = s(data['whatsappNumber']);
    _emailCtrl.text = s(data['email']);
    _suburbCtrl.text = s(data['suburb']);

    final prov = s(data['province']);
    final city = s(data['city']);
    final spec = s(data['speciality']);

    _selectedProvince = _provinces.contains(prov) ? prov : (_provinces.first);

    // ✅ ensure region is valid for selected province
    final regions = _regionsByProvince[_selectedProvince] ?? const <String>[];
    _selectedRegion = regions.contains(city) ? city : _placeholderRegion;

    // ✅ Speciality must match current category list
    final currentSpecs = _subcategories[_listingTypeLabel] ?? const <String>[];
    _selectedSpeciality =
        currentSpecs.contains(spec) ? spec : _placeholderSpeciality;

    _didHydrate = true;
  }

  bool _validate() {
    final name = _nameCtrl.text.trim();
    final about = _aboutCtrl.text.trim();

    if (name.isEmpty) {
      _toast('Please enter your business name.', error: true);
      return false;
    }
    if (_selectedProvince == _placeholderProvince) {
      _toast('Please select a province.', error: true);
      return false;
    }
    if (_selectedRegion == _placeholderRegion) {
      _toast('Please select a city / region.', error: true);
      return false;
    }
    if (_selectedSpeciality == _placeholderSpeciality) {
      _toast('Please select a speciality.', error: true);
      return false;
    }
    if (about.isEmpty) {
      _toast('Please add a short description (About).', error: true);
      return false;
    }
    return true;
  }

  Future<void> _save(DocumentReference ref) async {
    if (_saving) return;
    if (!_validate()) return;

    setState(() => _saving = true);

    try {
      final now = Timestamp.now();

      final name = _nameCtrl.text.trim();
      final about = _aboutCtrl.text.trim();

      final phone = _phoneCtrl.text.trim();
      final whatsapp = _whatsCtrl.text.trim();
      final email = _emailCtrl.text.trim();

      final province = _selectedProvince.trim();
      final city = _selectedRegion.trim();
      final suburb = _suburbCtrl.text.trim();

      final category = _listingTypeLabel;
      final speciality = _selectedSpeciality.trim();

      final categorySlug = _slugify(category);
      final specialitySlug = _slugify(speciality);
      final provinceSlug = _slugify(province);

      final updateData = <String, dynamic>{
        'name': name,
        'about': about,
        'category': category,
        'categorySlug': categorySlug,
        'speciality': speciality,
        'specialitySlug': specialitySlug,
        'province': province,
        'provinceSlug': provinceSlug,
        'city': city,
        if (suburb.isNotEmpty)
          'suburb': suburb
        else
          'suburb': FieldValue.delete(),
        if (phone.isNotEmpty)
          'phoneNumber': phone
        else
          'phoneNumber': FieldValue.delete(),
        if (whatsapp.isNotEmpty)
          'whatsappNumber': whatsapp
        else
          'whatsappNumber': FieldValue.delete(),
        if (email.isNotEmpty) 'email': email else 'email': FieldValue.delete(),
        'updatedAt': now,
      };

      await ref.update(updateData);

      if (!mounted) return;
      _toast('Listing updated!');
      context.pop();
    } catch (e) {
      debugPrint('⚠️ save listing failed: $e');
      _toast('Save failed. Check rules/connection.', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _aboutCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _whatsCtrl.dispose();
    _suburbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    final double width = widget.width ?? MediaQuery.sizeOf(context).width;
    final double height = widget.height ?? MediaQuery.sizeOf(context).height;

    // ✅ remove SafeArea white bands: handle insets manually (same approach as your other pages)
    final insets = MediaQuery.of(context).padding;
    final topInset = insets.top;
    final bottomInset = insets.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SizedBox(
        width: width,
        height: height,
        child: Container(
          color: theme.primaryBackground,
          child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
            future: _loadListingDoc(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: theme.primary),
                );
              }

              final doc = snapshot.data;
              if (doc == null) return _buildEmptyState(theme);

              _hydrateFromDoc(doc);
              final listingRef = doc.reference;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------------- TOP BAR ----------------
                  Padding(
                    padding:
                        EdgeInsets.fromLTRB(_hPad, topInset + _vPad, _hPad, 12),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => context.pop(),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: theme.secondaryBackground,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: theme.alternate, width: 1),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 20,
                              color: theme.primaryText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit Listing',
                                style: theme.titleLarge.override(
                                  fontFamily: theme.titleLargeFamily,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Update your directory profile',
                                style: _subtitleStyle(theme),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: _saving ? null : () => _save(listingRef),
                          borderRadius: BorderRadius.circular(999),
                          child: Opacity(
                            opacity: _saving ? 0.65 : 1,
                            child: Container(
                              height: 38,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: theme.primary,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _saving
                                        ? Icons.hourglass_top_rounded
                                        : Icons.check_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _saving ? 'Saving' : 'Save',
                                    style: theme.labelMedium.override(
                                      fontFamily: theme.labelMediumFamily,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ---------------- PRIMARY HEADER BLOCK ----------------
                  Container(
                    width: double.infinity,
                    color: theme.primary,
                    padding: const EdgeInsets.fromLTRB(_hPad, 14, _hPad, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Listing type',
                          style: theme.titleMedium.override(
                            fontFamily: theme.titleMediumFamily,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildTypeTabs(),
                        const SizedBox(height: 10),
                        Text(
                          'You are editing a ${_listingTypeLabel.toLowerCase()} listing.',
                          style: theme.bodySmall.override(
                            fontFamily: theme.bodySmallFamily,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ---------------- FORM ----------------
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                          _hPad, 0, _hPad, bottomInset + 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection(
                            title: 'Business details',
                            child: Column(
                              children: [
                                _field(
                                  label: 'Name *',
                                  controller: _nameCtrl,
                                  hint: 'e.g. Acme Builders',
                                ),
                                const SizedBox(height: 12),
                                _dropdownField(
                                  label: 'Speciality *',
                                  value: _selectedSpeciality,
                                  items: _currentSpecialities,
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() => _selectedSpeciality = v);
                                  },
                                ),
                                const SizedBox(height: 12),
                                _field(
                                  label: 'About *',
                                  controller: _aboutCtrl,
                                  hint: 'Short description of your services',
                                  maxLines: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSection(
                            title: 'Contact',
                            child: Column(
                              children: [
                                _field(
                                  label: 'Phone number',
                                  controller: _phoneCtrl,
                                  hint: 'e.g. 082 123 4567',
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 12),
                                _field(
                                  label: 'WhatsApp number',
                                  controller: _whatsCtrl,
                                  hint: 'e.g. 082 123 4567',
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 12),
                                _field(
                                  label: 'Email',
                                  controller: _emailCtrl,
                                  hint: 'e.g. hello@company.co.za',
                                  keyboardType: TextInputType.emailAddress,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSection(
                            title: 'Location',
                            child: Column(
                              children: [
                                _dropdownField(
                                  label: 'Province *',
                                  value: _selectedProvince,
                                  items: _provinces,
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() {
                                      _selectedProvince = v;
                                      _selectedRegion = _placeholderRegion;
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                _dropdownField(
                                  label: 'City / Region *',
                                  value:
                                      _currentRegions.contains(_selectedRegion)
                                          ? _selectedRegion
                                          : _placeholderRegion,
                                  items: _currentRegions,
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() => _selectedRegion = v);
                                  },
                                ),
                                const SizedBox(height: 12),
                                _field(
                                  label: 'Suburb (optional)',
                                  controller: _suburbCtrl,
                                  hint: 'e.g. Sandton',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          _buildPrimaryButton(
                            label: _saving ? 'Saving…' : 'Save changes',
                            icon: _saving
                                ? Icons.hourglass_top_rounded
                                : Icons.check_rounded,
                            onTap: _saving ? () {} : () => _save(listingRef),
                            disabled: _saving,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Tip: keep your description short and specific — this helps you rank better in search.',
                            style: _subtitleStyle(theme),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // =========================================================
  // UI helpers (match AddListing)
  // =========================================================
  Widget _buildTypeTabs() {
    final theme = FlutterFlowTheme.of(context);
    final tabs = ['Professionals', 'Trades', 'Suppliers', 'Associations'];

    return SizedBox(
      height: 54,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: List.generate(tabs.length, (i) {
              final selected = _selectedTabIndex == i;

              return Padding(
                padding: EdgeInsets.only(right: i == tabs.length - 1 ? 0 : 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTabIndex = i;
                      _selectedSpeciality = _placeholderSpeciality;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected ? Colors.white : Colors.white54,
                        width: 1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                                color: Colors.black.withOpacity(0.10),
                              ),
                            ]
                          : const [],
                    ),
                    child: Text(
                      tabs[i],
                      style: _tabTextStyle(theme, selected: selected),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      decoration: _subbyCardDecoration(theme),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _sectionTitleStyle(theme)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    final theme = FlutterFlowTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.labelMedium.override(
            fontFamily: theme.labelMediumFamily,
            color: theme.secondaryText,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.alternate, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: _fieldTextStyle(theme),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: hint,
              hintStyle: _hintTextStyle(theme),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = FlutterFlowTheme.of(context);

    final bool isPlaceholder = value.startsWith('Select ');
    final Color selectedColor =
        isPlaceholder ? theme.secondaryText : theme.primaryText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.labelMedium.override(
            fontFamily: theme.labelMediumFamily,
            color: theme.secondaryText,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.alternate, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: theme.secondaryText),
              dropdownColor: theme.primaryBackground,
              style: _fieldTextStyle(theme).copyWith(color: selectedColor),
              items: items.map((s) {
                final bool itemPlaceholder = s.startsWith('Select ');
                return DropdownMenuItem<String>(
                  value: s,
                  child: Text(
                    s,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _fieldTextStyle(theme).copyWith(
                      color: itemPlaceholder
                          ? theme.secondaryText
                          : theme.primaryText,
                    ),
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

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool disabled = false,
  }) {
    final theme = FlutterFlowTheme.of(context);

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 48,
        width: double.infinity,
        decoration: BoxDecoration(
          color:
              disabled ? theme.secondaryText.withOpacity(0.35) : theme.primary,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: disabled ? Colors.transparent : theme.primary,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: _primaryBtnTextStyle(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(FlutterFlowTheme theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _hPad),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.alternate),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.storefront_outlined, size: 40, color: theme.primary),
              const SizedBox(height: 10),
              Text(
                'No listing found',
                style: theme.titleMedium.override(
                  fontFamily: theme.titleMediumFamily,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'We couldn’t find a listing linked to your account.',
                style: theme.bodyMedium.override(
                  fontFamily: theme.bodyMediumFamily,
                  color: theme.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () => context.pop(),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: theme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Go back',
                    style: theme.labelMedium.override(
                      fontFamily: theme.labelMediumFamily,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
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
}
