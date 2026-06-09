// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

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
  static const double _hPad = 24;
  static const double _vPad = 24;

  late String _category;
  String? _province;
  String? _city;

  // =========================================================
  // ✅ TYPOGRAPHY (CONSISTENT: token + explicit family, no random weights/sizes)
  // =========================================================
  TextStyle _appTitleStyle(FlutterFlowTheme theme) {
    return theme.titleLarge.copyWith(
      fontWeight: FontWeight.w900, // 🔥 Extra bold
      letterSpacing: 0.2,
    );
  }

  TextStyle _descStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: t.bodySmallFamily,
        color: t.secondaryText,
      );

  TextStyle _sectionLabelStyle(FlutterFlowTheme t) => t.titleSmall.override(
        fontFamily: t.titleSmallFamily,
      );

  TextStyle _chipTextStyle(FlutterFlowTheme t, {required bool selected}) =>
      t.labelMedium.override(
        fontFamily: t.labelMediumFamily,
        // ✅ Province chips: selected on primary should be WHITE (like Home tabs)
        color: selected ? Colors.white : t.secondaryText,
      );

  TextStyle _regionRowTextStyle(FlutterFlowTheme t) => t.bodyMedium.override(
        fontFamily: t.bodyMediumFamily,
      );

  TextStyle _ctaTextStyle(FlutterFlowTheme t) => t.labelLarge.override(
        fontFamily: t.labelLargeFamily,
        color: Colors.white,
      );

  TextStyle _infoTitleStyle(FlutterFlowTheme t) => t.bodyMedium.override(
        fontFamily: t.bodyMediumFamily,
      );

  TextStyle _infoSubtitleStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: t.bodySmallFamily,
        color: t.secondaryText,
      );
  // =========================================================

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
    final theme = FlutterFlowTheme.of(context);

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
          color: theme.primaryBackground,
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
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: theme.secondaryBackground,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.alternate, width: 1),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: theme.secondaryText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Choose your area',
                        // ✅ FIX: was _pageTitleStyle(theme) (method didn't exist)
                        style: _appTitleStyle(theme),
                      ),
                    ),
                  ],
                ),
              ),

              // ---------- DESCRIPTION ----------
              Padding(
                padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 14),
                child: Text(
                  _descriptionForCategory(_category),
                  style: _descStyle(theme),
                ),
              ),

              // ---------- PROVINCE ----------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: Text('Province', style: _sectionLabelStyle(theme)),
              ),
              const SizedBox(height: 8),

              SizedBox(
                height: 42,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: _hPad),
                  scrollDirection: Axis.horizontal,
                  itemCount: provinces.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
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
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: selected
                              ? theme.primary
                              : theme.secondaryBackground,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: selected ? theme.primary : theme.alternate,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            p,
                            style: _chipTextStyle(theme, selected: selected),
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
                child: Text('Region', style: _sectionLabelStyle(theme)),
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
                          color: selected
                              ? theme.secondaryBackground
                              : theme.primaryBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected ? theme.primary : theme.alternate,
                            width: selected ? 1.2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_city_rounded,
                              size: 20,
                              color: theme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                c,
                                style: _regionRowTextStyle(theme),
                              ),
                            ),
                            if (selected)
                              Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: theme.primary,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ---------- CTA ----------
              Padding(
                padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 18),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      elevation: 0,
                    ),
                    onPressed: (_province == null)
                        ? null
                        : () {
                            context.pop({
                              'province': _province,
                              'region': _city ?? '',
                              'provinceSlug':
                                  _province != null ? _slugify(_province!) : '',
                            });
                          },
                    child: Text(
                      'Use this location',
                      style: _ctaTextStyle(theme),
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
    final theme = FlutterFlowTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.alternate, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _infoTitleStyle(theme)),
          const SizedBox(height: 4),
          Text(subtitle, style: _infoSubtitleStyle(theme)),
        ],
      ),
    );
  }
}
