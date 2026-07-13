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

import 'index.dart'; // Imports other custom widgets

import 'index.dart'; // Imports other custom widgets

import '/flutter_flow/custom_functions.dart' as functions;

class LocationSelectPageView extends StatefulWidget {
  const LocationSelectPageView({
    super.key,
    this.width,
    this.height,
    this.initialProvince,
    this.initialRegion,
    this.category,
    this.searchText,
  });

  final double? width;
  final double? height;

  final String? initialProvince;
  final String? initialRegion;
  final String? category;
  final String? searchText;

  @override
  State<LocationSelectPageView> createState() => _LocationSelectPageViewState();
}

class _LocationSelectPageViewState extends State<LocationSelectPageView> {
  // ─── SUBBY PALETTE — DIRECTORY (Get-Quotes system) ─────────────────
  static const Color _ink = Color(0xFF1E282E);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _steel = Color(0xFF3F5C69);
  static const Color _lime = Color(0xFFE7E247);
  static const Color _slate = Color(0xFF4E504F);
  static const Color _hairline = Color(0xFFEAEEF0);
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const double _hPad = 22;

  late String _category;
  String? _province;
  String? _city;

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

  @override
  void initState() {
    super.initState();
    _category = (widget.category?.trim().isNotEmpty ?? false)
        ? widget.category!.trim()
        : 'Trades';
    _province = (widget.initialProvince?.trim().isNotEmpty ?? false)
        ? widget.initialProvince!.trim()
        : null;
    _city = (widget.initialRegion?.trim().isNotEmpty ?? false)
        ? widget.initialRegion!.trim()
        : null;
  }

  String _descriptionForCategory(String category) {
    switch (category) {
      case 'Associations':
        return 'Browse associations by location.';
      case 'Professionals':
        return 'Browse professionals by location.';
      case 'Suppliers':
        return 'Browse suppliers by location.';
      case 'Trades':
      default:
        return 'Browse trades by location.';
    }
  }

  List<String> _citiesForProvince(String? province) {
    if (province == null) return const <String>[];
    switch (province) {
      case 'Gauteng':
        return const [
          'Johannesburg',
          'Pretoria',
          'Centurion',
          'Midrand',
          'Sandton',
          'Soweto',
          'East Rand',
          'West Rand',
          'Vaal',
        ];
      case 'Western Cape':
        return const [
          'Cape Town',
          'Stellenbosch',
          'Somerset West',
          'Paarl',
          'George',
          'Knysna',
          'Hermanus',
        ];
      case 'KwaZulu-Natal':
        return const [
          'Durban',
          'Umhlanga',
          'Pietermaritzburg',
          'Ballito',
          'Richards Bay',
        ];
      case 'Eastern Cape':
        return const ['Gqeberha (Port Elizabeth)', 'East London', 'Mthatha'];
      case 'Free State':
        return const ['Bloemfontein', 'Welkom'];
      case 'North West':
        return const ['Rustenburg', 'Mahikeng', 'Potchefstroom'];
      case 'Limpopo':
        return const ['Polokwane', 'Tzaneen', 'Thohoyandou'];
      case 'Mpumalanga':
        return const [
          'Nelspruit (Mbombela)',
          'Witbank (eMalahleni)',
          'Secunda'
        ];
      case 'Northern Cape':
        return const ['Kimberley', 'Upington'];
      default:
        return const <String>[];
    }
  }

  Future<void> _pickProvince() async {
    final picked = await showModalBottomSheet<String>(
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
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 18, 22, 8),
              child: Text('Province',
                  style: TextStyle(
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
                children: _provinces.map((e) {
                  final selected = e == _province;
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
    if (picked == null) return;
    setState(() {
      _province = picked;
      _city = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double width = widget.width ?? MediaQuery.sizeOf(context).width;
    final double height = widget.height ?? MediaQuery.sizeOf(context).height;
    final double topInset = MediaQuery.of(context).padding.top;

    final cities = _citiesForProvince(_province);
    if (_province != null && cities.isNotEmpty && _city != null) {
      if (!cities.contains(_city)) _city = null;
    }

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(_hPad, 22, _hPad, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _uLabel('PROVINCE'),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: _pickProvince,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: _paper,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _hairline),
                              ),
                              child: Row(children: [
                                const Icon(Icons.map_outlined,
                                    size: 20, color: _slate),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(_province ?? 'Select province',
                                      style: TextStyle(
                                        fontFamily: _bodyFont,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            _province == null ? _faint : _ink,
                                      )),
                                ),
                                const Icon(Icons.expand_more_rounded,
                                    color: _faint),
                              ]),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _uLabel('REGION'),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: _hPad),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _paper,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _hairline),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: cities.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    _province == null
                                        ? 'Select a province first'
                                        : 'No regions configured for $_province.',
                                    style: const TextStyle(
                                        fontFamily: _bodyFont,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _faint),
                                  ),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.zero,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: cities.length,
                                  itemBuilder: (context, index) {
                                    final c = cities[index];
                                    final selected = c == _city;
                                    return InkWell(
                                      onTap: () => setState(() => _city = c),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 15),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? const Color(0xFFF3F6F7)
                                              : _paper,
                                          border: index == cities.length - 1
                                              ? null
                                              : const Border(
                                                  bottom: BorderSide(
                                                      color: _hairline)),
                                        ),
                                        child: Row(children: [
                                          Icon(Icons.location_city_outlined,
                                              size: 19,
                                              color: selected ? _ink : _faint),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(c,
                                                style: TextStyle(
                                                  fontFamily: _bodyFont,
                                                  fontSize: 15,
                                                  fontWeight: selected
                                                      ? FontWeight.w700
                                                      : FontWeight.w600,
                                                  color: selected
                                                      ? _ink
                                                      : _inkMute,
                                                )),
                                          ),
                                          if (selected)
                                            const Icon(
                                                Icons.check_circle_rounded,
                                                size: 20,
                                                color: _ink),
                                        ]),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ),
                    Container(
                      color: _paper,
                      padding: EdgeInsets.fromLTRB(_hPad, 14, _hPad,
                          14 + MediaQuery.of(context).padding.bottom),
                      child: _primaryButton(
                        label: 'Use this location',
                        icon: Icons.check_rounded,
                        onTap: (_province == null)
                            ? null
                            : () {
                                context.pop({
                                  'province': _province,
                                  'region': _city ?? '',
                                  'provinceSlug': _province != null
                                      ? functions.slugify(_province!)
                                      : '',
                                });
                              },
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

  // =========================================================
  // UI helpers
  // =========================================================
  Widget _masthead(double topInset) => Container(
        width: double.infinity,
        color: _steel,
        padding: EdgeInsets.fromLTRB(_hPad, topInset + 10, _hPad, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _circleButton(
                  Icons.arrow_back_ios_new_rounded, () => context.pop()),
              Expanded(
                child: Center(
                  child: Text('LOCATION',
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
            const Text('Choose your area',
                style: TextStyle(
                  fontFamily: _displayFont,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                  height: 1.08,
                  color: _paper,
                )),
            const SizedBox(height: 8),
            Text(_descriptionForCategory(_category),
                style: TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _paper.withOpacity(0.55),
                )),
          ],
        ),
      );

  Widget _uLabel(String text) => Text(text,
      style: const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: _inkMute,
      ));

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

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Opacity(
          opacity: onTap == null ? 0.5 : 1,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: _lime,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: _ink),
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(
                      fontFamily: _bodyFont,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
