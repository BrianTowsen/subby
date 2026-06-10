// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

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
      Color(0xFFFFB000); // gold — live / paid / done / warning
  static const Color _coral = Color(0xFFC8102E);
  // Type
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const String _monoFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = 24;
  static const double _vPad = 24;
  static const double _radius = 16;
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

  // -----------------------------
  // Theme helpers
  // -----------------------------
  Color _quotesColour(FlutterFlowTheme theme) {
    // Try FF custom color "GetQuotesColour" -> getter typically getQuotesColour
    // If you don't have it, it safely falls back to _ink.
    try {
      final c = (theme as dynamic).getQuotesColour as Color?;
      return c ?? _ink;
    } catch (_) {
      return _ink;
    }
  }

  // -----------------------------
  // Typography
  // -----------------------------
  TextStyle _titleStyle(FlutterFlowTheme theme) {
    return theme.titleLarge.override(
      fontFamily: _displayFont,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.2,
    );
  }

  TextStyle _subtitleStyle(FlutterFlowTheme theme) {
    return theme.bodySmall.override(
      fontFamily: _bodyFont,
      color: _inkMute,
    );
  }

  TextStyle _sectionTitleStyle(FlutterFlowTheme t) => t.titleMedium.override(
        fontFamily: _displayFont,
      );

  TextStyle _metaStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: _bodyFont,
        color: _inkMute,
      );

  TextStyle _cardTitleStyle(FlutterFlowTheme t) => t.bodyMedium.override(
        fontFamily: _bodyFont,
      );

  // -----------------------------
  // Subby card shell
  // -----------------------------
  Widget _cardShell(FlutterFlowTheme theme, Widget child,
      {EdgeInsets padding = const EdgeInsets.all(16)}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _hairline.withOpacity(0.9)),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Padding(padding: padding, child: child),
      ),
    );
  }

  // ✅ outlined status pill (matches MyProjects/Timeline)
  Widget _statusPillOutlined({
    required FlutterFlowTheme theme,
    required Color accent,
    required String text,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 140),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: accent.withOpacity(0.28),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.labelSmall.override(
                  fontFamily: _bodyFont,
                  color: accent,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------
  // ✅ Project tile/card (MATCHES MyProjects design)
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

        // ✅ kill splash/highlight/overlay (flicker)
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),

        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            boxShadow: [
              BoxShadow(
                blurRadius: 16,
                offset: const Offset(0, 10),
                color: Colors.black.withOpacity(0.08),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius),
            child: Container(
              color: _paper,
              child: Row(
                children: [
                  Container(width: 4, color: accent),
                  const SizedBox(width: 10),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(_radius),
                    ),
                    child: Icon(icon, size: 22, color: _paper),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (status.trim().isNotEmpty)
                            _statusPillOutlined(
                              theme: theme,
                              accent: accent,
                              text: status,
                            ),
                          if (status.trim().isNotEmpty)
                            const SizedBox(height: 6),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _cardTitleStyle(theme).copyWith(
                              color: _ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 16, color: _inkMute),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _metaStyle(theme).copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Last updated $lastUpdated',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _metaStyle(theme).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: _inkMute),
                  const SizedBox(width: 10),
                ],
              ),
            ),
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
          padding:
              const EdgeInsets.symmetric(horizontal: _hPad, vertical: _vPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  InkWell(
                    onTap: _handleBack,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _paper,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _hairline.withOpacity(0.9),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 22,
                        color: _ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: quotesColour,
                      borderRadius: BorderRadius.circular(_radius),
                    ),
                    child: const Icon(
                      Icons.request_quote_outlined,
                      size: 22,
                      color: _paper,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Get Quotes',
                          style: _titleStyle(theme).copyWith(color: _ink),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Request pricing from suppliers',
                          style: _subtitleStyle(theme),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ✅ Heading (same as other modules)
              Text(
                'Projects added',
                style: _sectionTitleStyle(theme).copyWith(
                  color: _ink,
                ),
              ),
              const SizedBox(height: 10),

              // Project preview (proof it’s wired) — UPDATED tile design
              if (_projectRef == null)
                _cardShell(
                  theme,
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: quotesColour.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(_radius),
                        ),
                        child: Icon(Icons.folder_open_rounded,
                            color: quotesColour, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No project selected',
                              style: _cardTitleStyle(theme).copyWith(
                                color: _ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Select a project in My Projects to request quotes.',
                              style: _metaStyle(theme)
                                  .copyWith(fontWeight: FontWeight.w600),
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
                      onTap: () {
                        // No destination yet — keep it wired for later.
                        // For now, just remove keyboard focus (already done) and do nothing.
                      },
                    );
                  },
                ),

              const SizedBox(height: _gap),

              _cardShell(
                theme,
                Text(
                  'Get Quotes content coming next.',
                  style:
                      _metaStyle(theme).copyWith(fontWeight: FontWeight.w600),
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
