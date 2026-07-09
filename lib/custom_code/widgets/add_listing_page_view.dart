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

import '/flutter_flow/custom_functions.dart' as functions;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/auth/firebase_auth/auth_util.dart';

class AddListingPageView extends StatefulWidget {
  const AddListingPageView({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<AddListingPageView> createState() => _AddListingPageViewState();
}

class _AddListingPageViewState extends State<AddListingPageView> {
  // ─── SUBBY PALETTE — DIRECTORY (Get-Quotes system) ─────────────────
  static const Color _ink = Color(0xFF29343A);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _steel = Color(0xFF455861);
  static const Color _lime = Color(0xFFE7E247);
  static const Color _slate = Color(0xFF5D737E);
  static const Color _hairline = Color(0xFFEAEEF0);
  static const Color _hairlineOnSurface = Color(0xFFDCE3E6);
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const double _hPad = 22;

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

  static const String _placeholderProvince = 'Select province';
  static const String _placeholderRegion = 'Select region';
  static const String _placeholderSpeciality = 'Select speciality';

  static const List<String> _listingTypes = [
    'Professionals',
    'Trades',
    'Suppliers',
    'Associations',
  ];

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
    'Eastern Cape': ['Gqeberha (Port Elizabeth)', 'East London', 'Mthatha'],
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

  List<String> get _currentRegions =>
      _regionsByProvince[_selectedProvince] ?? const <String>[];

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

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        backgroundColor: _ink,
        content: Text(msg,
            style: const TextStyle(
                fontFamily: _bodyFont,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ));
  }

  List<String> _parseList(String raw) => raw
      .split(RegExp(r'[,\n]'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  String get _listingTypeLabel => _listingType;

  bool _validate() {
    if (_nameCtrl.text.trim().isEmpty) {
      _toast('Please enter your business name.', error: true);
      return false;
    }
    if (_selectedSpeciality == _placeholderSpeciality) {
      _toast('Please pick a speciality.', error: true);
      return false;
    }
    if (_aboutCtrl.text.trim().isEmpty) {
      _toast('Please add a short description.', error: true);
      return false;
    }
    if (_selectedProvince == _placeholderProvince) {
      _toast('Please pick a province.', error: true);
      return false;
    }
    if (_selectedRegion == _placeholderRegion) {
      _toast('Please pick a city / region.', error: true);
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (_isSaving || !_validate()) return;
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
      final provinceSlug = functions.slugify(province);
      final categorySlug = functions.slugify(category);
      final specialitySlug = functions.slugify(speciality);
      final services = _parseList(_servicesCtrl.text);
      final associations = _parseList(_associationsCtrl.text);
      final openingHours = _hoursCtrl.text.trim();

      final doc = FirebaseFirestore.instance.collection('subby_listings').doc();
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
        'suburb': suburb,
        'phoneNumber': phone,
        'whatsappNumber': whatsapp,
        'email': email,
        'services': services,
        'associations': associations,
        'openingHours': openingHours,
        'ownerRef': currentUserReference,
        'ownerId': currentUserUid,
        'isVerified': false,
        'rating': 0,
        'createdAt': now,
        'updatedAt': now,
      });

      if (!mounted) return;
      _toast('Listing saved.');
      final nav = Navigator.of(context);
      if (nav.canPop()) nav.pop();
    } catch (e) {
      debugPrint('⚠️ save listing failed: $e');
      _toast('Could not save listing.', error: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
                children: items.where((e) => !e.startsWith('Select ')).map((e) {
                  final selected = e == current;
                  return InkWell(
                    onTap: () => Navigator.of(ctx).pop(e),
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

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SizedBox(
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
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(_hPad, 22, _hPad,
                        24 + MediaQuery.of(context).padding.bottom),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _uLabel('LISTING TYPE'),
                        const SizedBox(height: 10),
                        _selectCard(
                          icon: Icons.workspace_premium_outlined,
                          value: _listingType,
                          onTap: () async {
                            final v = await _pickFromSheet(
                                'Listing type', _listingTypes, _listingType);
                            if (v != null) {
                              setState(() {
                                _listingType = v;
                                _selectedSpeciality = _placeholderSpeciality;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        _uLabel('PHOTOS'),
                        const SizedBox(height: 10),
                        Row(children: [
                          Container(
                            width: 76,
                            height: 76,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _paper,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: _hairlineOnSurface, width: 1.5),
                            ),
                            child: const Icon(Icons.add_a_photo_outlined,
                                size: 24, color: _faint),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 76,
                            height: 76,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: _surface,
                                borderRadius: BorderRadius.circular(14)),
                            child: const Icon(Icons.image_outlined,
                                size: 24, color: Color(0xFFC6D0D5)),
                          ),
                        ]),
                        const SizedBox(height: 20),
                        _uLabel('DETAILS'),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: _paper,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _hairline),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(children: [
                            _textField('Name *', Icons.storefront_outlined,
                                _nameCtrl, 'e.g. Acme Builders'),
                            _pickerField(
                              'Speciality *',
                              Icons.handyman_outlined,
                              _selectedSpeciality,
                              () async {
                                final list =
                                    _subcategories[_listingType] ?? const [];
                                final v = await _pickFromSheet(
                                    'Speciality', list, _selectedSpeciality);
                                if (v != null) {
                                  setState(() => _selectedSpeciality = v);
                                }
                              },
                            ),
                            _textField(
                                'About *',
                                Icons.notes_outlined,
                                _aboutCtrl,
                                'Short description of your services…',
                                maxLines: 3),
                            _textField(
                                'Services',
                                Icons.checklist_rounded,
                                _servicesCtrl,
                                'New installations, Geyser repairs…',
                                maxLines: 2),
                            _textField(
                                'Associations',
                                Icons.verified_outlined,
                                _associationsCtrl,
                                'Master Builders Association, ECA…'),
                            _textField('Phone number', Icons.call_outlined,
                                _phoneCtrl, 'e.g. 082 123 4567',
                                keyboard: TextInputType.phone),
                            _textField('WhatsApp number', Icons.chat_outlined,
                                _whatsCtrl, 'e.g. 082 123 4567',
                                keyboard: TextInputType.phone),
                            _textField('Email', Icons.mail_outlined, _emailCtrl,
                                'e.g. hello@company.co.za',
                                keyboard: TextInputType.emailAddress),
                            _textField('Opening hours', Icons.schedule_rounded,
                                _hoursCtrl, 'e.g. 07:00 – 18:00'),
                            _pickerField(
                              'Province *',
                              Icons.map_outlined,
                              _selectedProvince,
                              () async {
                                final v = await _pickFromSheet(
                                    'Province', _provinces, _selectedProvince);
                                if (v != null) {
                                  setState(() {
                                    _selectedProvince = v;
                                    _selectedRegion = _placeholderRegion;
                                  });
                                }
                              },
                            ),
                            _pickerField(
                              'City / Region *',
                              Icons.location_city_outlined,
                              _selectedRegion,
                              () async {
                                if (_currentRegions.isEmpty) {
                                  _toast('Pick a province first.');
                                  return;
                                }
                                final v = await _pickFromSheet('City / Region',
                                    _currentRegions, _selectedRegion);
                                if (v != null) {
                                  setState(() => _selectedRegion = v);
                                }
                              },
                            ),
                            _textField(
                                'Suburb (optional)',
                                Icons.place_outlined,
                                _suburbCtrl,
                                'e.g. Sandton',
                                divider: false),
                          ]),
                        ),
                        const SizedBox(height: 24),
                        InkWell(
                          onTap: _isSaving ? null : _save,
                          borderRadius: BorderRadius.circular(14),
                          child: Opacity(
                            opacity: _isSaving ? 0.6 : 1,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                  color: _lime,
                                  borderRadius: BorderRadius.circular(14)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                      _isSaving
                                          ? Icons.hourglass_top_rounded
                                          : Icons.arrow_forward_rounded,
                                      size: 18,
                                      color: _ink),
                                  const SizedBox(width: 8),
                                  Text(_isSaving ? 'Saving…' : 'Continue',
                                      style: const TextStyle(
                                          fontFamily: _bodyFont,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: _ink)),
                                ],
                              ),
                            ),
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

  Widget _selectCard({
    required IconData icon,
    required String value,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _hairline),
          ),
          child: Row(children: [
            Icon(icon, size: 20, color: _slate),
            const SizedBox(width: 12),
            Expanded(
                child: Text(value,
                    style: const TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _ink))),
            const Icon(Icons.expand_more_rounded, color: _faint),
          ]),
        ),
      );

  Widget _pickerField(
      String label, IconData icon, String value, VoidCallback onTap) {
    final isPlaceholder = value.startsWith('Select ');
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _hairline)),
        ),
        child: Row(children: [
          Icon(icon, size: 19, color: _slate),
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
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isPlaceholder ? _faint : _ink)),
              ],
            ),
          ),
          const Icon(Icons.expand_more_rounded, color: _faint),
        ]),
      ),
    );
  }

  Widget _textField(
    String label,
    IconData icon,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboard,
    bool divider = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border:
            divider ? const Border(bottom: BorderSide(color: _hairline)) : null,
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 19, color: _slate),
        ),
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
              const SizedBox(height: 2),
              TextField(
                controller: controller,
                maxLines: maxLines,
                keyboardType: keyboard,
                cursorColor: _ink,
                style: const TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _ink),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: hint,
                  hintStyle: const TextStyle(
                      fontFamily: _bodyFont,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _faint),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _masthead(double topInset) => Container(
        width: double.infinity,
        color: _steel,
        padding: EdgeInsets.fromLTRB(_hPad, topInset + 10, _hPad, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.safePop(),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: _paper.withOpacity(0.12),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 16, color: _paper),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text('NEW LISTING',
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
            const Text('Add listing',
                style: TextStyle(
                  fontFamily: _displayFont,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                  height: 1.08,
                  color: _paper,
                )),
            const SizedBox(height: 8),
            Text('Create your directory profile.',
                style: TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _paper.withOpacity(0.55),
                )),
          ],
        ),
      );
}
