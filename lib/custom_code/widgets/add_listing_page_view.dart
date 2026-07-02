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
  // ─── SUBBY PALETTE — DIRECTORY (amber / sunshine) ──────────────────
  // Directory section colours. Teal is reserved for Projects. The minimal
  // underline layout is ported from AddProjectsPageView (Option C).
  static const Color _amber =
      Color(0xFF29343A); // accent: title, icon, value, CTA
  static const Color _inkMute = Color(0xFF566670); // uppercase micro-labels
  static const Color _faint = Color(0xFF93A3AC); // subtitles / helpers
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _orange = Color(
      0xFF5D737E); // DS green: leading icons / active bookmark (was orange #EB7A02)
  static const Color _green = Color(0xFF5D737E); // DS: verified / info
  static const Color _gold = Color(0xFF5D737E); // DS: rating stars
  static const Color _hairline = Color(0xFFEAEEF0);
  static const Color _rule = Color(0xFFDCE3E6); // underline divider
  // Type
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  // Geometry
  static const double _hPad = 24;
  static const double _vPad = 14;

  // ---------------------------------------------------------
  // Form state
  // ---------------------------------------------------------
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _aboutCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _whatsCtrl = TextEditingController();
  final TextEditingController _suburbCtrl = TextEditingController();
  final TextEditingController _servicesCtrl = TextEditingController();
  final TextEditingController _associationsCtrl = TextEditingController();
  final TextEditingController _hoursCtrl = TextEditingController();

  String _listingType = 'Professionals';
  String _selectedProvince = 'Select province';
  String _selectedRegion = 'Select region';
  String _selectedSpeciality = 'Select speciality';

  bool _isSaving = false;

  // Hero photo: picked in-form, uploaded to Storage on save.
  Uint8List? _heroBytes;
  String? _heroFileName;

  // ---------------------------------------------------------
  // Typography (underline system)
  // ---------------------------------------------------------
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

  TextStyle get _helperStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _faint,
      );

  static const BoxDecoration _uRule = BoxDecoration(
    border: Border(bottom: BorderSide(color: _rule, width: 1)),
  );

  // ---------------------------------------------------------
  // Listing type
  // ---------------------------------------------------------
  static const List<String> _listingTypes = [
    'Professionals',
    'Trades',
    'Suppliers',
    'Associations',
  ];

  String get _listingTypeLabel => _listingType;

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
    final list = _subcategories[_listingTypeLabel] ?? const <String>[];
    if (list.isEmpty) return const <String>[_placeholderSpeciality];
    return <String>[_placeholderSpeciality, ...list];
  }

  // ---------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------
  List<String> _parseList(String raw) =>
      raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

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
          backgroundColor: error ? const Color(0xFF566670) : _amber,
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: _bodyFont,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // ---------------------------------------------------------
  // Hero photo
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

      final services = _parseList(_servicesCtrl.text);
      final associations = _parseList(_associationsCtrl.text);
      final openingHours = _hoursCtrl.text.trim();

      final doc = FirebaseFirestore.instance.collection('subby_listings').doc();

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
        if (services.isNotEmpty) 'services': services,
        if (associations.isNotEmpty) 'associations': associations,
        if (openingHours.isNotEmpty) 'openingHours': openingHours,
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
    _servicesCtrl.dispose();
    _associationsCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = widget.width ?? MediaQuery.sizeOf(context).width;
    final double height = widget.height ?? MediaQuery.sizeOf(context).height;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SizedBox(
        width: width,
        height: height,
        child: Container(
          color: _paper,
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(_hPad, _vPad, _hPad, _vPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _backButton(),
                  const SizedBox(height: 20),
                  Text('Add listing', style: _titleStyle),
                  const SizedBox(height: 8),
                  Text('Create your directory profile.', style: _subtitleStyle),
                  const SizedBox(height: 26),
                  _uSelect(
                    label: 'Listing type',
                    icon: Icons.workspace_premium_outlined,
                    value: _listingType,
                    items: _listingTypes,
                    onChanged: (v) => setState(() {
                      _listingType = v;
                      _selectedSpeciality = _placeholderSpeciality;
                    }),
                  ),
                  _photoRow(),
                  _uText(
                    label: 'Name *',
                    controller: _nameCtrl,
                    icon: Icons.storefront_outlined,
                    hint: 'e.g. Acme Builders',
                  ),
                  _uSelect(
                    label: 'Speciality *',
                    icon: Icons.handyman_outlined,
                    value: _selectedSpeciality,
                    items: _currentSpecialities,
                    onChanged: (v) => setState(() => _selectedSpeciality = v),
                  ),
                  _uText(
                    label: 'About *',
                    controller: _aboutCtrl,
                    icon: Icons.notes_outlined,
                    hint: 'Short description of your services…',
                    maxLines: 4,
                  ),
                  _uText(
                    label: 'Services',
                    controller: _servicesCtrl,
                    icon: Icons.checklist_rounded,
                    hint: 'New installations, Geyser repairs, COC…',
                    maxLines: 2,
                  ),
                  _uText(
                    label: 'Associations',
                    controller: _associationsCtrl,
                    icon: Icons.verified_outlined,
                    hint: 'Master Builders Association, ECA…',
                  ),
                  _uText(
                    label: 'Phone number',
                    controller: _phoneCtrl,
                    icon: Icons.call_outlined,
                    hint: 'e.g. 082 123 4567',
                    keyboardType: TextInputType.phone,
                  ),
                  _uText(
                    label: 'WhatsApp number',
                    controller: _whatsCtrl,
                    icon: Icons.chat_outlined,
                    hint: 'e.g. 082 123 4567',
                    keyboardType: TextInputType.phone,
                  ),
                  _uText(
                    label: 'Email',
                    controller: _emailCtrl,
                    icon: Icons.mail_outlined,
                    hint: 'e.g. hello@company.co.za',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _uText(
                    label: 'Opening hours',
                    controller: _hoursCtrl,
                    icon: Icons.schedule_rounded,
                    hint: 'e.g. 07:00 – 18:00',
                  ),
                  _uSelect(
                    label: 'Province *',
                    icon: Icons.map_outlined,
                    value: _selectedProvince,
                    items: _provinces,
                    onChanged: (v) => setState(() {
                      _selectedProvince = v;
                      _selectedRegion = _placeholderRegion;
                    }),
                  ),
                  _uSelect(
                    label: 'City / Region *',
                    icon: Icons.location_city_outlined,
                    value: _currentRegions.contains(_selectedRegion)
                        ? _selectedRegion
                        : _placeholderRegion,
                    items: _currentRegions,
                    onChanged: (v) => setState(() => _selectedRegion = v),
                  ),
                  _uText(
                    label: 'Suburb (optional)',
                    controller: _suburbCtrl,
                    icon: Icons.place_outlined,
                    hint: 'e.g. Sandton',
                  ),
                  const SizedBox(height: 28),
                  _primaryButton(
                    label: _isSaving ? 'Saving…' : 'Continue',
                    icon: _isSaving
                        ? Icons.hourglass_top_rounded
                        : Icons.arrow_forward_rounded,
                    onTap: _isSaving ? null : _saveListing,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Next: photos, services, tags and verification.',
                    style: _helperStyle,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // UI helpers (underline system)
  // =========================================================
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

  Widget _uText({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    final multiline = maxLines > 1;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: _uRule,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: _uLabelStyle),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: multiline
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(top: multiline ? 3 : 0),
                child: Icon(icon, size: 19, color: _orange),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: !_isSaving,
                  cursorColor: _amber,
                  maxLines: maxLines,
                  keyboardType: keyboardType,
                  style: _valueStyle,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: hint,
                    hintStyle: _hintStyle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _uSelect({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    final safeValue = items.contains(value) ? value : items.first;
    final isPlaceholder = safeValue.startsWith('Select ');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: _uRule,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: _uLabelStyle),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, size: 19, color: _orange),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: safeValue,
                    isExpanded: true,
                    isDense: true,
                    dropdownColor: _paper,
                    icon:
                        const Icon(Icons.expand_more_rounded, color: _inkMute),
                    style: isPlaceholder ? _hintStyle : _valueStyle,
                    items: items
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e,
                            child: Text(
                              e,
                              overflow: TextOverflow.ellipsis,
                              style: e.startsWith('Select ')
                                  ? _hintStyle
                                  : _valueStyle,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _isSaving
                        ? null
                        : (v) {
                            if (v == null) return;
                            onChanged(v);
                          },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _photoRow() {
    final hasPhoto = _heroBytes != null && _heroBytes!.isNotEmpty;
    return InkWell(
      onTap: _isSaving ? null : _pickHeroPhoto,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: _uRule,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('COVER PHOTO', style: _uLabelStyle),
            const SizedBox(height: 8),
            Row(
              children: [
                if (hasPhoto)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(_heroBytes!,
                        width: 44, height: 44, fit: BoxFit.cover),
                  )
                else
                  const Icon(Icons.add_a_photo_outlined,
                      size: 19, color: _orange),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasPhoto ? 'Cover photo added' : 'Add a cover photo',
                    style: hasPhoto ? _valueStyle : _hintStyle,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: _rule),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Opacity(
          opacity: onTap == null ? 0.7 : 1,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: _amber,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: _paper),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _paper,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
