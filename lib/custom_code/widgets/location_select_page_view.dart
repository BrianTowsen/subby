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

class LocationSelectPageView extends StatefulWidget {
  const LocationSelectPageView({
    super.key,
    this.width,
    this.height,
    this.initialProvince,
    this.initialRegion, // NEW
    this.category, // Associations / Professionals / Trades / Suppliers
    this.searchText, // optional
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
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  // less-is-more system · ported from Clutch Putt · lime → yellow.
  // Inline = authoritative for this file. Grep `SUBBY PALETTE (LOCK)` to sync.
  //
  // Neutrals
  static const Color _ink = Color(0xFF181C27);
  static const Color _inkSoft = Color(0xFF181C27);
  static const Color _inkMute = Color(0xFF6B7280);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFE3E4E8);
  static const Color _surface2 = Color(0xFFE3E4E8);
  static const Color _hairline = Color(0xFFE3E4E8);
  static const Color _hairlineOnSurface = Color(0xFFD0D2D8);
  // Brand accent — YELLOW. Always ink foreground, never white.
  static const Color _spark = Color(0xFFFFE718); // primary CTA / ranked accent
  static const Color _sparkInk = Color(0xFF181C27);
  static const Color _calm = Color(0xFF9C8A12);
  static const Color _calmInk = Color(0xFFFFFFFF);
  // Status
  static const Color _live =
      Color(0xFFFFB000); // gold — live / open-now / warning
  static const Color _steel = Color(0xFF9DA8B5);
  static const Color _coral = Color(0xFFC8102E);
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

  late String _category;
  String? _province;
  String? _city;

  // =========================================================
  // ✅ TYPOGRAPHY (locked palette — explicit family + colour)
  // =========================================================
  TextStyle get _appTitleStyle => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        height: 1.05,
        color: _ink,
      );

  TextStyle get _descStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 13,
        color: _inkMute,
      );

  TextStyle get _sectionLabelStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: _ink,
      );

  TextStyle _chipTextStyle({required bool selected}) => TextStyle(
        fontFamily: _bodyFont,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: selected ? _paper : _inkMute,
      );

  TextStyle get _regionRowTextStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _ink,
      );

  TextStyle get _ctaTextStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _sparkInk, // ink-on-yellow
      );

  TextStyle get _infoTitleStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _ink,
      );

  TextStyle get _infoSubtitleStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 12,
        color: _inkMute,
      );
  // =========================================================

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

    final provinces = const [
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

    final cities = _citiesForProvince(_province);

    if (_province != null && cities.isNotEmpty && _city != null) {
      if (!cities.contains(_city)) {
        _city = null;
      }
    }

    return SizedBox(
      width: width,
      height: height,
      child: SafeArea(
        child: Container(
          color: _paper,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- TOP BAR ----------
              Padding(
                padding: const EdgeInsets.fromLTRB(_hPad, _vPad, _hPad, 10),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(_rMed),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: _ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Choose your area',
                        style: _appTitleStyle,
                      ),
                    ),
                  ],
                ),
              ),

              // ---------- DESCRIPTION ----------
              Padding(
                padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 16),
                child: Text(
                  _descriptionForCategory(_category),
                  style: _descStyle,
                ),
              ),

              // ---------- PROVINCE ----------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: Text('Province', style: _sectionLabelStyle),
              ),
              const SizedBox(height: 8),

              SizedBox(
                height: 40,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: _hPad),
                  scrollDirection: Axis.horizontal,
                  itemCount: provinces.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final p = provinces[index];
                    final selected = p == _province;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _province = p;
                          _city = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: selected ? _ink : _paper,
                          borderRadius: BorderRadius.circular(_rPill),
                          border: Border.all(
                            color: selected ? _ink : _hairline,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            p,
                            style: _chipTextStyle(selected: selected),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 18),

              // ---------- REGION ----------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: Text('Region', style: _sectionLabelStyle),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 24),
                  itemCount: cities.isEmpty ? 1 : cities.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (cities.isEmpty) {
                      return _infoCard(
                        context,
                        title: _province == null
                            ? 'Select a province first'
                            : 'No regions configured',
                        subtitle: _province == null
                            ? 'Choose a province to continue.'
                            : 'Add regions for $_province later.',
                      );
                    }

                    final c = cities[index];
                    final selected = c == _city;

                    return GestureDetector(
                      onTap: () => setState(() => _city = c),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selected ? _surface : _paper,
                          borderRadius: BorderRadius.circular(_rLarge),
                          border: Border.all(
                            color: selected ? _ink : _hairline,
                            width: selected ? 1.2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_city_rounded,
                              size: 20,
                              color: _inkMute,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                c,
                                style: _regionRowTextStyle,
                              ),
                            ),
                            if (selected)
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: _ink,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ---------- CTA (primary action — yellow, ink-on-yellow) ----------
              Padding(
                padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 18),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _spark,
                      foregroundColor: _sparkInk,
                      disabledBackgroundColor: _surface,
                      disabledForegroundColor: _inkMute,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_rMed),
                      ),
                      elevation: 0,
                    ),
                    onPressed: (_province == null)
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
                    child: Text(
                      'Use this location',
                      style: _ctaTextStyle,
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

  Widget _infoCard(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(_rLarge),
        border: Border.all(color: _hairlineOnSurface, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _infoTitleStyle),
          const SizedBox(height: 4),
          Text(subtitle, style: _infoSubtitleStyle),
        ],
      ),
    );
  }
}
