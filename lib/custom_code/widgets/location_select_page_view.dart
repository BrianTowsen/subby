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
  // ─── SUBBY PALETTE — DIRECTORY (amber / sunshine) ──────────────────
  static const Color _amber = Color(0xFF323F4D); // accent
  static const Color _sunshine = Color(0xFFC7E87A); // secondary highlight
  static const Color _inkMute = Color(0xFF5A6675); // labels
  static const Color _faint = Color(0xFF93A0B0); // subtitles / unselected
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFEEF1F4);
  static const Color _orange =
      Color(0xFFEB7A02); // DS: leading icons / active bookmark
  static const Color _green = Color(0xFF1F8A5B); // DS: verified / info
  static const Color _gold = Color(0xFFFBB12A); // DS: rating stars
  static const Color _hairline = Color(0xFFEEF1F2);
  static const Color _rule = Color(0xFFE2E7EE);
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const double _hPad = 24;
  static const double _vPad = 14;

  late String _category;
  String? _province;
  String? _city;

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

  static const BoxDecoration _uRule = BoxDecoration(
    border: Border(bottom: BorderSide(color: _rule, width: 1)),
  );

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
        return const [
          'Gqeberha (Port Elizabeth)',
          'East London',
          'Mthatha',
        ];
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

  @override
  Widget build(BuildContext context) {
    final double width = widget.width ?? MediaQuery.sizeOf(context).width;
    final double height = widget.height ?? MediaQuery.sizeOf(context).height;

    final cities = _citiesForProvince(_province);
    if (_province != null && cities.isNotEmpty && _city != null) {
      if (!cities.contains(_city)) _city = null;
    }

    final provinceItems = <String>['Select province', ..._provinces];
    final provinceValue = _province ?? 'Select province';

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        color: _paper,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(_hPad, _vPad, _hPad, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _backButton(),
                    const SizedBox(height: 20),
                    Text('Choose your area', style: _titleStyle),
                    const SizedBox(height: 8),
                    Text(_descriptionForCategory(_category),
                        style: _subtitleStyle),
                    const SizedBox(height: 26),
                    _uSelect(
                      label: 'Province',
                      icon: Icons.map_outlined,
                      value: provinceValue,
                      items: provinceItems,
                      onChanged: (v) {
                        setState(() {
                          _province = v == 'Select province' ? null : v;
                          _city = null;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    Text('REGION', style: _uLabelStyle),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 8),
                  physics: const BouncingScrollPhysics(),
                  itemCount: cities.isEmpty ? 1 : cities.length,
                  itemBuilder: (context, index) {
                    if (cities.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: _uRule,
                        child: Text(
                          _province == null
                              ? 'Select a province first'
                              : 'No regions configured for $_province.',
                          style: _subtitleStyle,
                        ),
                      );
                    }
                    final c = cities[index];
                    final selected = c == _city;
                    return InkWell(
                      onTap: () => setState(() => _city = c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: _uRule,
                        child: Row(
                          children: [
                            Icon(Icons.location_city_outlined,
                                size: 19, color: selected ? _amber : _faint),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                c,
                                style: selected
                                    ? _valueStyle
                                    : const TextStyle(
                                        fontFamily: _bodyFont,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _inkMute,
                                      ),
                              ),
                            ),
                            if (selected)
                              const Icon(Icons.check_circle_rounded,
                                  size: 20, color: _amber),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(_hPad, 8, _hPad, 18),
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
    );
  }

  // =========================================================
  // UI helpers
  // =========================================================
  Widget _backButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.pop(),
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

  Widget _uSelect({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    final safeValue = items.contains(value) ? value : items.first;
    final isPlaceholder = safeValue.startsWith('Select ');
    final hintStyle = const TextStyle(
      fontFamily: _bodyFont,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Color(0xFF94A0AD),
    );
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
                    style: isPlaceholder ? hintStyle : _valueStyle,
                    items: items
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e,
                            child: Text(
                              e,
                              overflow: TextOverflow.ellipsis,
                              style: e.startsWith('Select ')
                                  ? hintStyle
                                  : _valueStyle,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
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
          opacity: onTap == null ? 0.5 : 1,
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
