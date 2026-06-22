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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GetQuotesPageView extends StatefulWidget {
  const GetQuotesPageView({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<GetQuotesPageView> createState() => _GetQuotesPageViewState();
}

class _GetQuotesPageViewState extends State<GetQuotesPageView> {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  // Synced with DashboardPageView / AddProjectsPageView (flat teal system).
  // Inline = authoritative for this file. Grep `SUBBY PALETTE (LOCK)` to sync.
  //
  // Neutrals
  static const Color _ink = Color(0xFF017374); // text, chrome, accent
  static const Color _inkMute = Color(0xFF5A6675);
  static const Color _faint = Color(0xFF93A0B0);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFEEF1F4);
  static const Color _hairline = Color(0xFFEEF1F2);
  static const Color _hairlineOnSurface = Color(0xFFE2E7EE);
  // Brand accent — TEAL.
  static const Color _teal = Color(0xFF017374);
  static const Color _tealTint = Color(0xFFE3F4F2);
  // Status
  static const Color _live = Color(0xFFE5771E); // orange
  static const Color _coral = Color(0xFFE5771E);
  // Type
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const String _monoFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = 24;
  static const double _vPad = 14;
  static const double _radius = 12;
  static const double _gap = 12;

  static const String _kActiveProjectPath = 'subby_active_project_path';

  DocumentReference? _projectRef;

  @override
  void initState() {
    super.initState();
    _loadActiveProject();
  }

  Future<void> _loadActiveProject() async {
    final prefs = await SharedPreferences.getInstance();
    final path = (prefs.getString(_kActiveProjectPath) ?? '').trim();
    if (path.isEmpty) return;

    if (mounted) {
      setState(() => _projectRef = FirebaseFirestore.instance.doc(path));
    }
  }

  void _handleBack() {
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  // Accent (theme token override → falls back to teal ink).
  Color _quotesColour(FlutterFlowTheme theme) {
    try {
      final c = (theme as dynamic).getQuotesColour as Color?;
      return c ?? _ink;
    } catch (_) {
      return _ink;
    }
  }

  // =========================================================
  // ✅ TYPOGRAPHY (flat teal system)
  // =========================================================
  TextStyle _pageTitle(FlutterFlowTheme t) => t.titleLarge.override(
        fontFamily: _displayFont,
        color: _ink,
        fontWeight: FontWeight.w900,
        fontSize: 30,
        lineHeight: 1.05,
        letterSpacing: -0.5,
      );

  TextStyle _pageSubtitle(FlutterFlowTheme t) => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: _faint,
      );

  TextStyle _uLabel(FlutterFlowTheme t) => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: _inkMute,
      );

  TextStyle _metaStyle(FlutterFlowTheme t) => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: _faint,
      );

  Widget _minBack() => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleBack,
          borderRadius: BorderRadius.circular(999),
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
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

  Widget _flatCard(Widget child,
          {EdgeInsets padding = const EdgeInsets.all(16),
          Color? fill,
          Color? border}) =>
      Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: fill ?? _paper,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: border ?? _hairline),
        ),
        child: child,
      );

  // Soft-tint pill (teal/orange/grey).
  Widget _softPill(String text, {required Color fg, required Color bg}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: _bodyFont,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ).copyWith(color: fg),
        ),
      );

  // -----------------------------
  // ✅ Project tile (flat, hairline)
  // -----------------------------
  Widget _projectTile({
    required FlutterFlowTheme theme,
    required Color accent,
    required String name,
    required String location,
    required String status,
    required String lastUpdated,
    IconData icon = Icons.request_quote_outlined,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_radius),
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                FocusScope.of(context).unfocus();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) onTap();
                });
              },
        borderRadius: BorderRadius.circular(_radius),
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        child: _flatCard(
          padding: const EdgeInsets.all(14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(icon, size: 22, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (status.trim().isNotEmpty)
                      _softPill(status, fg: _teal, bg: _tealTint),
                    if (status.trim().isNotEmpty) const SizedBox(height: 8),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.titleMedium.override(
                        fontFamily: _displayFont,
                        color: _ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 16, color: _faint),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _metaStyle(theme),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Last updated $lastUpdated',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _metaStyle(theme),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: _faint),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final quotesColour = _quotesColour(theme);

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: _paper,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(_hPad, _vPad, _hPad, _hPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _minBack(),
              const SizedBox(height: 18),
              Text('Get Quotes', style: _pageTitle(theme)),
              const SizedBox(height: 8),
              Text('Request pricing from suppliers',
                  style: _pageSubtitle(theme)),
              const SizedBox(height: 22),
              Text('PROJECTS ADDED', style: _uLabel(theme)),
              const SizedBox(height: 10),
              if (_projectRef == null)
                _flatCard(
                  padding: const EdgeInsets.all(14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.folder_open_rounded,
                          color: _teal, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No project selected',
                              style: theme.titleMedium.override(
                                fontFamily: _displayFont,
                                color: _ink,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                letterSpacing: -0.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Select a project in My Projects to request quotes.',
                              style: _metaStyle(theme),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                StreamBuilder<DocumentSnapshot<Object?>>(
                  stream: _projectRef!.snapshots(),
                  builder: (context, snap) {
                    final raw = snap.data?.data();
                    final data =
                        raw is Map<String, dynamic> ? raw : <String, dynamic>{};

                    final name = (data['name'] ??
                            data['projectName'] ??
                            data['title'] ??
                            'Project')
                        .toString();
                    final status =
                        (data['status'] ?? 'Active').toString().trim();
                    final province = (data['province'] ?? '').toString().trim();
                    final city = (data['city'] ?? '').toString().trim();
                    final location = [city, province]
                        .where((x) => x.trim().isNotEmpty)
                        .join(', ');
                    final updatedAt = data['updatedAt'];
                    final updatedLabel = (updatedAt is Timestamp)
                        ? dateTimeFormat('relative', updatedAt.toDate())
                        : 'recently';

                    return _projectTile(
                      theme: theme,
                      accent: quotesColour,
                      name: name,
                      location: location.isEmpty ? 'South Africa' : location,
                      status: status,
                      lastUpdated: updatedLabel,
                      icon: Icons.request_quote_outlined,
                      onTap: () {},
                    );
                  },
                ),
              const SizedBox(height: _gap),
              _flatCard(
                fill: const Color(0xFFF6F8FA),
                Text(
                  'Get Quotes content coming next.',
                  style: _metaStyle(theme),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: Container()),
            ],
          ),
        ),
      ),
    );
  }
}
