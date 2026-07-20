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
import '/auth/firebase_auth/auth_util.dart';
import 'package:flutter/services.dart'; // SystemUiOverlayStyle (white status bar icons over ink hero)

class AddProjectsPageView extends StatefulWidget {
  const AddProjectsPageView({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<AddProjectsPageView> createState() => _AddProjectsPageViewState();
}

class _AddProjectsPageViewState extends State<AddProjectsPageView>
    with SingleTickerProviderStateMixin {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  // Synced with DashboardPageView v4. Inline = authoritative for this file.
  // Grep `SUBBY PALETTE (LOCK)` to sync.
  //
  // Neutrals
  static const Color _ink = Color(0xFF1E282E);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _hairline = Color(0xFFEAEEF0);
  static const Color _hairlineOnSurface = Color(0xFFDCE3E6);
  // Brand accent — TEAL. Used as the accent (focus ring, active switch); the
  // primary CTA stays ink to match the dashboard's "Create project".
  static const Color _teal = Color(0xFF1E282E);
  // Status
  static const Color _live = Color(0xFF566670); // clay — live / warning
  static const Color _coral = Color(0xFF566670);
  // Type
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const String _monoFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = 24;
  static const double _vPad = 14;
  static const double _radius = 10;
  static const double _gap = 12;

  final _formKey = GlobalKey<FormState>();

  // UI controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  String _status = 'Planning';
  String _province = 'Western Cape';
  String _scope = 'New build';

  DateTime? _startDate;
  DateTime? _endDate;

  bool _archived = false;
  bool _saving = false;

  // ─── Edge-swipe-to-dismiss (follow the thumb, snap back or close) ───
  // Only a drag that STARTS within [_edgeWidth] px of the left edge counts as
  // a back-swipe; drags beginning in the middle of the screen are ignored so
  // they never accidentally dismiss the page (and stay free for other
  // gestures like list scrubbing / text selection).
  static const double _edgeWidth = 30;
  double _dragX = 0;
  bool _edgeEngaged = false;
  late final AnimationController _snapCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  Animation<double>? _snapAnim;

  @override
  void dispose() {
    _snapCtrl.dispose();
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // Gate the gesture at its start: engage only when the finger lands near the
  // left edge. deferToChild still lets text fields / dropdowns claim their own
  // horizontal gestures first.
  void _onDragStart(DragStartDetails d) {
    _edgeEngaged = d.localPosition.dx <= _edgeWidth;
  }

  // Only rightward drags count, and only when the swipe began at the edge.
  void _onDragUpdate(DragUpdateDetails d) {
    if (!_edgeEngaged) return;
    if (_snapCtrl.isAnimating) _snapCtrl.stop();
    setState(() {
      _dragX = (_dragX + d.delta.dx).clamp(0.0, double.infinity);
    });
  }

  void _onDragEnd(DragEndDetails d) {
    if (!_edgeEngaged) return;
    _edgeEngaged = false;

    final double width = MediaQuery.sizeOf(context).width;
    final double v = d.primaryVelocity ?? 0;
    final bool shouldClose = _dragX > width * 0.30 || v > 700;

    if (shouldClose) {
      _animateDragTo(width, then: () {
        final nav = Navigator.of(context);
        if (nav.canPop()) nav.pop();
      });
    } else {
      _animateDragTo(0);
    }
  }

  void _animateDragTo(double target, {VoidCallback? then}) {
    _snapAnim = Tween<double>(begin: _dragX, end: target).animate(
      CurvedAnimation(parent: _snapCtrl, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() => _dragX = _snapAnim!.value);
      });
    _snapCtrl
      ..reset()
      ..forward().whenComplete(() {
        if (then != null) then();
      });
  }

  // =========================================================
  // ✅ TYPOGRAPHY
  // =========================================================
  TextStyle _appSubtitleStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: _bodyFont,
        color: _faint,
      );

  TextStyle _fieldTextStyle(FlutterFlowTheme t) => t.bodyMedium.override(
        fontFamily: _bodyFont,
        color: _ink,
        letterSpacing: 0.0,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      );

  TextStyle _helperStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: _bodyFont,
        color: _faint,
        letterSpacing: 0.0,
        fontWeight: FontWeight.w600,
      );

  // ✅ OPTION C — uppercase micro-label above each field.
  TextStyle _uLabelStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: _bodyFont,
        color: _inkMute,
        letterSpacing: 0.6,
        fontWeight: FontWeight.w800,
        fontSize: 11,
      );

  // =========================================================
  // ✅ OPTION C — MINIMAL UNDERLINE FIELDS
  // =========================================================
  static const BoxDecoration _uRule = BoxDecoration(
    border: Border(bottom: BorderSide(color: _hairlineOnSurface, width: 1)),
  );

  Widget _uText({
    required FlutterFlowTheme theme,
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    final multiline = maxLines > 1;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 19),
      decoration: _uRule,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: _uLabelStyle(theme)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: multiline
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(top: multiline ? 3 : 0),
                child: Icon(icon, size: 19, color: _teal),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  onTap: _ensureFocusedVisible,
                  enabled: !_saving,
                  cursorColor: _teal,
                  textInputAction: TextInputAction.done,
                  maxLines: maxLines,
                  validator: validator,
                  style: _fieldTextStyle(theme),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: hint,
                    hintStyle: theme.bodyMedium.override(
                      fontFamily: _bodyFont,
                      color: _inkMute.withOpacity(0.7),
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    errorStyle: theme.bodySmall.override(
                      fontFamily: _bodyFont,
                      color: _coral,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w700,
                    ),
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
    required FlutterFlowTheme theme,
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    final safeValue = items.contains(value) ? value : items.first;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 19),
      decoration: _uRule,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: _uLabelStyle(theme)),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, size: 19, color: _teal),
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
                    style: _fieldTextStyle(theme),
                    items: items
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e,
                            child: Text(
                              e,
                              style: _fieldTextStyle(theme),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _saving
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

  Widget _uDate({
    required FlutterFlowTheme theme,
    required String label,
    required IconData icon,
    required String value,
    required VoidCallback onTap,
  }) {
    final isPlaceholder = value == 'Select date';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _saving ? null : onTap,
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 19),
          decoration: _uRule,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: _uLabelStyle(theme)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(icon, size: 19, color: _teal),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      value,
                      style: _fieldTextStyle(theme).copyWith(
                        color: isPlaceholder ? _inkMute : _ink,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: _hairlineOnSurface),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Project Scope — segmented chip selector (saved as `category`).
  static const List<String> _scopeOptions = <String>[
    'New build',
    'Building addition',
    'Home renovation',
  ];

  Widget _uScope(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 19),
      decoration: _uRule,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PROJECT SCOPE', style: _uLabelStyle(theme)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _scopeOptions.map((o) {
              final sel = _scope == o;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _saving ? null : () => setState(() => _scope = o),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFFE7E247) : _surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(o,
                      style: TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: sel ? _ink : _inkMute,
                      )),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _uArchiveRow(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Archive',
                  style: theme.bodyMedium.override(
                    fontFamily: _bodyFont,
                    color: _ink,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Keep this project hidden until you’re ready to use it.',
                  style: _helperStyle(theme),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: _archived,
            onChanged: _saving ? null : (v) => setState(() => _archived = v),
            activeColor: _teal,
          ),
        ],
      ),
    );
  }

  Widget _primarySave(FlutterFlowTheme theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _saving ? null : () => _saveProject(theme),
        borderRadius: BorderRadius.circular(999),
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        child: Opacity(
          opacity: _saving ? 0.7 : 1,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 19),
            decoration: BoxDecoration(
              color: const Color(0xFFE7E247),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_saving)
                  const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(_ink),
                      ),
                    ),
                  )
                else
                  const Icon(Icons.check_rounded, size: 18, color: _ink),
                const SizedBox(width: 8),
                Text(
                  _saving ? 'Saving…' : 'Save Project',
                  style: theme.bodyMedium.override(
                    fontFamily: _bodyFont,
                    color: _ink,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // ✅ DATE PICKERS
  // =========================================================
  Future<void> _pickDate({required bool isStart}) async {
    final initial = (isStart ? _startDate : _endDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        final base = Theme.of(context);
        return Theme(
          data: base.copyWith(
            colorScheme: base.colorScheme.copyWith(
              primary: _teal, // selected day + header background
              onPrimary: _paper, // text on the selected day / header
              onSurface: _ink, // body text (days, year list)
              surface: _paper,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: _paper,
              headerBackgroundColor: _teal,
              headerForegroundColor: _paper,
              todayForegroundColor: WidgetStateProperty.resolveWith(
                (states) =>
                    states.contains(WidgetState.selected) ? _paper : _ink,
              ),
              todayBorder: const BorderSide(color: _teal, width: 1.4),
              dayStyle: const TextStyle(
                fontFamily: _bodyFont,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _teal,
                textStyle: const TextStyle(
                  fontFamily: _bodyFont,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;

    if (!mounted) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  String _dateLabel(DateTime? d) {
    if (d == null) return 'Select date';
    return dateTimeFormat('d/M/y', d);
  }

  // =========================================================
  // ✅ DROPDOWN LISTS
  // =========================================================
  static const List<String> _statusOptions = <String>[
    'Planning',
    'Active',
    'On Hold',
    'Completed',
  ];

  static const List<String> _provinceOptions = <String>[
    'Western Cape',
    'Eastern Cape',
    'Northern Cape',
    'Free State',
    'KwaZulu-Natal',
    'Gauteng',
    'Mpumalanga',
    'Limpopo',
    'North West',
  ];

  // =========================================================
  // ✅ SAVE (Firestore)
  // =========================================================
  Future<void> _saveProject(FlutterFlowTheme theme) async {
    if (_saving) return;

    if (currentUserReference == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF3D4F66),
          content: Text(
            'You must be logged in to create a project.',
            style: theme.bodyMedium.override(
              fontFamily: _bodyFont,
              color: _paper,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
      return;
    }

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _saving = true);
    try {
      final now = Timestamp.now();

      final payload = <String, dynamic>{
        'ownerRef': currentUserReference,
        'name': _nameCtrl.text.trim(),
        'status': _status,
        'category': _scope,
        'province': _province,
        'city': _cityCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'notes': _notesCtrl.text.trim(),
        'startDate':
            _startDate == null ? null : Timestamp.fromDate(_startDate!),
        'endDate': _endDate == null ? null : Timestamp.fromDate(_endDate!),
        'archived': _archived,
        'createdAt': now,
        'updatedAt': now,
      };

      payload.removeWhere((k, v) => v == null);

      await FirebaseFirestore.instance.collection('projects').add(payload);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF3D4F66),
          content: Text(
            'Project created!',
            style: theme.bodyMedium.override(
              fontFamily: _bodyFont,
              color: _paper,
              fontWeight: FontWeight.w800,
            ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      final nav = Navigator.of(context);
      if (nav.canPop()) nav.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF3D4F66),
          content: Text(
            'Failed to save project: $e',
            style: theme.bodyMedium.override(
              fontFamily: _bodyFont,
              color: _paper,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _heroCircle(IconData icon, VoidCallback onTap) => Material(
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

  // Dark ink hero (matches ProjectTimelinePageView).
  Widget _hero() => Container(
        width: double.infinity,
        color: const Color(0xFF3D4F66),
        padding: EdgeInsets.fromLTRB(
            20, MediaQuery.of(context).padding.top + 6, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _heroCircle(Icons.arrow_back_ios_new_rounded, () {
                  final nav = Navigator.of(context);
                  if (nav.canPop()) nav.pop();
                }),
                Expanded(
                  child: Center(
                    child: Text('NEW PROJECT',
                        style: TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                            color: _paper.withOpacity(0.5))),
                  ),
                ),
                const SizedBox(width: 38, height: 38),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Add project',
                style: TextStyle(
                    fontFamily: _displayFont,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    height: 1.0,
                    color: _paper)),
            const SizedBox(height: 8),
            Text('Create a workspace for tasks, costs & snags.',
                style: TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _paper.withOpacity(0.6))),
          ],
        ),
      );

  // Bright-white elevated footer (matches the Timeline inspector shell).
  Widget _footer(FlutterFlowTheme theme) => Container(
        decoration: const BoxDecoration(
          color: _paper,
          border: Border(top: BorderSide(color: Color(0xFFEAEEF0), width: 1)),
        ),
        padding: const EdgeInsets.fromLTRB(_hPad, 14, _hPad, 14),
        child: SafeArea(top: false, child: _primarySave(theme)),
      );

  // Lift the focused field above the on-screen keyboard.
  void _ensureFocusedVisible() {
    Future.delayed(const Duration(milliseconds: 250), () {
      final ctx = FocusManager.instance.primaryFocus?.context;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            alignment: 0.1,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // white icons (Android)
        statusBarBrightness: Brightness.dark, // white icons (iOS)
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onHorizontalDragStart: _onDragStart,
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        child: Transform.translate(
          offset: Offset(_dragX, 0),
          child: Container(
            width: widget.width ?? double.infinity,
            height: widget.height ?? double.infinity,
            color: _paper,
            child: SafeArea(
              top: false,
              bottom: true,
              child: Column(
                children: [
                  _hero(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(_hPad, 10, _hPad, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PROJECT DETAILS', style: _uLabelStyle(theme)),
                            const SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: _paper,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _hairline),
                              ),
                              clipBehavior: Clip.antiAlias,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _uText(
                                    theme: theme,
                                    label: 'Project name',
                                    controller: _nameCtrl,
                                    icon: Icons.home_work_outlined,
                                    hint: 'e.g. Winston Ridge Renovation',
                                    validator: (v) {
                                      if ((v ?? '').trim().isEmpty) {
                                        return 'Project name is required';
                                      }
                                      return null;
                                    },
                                  ),
                                  _uScope(theme),
                                  _uSelect(
                                    theme: theme,
                                    label: 'Status',
                                    icon: Icons.flag_outlined,
                                    value: _status,
                                    items: _statusOptions,
                                    onChanged: (v) =>
                                        setState(() => _status = v),
                                  ),
                                  _uSelect(
                                    theme: theme,
                                    label: 'Province',
                                    icon: Icons.map_outlined,
                                    value: _province,
                                    items: _provinceOptions,
                                    onChanged: (v) =>
                                        setState(() => _province = v),
                                  ),
                                  _uText(
                                    theme: theme,
                                    label: 'City / Area',
                                    controller: _cityCtrl,
                                    icon: Icons.location_city_outlined,
                                    hint: 'e.g. Durbanville',
                                  ),
                                  _uText(
                                    theme: theme,
                                    label: 'Address',
                                    controller: _addressCtrl,
                                    icon: Icons.place_outlined,
                                    hint: 'Street address (optional)',
                                  ),
                                  _uDate(
                                    theme: theme,
                                    label: 'Start date',
                                    icon: Icons.calendar_month_outlined,
                                    value: _dateLabel(_startDate),
                                    onTap: () => _pickDate(isStart: true),
                                  ),
                                  _uDate(
                                    theme: theme,
                                    label: 'End date',
                                    icon: Icons.event_outlined,
                                    value: _dateLabel(_endDate),
                                    onTap: () => _pickDate(isStart: false),
                                  ),
                                  _uText(
                                    theme: theme,
                                    label: 'Notes',
                                    controller: _notesCtrl,
                                    icon: Icons.notes_outlined,
                                    hint:
                                        'Anything important (budget notes, build phases, key contacts)…',
                                    maxLines: 4,
                                  ),
                                  _uArchiveRow(theme),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _footer(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
