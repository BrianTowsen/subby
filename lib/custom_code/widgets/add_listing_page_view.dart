// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/flutter_flow/custom_functions.dart' as functions;

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import '/auth/firebase_auth/auth_util.dart';

class AddListingPageView extends StatefulWidget {
  const AddListingPageView({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<AddListingPageView> createState() => _AddListingPageViewState();
}

class _AddListingPageViewState extends State<AddListingPageView> {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  // less-is-more system · ported from Clutch Putt · lime → yellow.
  // Inline = authoritative for this file. Grep `SUBBY PALETTE (LOCK)` to sync.
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
  static const Color _live =
      Color(0xFFFFB000); // gold — live / open-now / warning
  static const Color _coral =
      Color(0xFFC8102E); // legacy red — error/destructive
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

  static const double _hPad = _pageHPad;
  static const double _vPad = _pageHPad;

  static const double _cardRadius = _rLarge;

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _hairline, width: 1),
      );

  // ---------------------------------------------------------
  // Form state
  // ---------------------------------------------------------
  int _selectedTabIndex = 0; // 0..3

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _aboutCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _whatsCtrl = TextEditingController();
  final TextEditingController _suburbCtrl = TextEditingController();

  // ✅ Required dropdown selections
  String _selectedProvince = 'Select province';
  String _selectedRegion = 'Select region';
  String _selectedSpeciality = 'Select speciality';

  bool _isSaving = false;

  // Hero photo: picked in-form, uploaded to Storage on save.
  Uint8List? _heroBytes;
  String? _heroFileName;

  // ---------------------------------------------------------
  // Typography (locked palette — explicit family + colour)
  // ---------------------------------------------------------
  TextStyle get _titleStyle => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        height: 1.05,
        color: _ink,
      );

  TextStyle get _subtitleStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: _inkMute,
      );

  TextStyle get _sectionTitleStyle => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: _ink,
      );

  TextStyle _tabTextStyle({required bool selected}) => TextStyle(
        fontFamily: _bodyFont,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: selected ? _paper : _inkMute,
      );

  TextStyle get _fieldTextStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 14,
        color: _ink,
      );

  TextStyle get _hintTextStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 14,
        color: _inkMute,
      );

  TextStyle get _labelStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _inkMute,
      );

  TextStyle get _primaryBtnTextStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _sparkInk, // ink-on-yellow
      );

  // ---------------------------------------------------------
  // Listing type labels
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
  // Dropdown data
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
  // Firestore wiring
  // ---------------------------------------------------------
  DocumentReference? _currentUserRefOrNull() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(user.uid);
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          backgroundColor: error ? _coral : _ink,
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: _bodyFont,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // ---------------------------------------------------------
  // Hero photo (FilePicker + FirebaseStorage; uploaded on save)
  // ---------------------------------------------------------
  Future<void> _pickHeroPhoto() async {
    if (_isSaving) return;
    FocusScope.of(context).unfocus();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final f = result.files.first;
      final Uint8List? bytes = f.bytes;
      if (bytes == null || bytes.isEmpty) {
        _toast('Could not read that image. Try again.', error: true);
        return;
      }
      setState(() {
        _heroBytes = bytes;
        _heroFileName = f.name;
      });
    } catch (e) {
      debugPrint('\u26a0\ufe0f pick hero failed: $e');
      _toast('Could not pick image.', error: true);
    }
  }

  Widget _buildHeroPhotoPicker() {
    final hasPhoto = _heroBytes != null && _heroBytes!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _isSaving ? null : _pickHeroPhoto,
          borderRadius: BorderRadius.circular(_cardRadius),
          child: Container(
            width: double.infinity,
            height: 170,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(_cardRadius),
              border: Border.all(color: _hairlineOnSurface, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasPhoto
                ? Image.memory(_heroBytes!, fit: BoxFit.cover)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo_outlined,
                          size: 30, color: _inkMute),
                      const SizedBox(height: 8),
                      Text('Add a cover photo', style: _hintTextStyle),
                    ],
                  ),
          ),
        ),
        if (hasPhoto) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: _isSaving ? null : _pickHeroPhoto,
                child: const Text(
                  'Change',
                  style: TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
              ),
              TextButton(
                onPressed: _isSaving
                    ? null
                    : () => setState(() {
                          _heroBytes = null;
                          _heroFileName = null;
                        }),
                child: const Text(
                  'Remove',
                  style: TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _inkMute,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
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

  Future<void> _saveListing() async {
    if (_isSaving) return;
    if (!_validate()) return;

    final userRef = _currentUserRefOrNull();
    if (userRef == null) {
      context.pushNamed('loginPage');
      return;
    }

    setState(() => _isSaving = true);

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

      final categorySlug = functions.slugify(category);
      final specialitySlug = functions.slugify(speciality);
      final provinceSlug = functions.slugify(province);

      final doc = FirebaseFirestore.instance.collection('subby_listings').doc();

      // Upload hero photo (optional) -> users/<uid>/listings/<id>/...
      // (public-read, owner-write under existing Storage rules)
      String heroUrl = '';
      List<String> photoUrls = const <String>[];
      if (_heroBytes != null && _heroBytes!.isNotEmpty) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        final rawName =
            (_heroFileName?.isNotEmpty ?? false) ? _heroFileName! : 'hero.jpg';
        final safeName =
            p.basename(rawName).replaceAll(RegExp(r'[^\w\.\- ]+'), '_');
        final storagePath =
            'users/${userRef.id}/listings/${doc.id}/hero_${ts}_$safeName';
        final contentType =
            lookupMimeType(safeName, headerBytes: _heroBytes) ?? 'image/jpeg';
        final storageRef = FirebaseStorage.instance.ref().child(storagePath);
        await storageRef.putData(
          _heroBytes!,
          SettableMetadata(contentType: contentType),
        );
        heroUrl = await storageRef.getDownloadURL();
        photoUrls = <String>[heroUrl];
      }

      await doc.set({
        'name': name,
        'about': about,
        'category': category,
        'categorySlug': categorySlug,
        'speciality': speciality,
        'specialitySlug': specialitySlug,
        'province': province,
        'provinceSlug': provinceSlug,
        'city': city,
        if (suburb.isNotEmpty) 'suburb': suburb,
        if (phone.isNotEmpty) 'phoneNumber': phone,
        if (whatsapp.isNotEmpty) 'whatsappNumber': whatsapp,
        if (email.isNotEmpty) 'email': email,
        if (heroUrl.isNotEmpty) 'heroPhotoUrl': heroUrl,
        if (photoUrls.isNotEmpty) 'photoUrls': photoUrls,
        'ownerRef': userRef,
        'ownerName': currentUserDisplayName,
        'ownerPhotoUrl': currentUserPhoto,
        'isVerified': false,
        'rating': 0.0,
        'reviewCount': 0,
        'openNow': true,
        'createdAt': now,
        'updatedAt': now,
      });

      if (!mounted) return;

      _toast('Listing created!');
      context.safePop();
    } catch (e) {
      debugPrint('⚠️ create listing failed: $e');
      _toast('Could not create listing. Check rules/connection.', error: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
    final double width = widget.width ?? MediaQuery.sizeOf(context).width;
    final double height = widget.height ?? MediaQuery.sizeOf(context).height;

    return SizedBox(
      width: width,
      height: height,
      child: SafeArea(
        child: Container(
          color: _paper,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(_hPad, _vPad, _hPad, 12),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => context.safePop(),
                      borderRadius: BorderRadius.circular(_rMed),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(_rMed),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: _ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add Listing', style: _titleStyle),
                        const SizedBox(height: 2),
                        Text(
                          'Create your directory profile',
                          style: _subtitleStyle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ---------- LISTING TYPE (contained surface block) ----------
              Padding(
                padding: const EdgeInsets.fromLTRB(_hPad, 4, _hPad, 0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(_rLarge),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Listing type', style: _sectionTitleStyle),
                      const SizedBox(height: 10),
                      _buildTypeTabs(),
                      const SizedBox(height: 10),
                      Text(
                        'You are creating a ${_listingTypeLabel.toLowerCase()} listing.',
                        style: _subtitleStyle,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        title: 'Photo',
                        child: _buildHeroPhotoPicker(),
                      ),
                      const SizedBox(height: 16),
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
                              value: _currentRegions.contains(_selectedRegion)
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
                        label: _isSaving ? 'Saving…' : 'Continue',
                        icon: _isSaving
                            ? Icons.hourglass_top_rounded
                            : Icons.arrow_forward_rounded,
                        onTap: _isSaving ? () {} : _saveListing,
                        disabled: _isSaving,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Next: photos, services, tags and verification.',
                        style: _subtitleStyle,
                      ),
                    ],
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
  // UI helpers
  // =========================================================
  Widget _buildTypeTabs() {
    final tabs = ['Professionals', 'Trades', 'Suppliers', 'Associations'];

    return SizedBox(
      height: 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
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
                    color: selected ? _ink : _paper,
                    borderRadius: BorderRadius.circular(_rPill),
                    border: Border.all(
                      color: selected ? _ink : _hairlineOnSurface,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    tabs[i],
                    style: _tabTextStyle(selected: selected),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _sectionTitleStyle),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(_rMed),
            border: Border.all(color: _hairlineOnSurface, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: _fieldTextStyle,
            cursorColor: _ink,
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: hint,
              hintStyle: _hintTextStyle,
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
    final bool isPlaceholder = value.startsWith('Select ');
    final Color textColor = isPlaceholder ? _inkMute : _ink;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 8),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(_rMed),
            border: Border.all(color: _hairlineOnSurface, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: _inkMute),
              dropdownColor: _paper,
              style: _fieldTextStyle.copyWith(color: textColor),
              items: items.map((s) {
                final bool itemPlaceholder = s.startsWith('Select ');
                return DropdownMenuItem<String>(
                  value: s,
                  child: Text(
                    s,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _fieldTextStyle.copyWith(
                      color: itemPlaceholder ? _inkMute : textColor,
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
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(_rMed),
      child: Container(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          color: disabled ? _surface : _spark,
          borderRadius: BorderRadius.circular(_rMed),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: disabled ? _inkMute : _sparkInk),
            const SizedBox(width: 8),
            Text(
              label,
              style: disabled
                  ? _primaryBtnTextStyle.copyWith(color: _inkMute)
                  : _primaryBtnTextStyle,
            ),
          ],
        ),
      ),
    );
  }
}
