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

class ToDoListPageView extends StatefulWidget {
  const ToDoListPageView({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<ToDoListPageView> createState() => _ToDoListPageViewState();
}

class _ToDoListPageViewState extends State<ToDoListPageView> {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  // Synced with DashboardPageView / AddProjectsPageView (flat teal system).
  // Inline = authoritative for this file. Grep `SUBBY PALETTE (LOCK)` to sync.
  //
  // Neutrals
  static const Color _ink = Color(0xFF017374); // text, chrome, accent
  static const Color _inkMute = Color(0xFF5A6675);
  static const Color _faint = Color(0xFF93A0B0); // muted labels, chevrons
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFEEF1F4);
  static const Color _hairline = Color(0xFFEEF1F2);
  static const Color _hairlineOnSurface = Color(0xFFE2E7EE);
  // Brand accent — TEAL.
  static const Color _teal = Color(0xFF017374);
  static const Color _tealTint = Color(0xFFE3F4F2);
  // Status
  static const Color _live = Color(0xFFE5771E); // orange — done / warning
  static const Color _coral = Color(0xFFE5771E);
  // Type
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const String _monoFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = 24;
  static const double _vPad = 14;
  static const double _radius = 12;

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

  // Minimal circular back button (matches AddProjectsPageView).
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

  // Flat hairline card (no shadow).
  Widget _flatCard(Widget child,
          {EdgeInsets padding = const EdgeInsets.all(16)}) =>
      Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: _hairline),
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

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
              Text('To Do List', style: _pageTitle(theme)),
              const SizedBox(height: 8),
              Text('Tasks and assignments', style: _pageSubtitle(theme)),
              const SizedBox(height: 24),

              // Project preview (proof it’s wired)
              if (_projectRef == null)
                _flatCard(
                  Text(
                    'No project selected.',
                    style: theme.bodyMedium.override(
                      fontFamily: _bodyFont,
                      color: _faint,
                    ),
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

                    return _flatCard(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: theme.titleMedium.override(
                              fontFamily: _displayFont,
                              color: _ink,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'To Do content coming next.',
                            style: theme.bodySmall.override(
                              fontFamily: _bodyFont,
                              color: _faint,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
