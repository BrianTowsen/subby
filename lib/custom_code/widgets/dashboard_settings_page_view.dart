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

// =================== DashboardSettingsPageView (FULL FILE) ===================

import 'package:shared_preferences/shared_preferences.dart';

class DashboardSettingsPageView extends StatefulWidget {
  const DashboardSettingsPageView({
    super.key,
    this.width,
    this.height,

    /// Optional: go back route (if you prefer route pop, you can ignore this)
    this.backRouteName,
  });

  final double? width;
  final double? height;

  final String? backRouteName;

  @override
  State<DashboardSettingsPageView> createState() =>
      _DashboardSettingsPageViewState();
}

class _DashboardSettingsPageViewState extends State<DashboardSettingsPageView> {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  // less-is-more system · ported from Clutch Putt · lime → yellow.
  // Inline = authoritative for this file. Grep `SUBBY PALETTE (LOCK)` to sync.
  //
  // Neutrals
  static const Color _ink = Color(0xFF1E282E);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _hairline = Color(0xFFEAEEF0);
  static const Color _hairlineOnSurface = Color(0xFFDCE3E6);
  // Brand accent — YELLOW. Always ink foreground, never white.
  static const Color _spark = Color(0xFFE7E247); // primary CTA / ranked accent
  static const Color _sparkInk = Color(0xFF1E282E);
  // Status
  static const Color _live =
      Color(0xFFAC0C0C); // red — live / warning / destructive
  static const Color _coral = Color(0xFFAC0C0C);
  // Type
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const String _monoFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = 24;
  static const double _radius = 12;
  static const double _gap = 12;
  static const double _tileH = 72;

  // ✅ Must match DashboardPageView
  static const String _kPrefsOrderKey = 'subby_dashboard_tile_order_v7';
  static const String _kPrefsVisibleKey = 'subby_dashboard_visible_tiles_v1';

  // Tile IDs
  static const String _tProjects = 'projects';
  static const String _tTimeline = 'timeline';
  static const String _tTodo = 'todo';
  static const String _tProjectCost = 'projectCost';
  static const String _tGetQuotes = 'getQuotes';
  static const String _tSnag = 'snag';
  static const String _tDirectory = 'directory';

  static const List<String> _defaultOrder = [
    _tProjects,
    _tTimeline,
    _tTodo,
    _tProjectCost,
    _tGetQuotes,
    _tSnag,
    _tDirectory,
  ];

  static const Map<String, String> _labels = {
    _tProjects: 'My Projects',
    _tTimeline: 'Timeline',
    _tTodo: 'Todo List',
    _tProjectCost: 'Project Cost',
    _tGetQuotes: 'Get Quotes',
    _tSnag: 'Snag List',
    _tDirectory: 'Directory',
  };

  List<String> _tileOrder = List<String>.from(_defaultOrder);
  Set<String> _visibleTiles = Set<String>.from(_defaultOrder);

  bool _loading = true;

  // -----------------------------
  // Typography (Subby style)
  // -----------------------------
  TextStyle _titleStyle(FlutterFlowTheme t) => t.titleLarge.override(
        fontFamily: _displayFont,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.2,
      );

  TextStyle _subtitleStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: _bodyFont,
        color: _inkMute,
      );

  TextStyle _rowTitleStyle(FlutterFlowTheme t) => t.bodyMedium.override(
        fontFamily: _bodyFont,
        fontWeight: FontWeight.w800,
        color: _ink,
      );

  TextStyle _rowMetaStyle(FlutterFlowTheme t) => t.labelSmall.override(
        fontFamily: _bodyFont,
        color: _inkMute,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initPrefs();
    });
  }

  // -----------------------------
  // ✅ Order normalization (ORDER ONLY!)
  // -----------------------------
  List<String> _normalizeOrder(List<String> input) {
    final seen = <String>{};
    final out = <String>[];

    for (final id in input) {
      if (_defaultOrder.contains(id) && !seen.contains(id)) {
        seen.add(id);
        out.add(id);
      }
    }
    // ✅ IMPORTANT: for ORDER we add missing defaults back
    for (final id in _defaultOrder) {
      if (!seen.contains(id)) out.add(id);
    }
    return out;
  }

  // -----------------------------
  // ✅ Visibility sanitizer (NO re-adding missing!)
  // -----------------------------
  List<String> _sanitizeVisible(List<String> input) {
    final seen = <String>{};
    final out = <String>[];
    for (final id in input) {
      if (_defaultOrder.contains(id) && !seen.contains(id)) {
        seen.add(id);
        out.add(id);
      }
    }
    return out; // ✅ DO NOT add missing defaults here
  }

  Future<void> _initPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedOrder = prefs.getStringList(_kPrefsOrderKey);
      final storedVisible = prefs.getStringList(_kPrefsVisibleKey);

      final order = (storedOrder != null && storedOrder.isNotEmpty)
          ? _normalizeOrder(storedOrder)
          : List<String>.from(_defaultOrder);

      final visibleList = (storedVisible != null && storedVisible.isNotEmpty)
          ? _sanitizeVisible(storedVisible)
          : List<String>.from(_defaultOrder);

      if (!mounted) return;
      setState(() {
        _tileOrder = order;
        _visibleTiles = visibleList.toSet();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _tileOrder = List<String>.from(_defaultOrder);
        _visibleTiles = Set<String>.from(_defaultOrder);
        _loading = false;
      });
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kPrefsOrderKey, _tileOrder);

    // ✅ FIXED: do NOT normalize visibility like order
    final visibleList = _sanitizeVisible(_visibleTiles.toList());
    await prefs.setStringList(_kPrefsVisibleKey, visibleList);
  }

  Future<void> _resetDefaults() async {
    setState(() {
      _tileOrder = List<String>.from(_defaultOrder);
      _visibleTiles = Set<String>.from(_defaultOrder);
    });
    await _persist();
  }

  void _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final updated = List<String>.from(_tileOrder);
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);

    final normalized = _normalizeOrder(updated);
    setState(() => _tileOrder = normalized);
    await _persist();
  }

  Future<void> _toggleVisible(String id, bool value) async {
    final next = Set<String>.from(_visibleTiles);
    if (value) {
      next.add(id);
    } else {
      next.remove(id);
    }
    setState(() => _visibleTiles = next);
    await _persist();
  }

  Widget _cardShell(FlutterFlowTheme theme, Widget child) {
    return Container(
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
        child: child,
      ),
    );
  }

  Widget _tileRow(FlutterFlowTheme theme, String id, int index) {
    final label = _labels[id] ?? id;
    final visible = _visibleTiles.contains(id);

    return ReorderableDragStartListener(
      index: index,
      child: Container(
        height: _tileH,
        color: _paper,
        child: Row(
          children: [
            const SizedBox(width: 10),
            Icon(
              Icons.drag_handle_rounded,
              size: 22,
              color: _inkMute,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: _rowTitleStyle(theme)),
                  const SizedBox(height: 2),
                  Text(
                    visible ? 'Visible on dashboard' : 'Hidden',
                    style: _rowMetaStyle(theme),
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.95,
              child: Switch(
                value: visible,
                onChanged: (v) => _toggleVisible(id, v),
                activeColor: _ink,
              ),
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (_loading) {
      return Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? double.infinity,
        color: _paper,
        child: const Center(
            child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_ink))),
      );
    }

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: _paper,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              _hPad,
              MediaQuery.of(context).padding.top + 16,
              _hPad,
              14,
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.maybePop(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _hairline),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: _inkMute,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dashboard Settings', style: _titleStyle(theme)),
                      const SizedBox(height: 2),
                      Text(
                        'Choose which sections appear and in what order.',
                        style: _subtitleStyle(theme),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(_hPad, 6, _hPad, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardShell(
                    theme,
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      onReorder: _onReorder,
                      itemCount: _tileOrder.length,
                      itemBuilder: (context, index) {
                        final id = _tileOrder[index];
                        return Column(
                          key: ValueKey(id),
                          children: [
                            _tileRow(theme, id, index),
                            if (index != _tileOrder.length - 1)
                              Divider(
                                height: 1,
                                color: _hairline.withOpacity(0.75),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: _gap),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _resetDefaults,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _hairline),
                            ),
                            child: Center(
                              child: Text(
                                'Reset Defaults',
                                style: theme.bodyMedium.override(
                                  fontFamily: _bodyFont,
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => Navigator.maybePop(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: _spark,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'Done',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: _sparkInk,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
