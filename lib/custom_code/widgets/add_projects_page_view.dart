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
import '/auth/firebase_auth/auth_util.dart';

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
  static const Color _ink = Color(0xFF16202E);
  static const Color _inkMute = Color(0xFF5A6675);
  static const Color _faint = Color(0xFF93A0B0);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFEEF1F4);
  static const Color _hairline = Color(0xFFEEF1F2);
  static const Color _hairlineOnSurface = Color(0xFFE2E7EE);
  // Brand accent — TEAL. Used as the accent (focus ring, active switch); the
  // primary CTA stays ink to match the dashboard's "Create project".
  static const Color _teal = Color(0xFF0D9488);
  // Status
  static const Color _live = Color(0xFFFF6A2B); // orange — live / warning
  static const Color _coral = Color(0xFFE0531C);
  // Type
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const String _monoFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = 22;
  static const double _vPad = 8;
  static const double _radius = 12;
  static const double _gap = 12; // horizontal gap inside rows
  static const double _fieldGap = 20; // vertical rhythm between fields (open)

  final _formKey = GlobalKey<FormState>();

  // UI controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  String _status = 'Planning';
  String _province = 'Western Cape';

  DateTime? _startDate;
  DateTime? _endDate;

  bool _archived = false;
  bool _saving = false;

  // ─── Swipe-to-dismiss (follow the thumb, snap back or close) ────────
  double _dragX = 0;
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

  // Only rightward drags count; deferToChild lets text fields / dropdowns
  // claim their own horizontal gestures first.
  void _onDragUpdate(DragUpdateDetails d) {
    if (_snapCtrl.isAnimating) _snapCtrl.stop();
    setState(() {
      _dragX = (_dragX + d.delta.dx).clamp(0.0, double.infinity);
    });
  }

  void _onDragEnd(DragEndDetails d) {
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
  // ✅ TYPOGRAPHY (synced with the dashboard)
  // =========================================================
  TextStyle _appTitleStyle(FlutterFlowTheme t) => t.titleLarge.override(
        fontFamily: _displayFont,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: _ink,
      );

  TextStyle _appSubtitleStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: _bodyFont,
        color: _faint,
      );

  TextStyle _sectionTitleStyle(FlutterFlowTheme t) => t.titleMedium.override(
        fontFamily: _displayFont,
        color: _ink,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      );

  TextStyle _fieldLabelStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: _bodyFont,
        color: _inkMute,
        letterSpacing: 0.0,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      );

  TextStyle _fieldTextStyle(FlutterFlowTheme t) => t.bodyMedium.override(
        fontFamily: _bodyFont,
        color: _ink,
        letterSpacing: 0.0,
        fontWeight: FontWeight.w600,
      );

  TextStyle _helperStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: _bodyFont,
        color: _faint,
        letterSpacing: 0.0,
        fontWeight: FontWeight.w500,
      );

  // =========================================================
  // ✅ COLORS
  // =========================================================
  // High-contrast field fill so inputs are visible on white/flat backgrounds
  Color _fieldFill(FlutterFlowTheme theme) {
    final sb = _surface;
    if (sb != _paper) return sb;
    return _hairline.withOpacity(0.10);
  }

  Color _fieldBorder(FlutterFlowTheme theme) => _hairlineOnSurface;

  // =========================================================
  // ✅ SECTION HEADER (matches the dashboard)
  // =========================================================
  Widget _sectionHeader(FlutterFlowTheme theme, String label) => Row(
        children: [
          Container(
            width: 9,
            height: 16,
            decoration: BoxDecoration(
              color: _ink,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 10),
          Text(label, style: _sectionTitleStyle(theme)),
        ],
      );

  InputDecoration _fieldDecoration(
    FlutterFlowTheme theme, {
    required String hint,
    IconData? icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: theme.bodySmall.override(
        fontFamily: _bodyFont,
        color: _inkMute.withOpacity(0.7),
        letterSpacing: 0.0,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: _fieldFill(theme),
      prefixIcon: icon == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(icon, size: 18, color: _inkMute),
            ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide(color: _fieldBorder(theme), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: _teal, width: 1.7),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: _coral, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: _coral, width: 1.2),
      ),
    );
  }

  Widget _pillButton({
    required FlutterFlowTheme theme,
    required String text,
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = true,
    bool disabled = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(999),

        // ✅ kill splash/highlight/overlay (matches other pages)
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),

        child: Opacity(
          opacity: disabled ? 0.55 : 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: isPrimary ? _ink : _paper,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isPrimary ? _ink : _hairline,
                width: 1,
              ),
              // ✅ no shadows
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isPrimary ? _paper : _inkMute,
                ),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: theme.bodyMedium.override(
                    fontFamily: _bodyFont,
                    color: isPrimary ? _paper : _ink,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w700,
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
              todayForegroundColor: const WidgetStatePropertyAll(_ink),
              todayBorder: const BorderSide(color: _teal, width: 1.4),
              dayStyle: const TextStyle(
                fontFamily: _bodyFont,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
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

  Widget _dropdownField({
    required FlutterFlowTheme theme,
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    // ✅ safety: DropdownButton throws if value not in items
    final safeValue = items.contains(value) ? value : items.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _fieldLabelStyle(theme)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _fieldFill(theme),
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: _fieldBorder(theme), width: 1.2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Icon(icon, size: 18, color: _inkMute),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: safeValue,
                    isExpanded: true,
                    dropdownColor: _paper,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: _inkMute),
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
        ),
      ],
    );
  }

  Widget _dateField({
    required FlutterFlowTheme theme,
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _fieldLabelStyle(theme)),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _saving ? null : onTap,
            borderRadius: BorderRadius.circular(_radius),

            // ✅ kill splash/highlight/overlay
            splashFactory: NoSplash.splashFactory,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            overlayColor: WidgetStateProperty.all(Colors.transparent),

            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: _fieldFill(theme),
                borderRadius: BorderRadius.circular(_radius),
                border: Border.all(
                  color: _fieldBorder(theme),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: _inkMute),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      value,
                      style: _fieldTextStyle(theme).copyWith(
                        color: value == 'Select date' ? _inkMute : _ink,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: _inkMute),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // ✅ SAVE (Firestore)
  // =========================================================
  Future<void> _saveProject(FlutterFlowTheme theme) async {
    if (_saving) return;

    if (currentUserReference == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
          backgroundColor: _ink,
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

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Transform.translate(
        offset: Offset(_dragX, 0),
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height ?? double.infinity,
          color: _paper,
          child: SafeArea(
            top: true,
            bottom: true,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: _hPad, vertical: _vPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =========================================================
                    // ✅ HEADER (back + title)
                    // =========================================================
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              final nav = Navigator.of(context);
                              if (nav.canPop()) nav.pop();
                            },
                            borderRadius: BorderRadius.circular(999),
                            splashFactory: NoSplash.splashFactory,
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            overlayColor:
                                WidgetStateProperty.all(Colors.transparent),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _surface,
                                shape: BoxShape.circle,
                                border: Border.all(color: _hairline),
                              ),
                              child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 16,
                                  color: _inkMute),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Add project', style: _appTitleStyle(theme)),
                              const SizedBox(height: 2),
                              Text(
                                'Create a workspace for tasks, costs & snags.',
                                style: _appSubtitleStyle(theme),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 26),

                    // =========================================================
                    // ✅ FORM (open layout — no surrounding card)
                    // =========================================================
                    _sectionHeader(theme, 'Project details'),
                    const SizedBox(height: 18),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Project name
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Project name',
                                  style: _fieldLabelStyle(theme)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _nameCtrl,
                                style: _fieldTextStyle(theme),
                                cursorColor: _teal,
                                decoration: _fieldDecoration(
                                  theme,
                                  hint: 'e.g. Winston Ridge Renovation',
                                  icon: Icons.home_work_outlined,
                                ),
                                enabled: !_saving,
                                onChanged: (_) => setState(() {}),
                                validator: (v) {
                                  if ((v ?? '').trim().isEmpty) {
                                    return 'Project name is required';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: _fieldGap),

                          // Status + Province
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _dropdownField(
                                  theme: theme,
                                  label: 'Status',
                                  value: _status,
                                  items: _statusOptions,
                                  icon: Icons.flag_outlined,
                                  onChanged: (v) => setState(() => _status = v),
                                ),
                              ),
                              const SizedBox(width: _gap),
                              Expanded(
                                child: _dropdownField(
                                  theme: theme,
                                  label: 'Province',
                                  value: _province,
                                  items: _provinceOptions,
                                  icon: Icons.map_outlined,
                                  onChanged: (v) =>
                                      setState(() => _province = v),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: _fieldGap),

                          // City
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('City / Area',
                                  style: _fieldLabelStyle(theme)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _cityCtrl,
                                style: _fieldTextStyle(theme),
                                cursorColor: _teal,
                                decoration: _fieldDecoration(
                                  theme,
                                  hint: 'e.g. Durbanville',
                                  icon: Icons.location_city_outlined,
                                ),
                                enabled: !_saving,
                                onChanged: (_) => setState(() {}),
                              ),
                            ],
                          ),

                          const SizedBox(height: _fieldGap),

                          // Address
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Address', style: _fieldLabelStyle(theme)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _addressCtrl,
                                style: _fieldTextStyle(theme),
                                cursorColor: _teal,
                                decoration: _fieldDecoration(
                                  theme,
                                  hint: 'Street address (optional)',
                                  icon: Icons.place_outlined,
                                ),
                                enabled: !_saving,
                                onChanged: (_) => setState(() {}),
                              ),
                            ],
                          ),

                          const SizedBox(height: _fieldGap),

                          // Dates
                          Row(
                            children: [
                              Expanded(
                                child: _dateField(
                                  theme: theme,
                                  label: 'Start date',
                                  value: _dateLabel(_startDate),
                                  icon: Icons.calendar_month_outlined,
                                  onTap: () => _pickDate(isStart: true),
                                ),
                              ),
                              const SizedBox(width: _gap),
                              Expanded(
                                child: _dateField(
                                  theme: theme,
                                  label: 'End date',
                                  value: _dateLabel(_endDate),
                                  icon: Icons.event_outlined,
                                  onTap: () => _pickDate(isStart: false),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: _fieldGap),

                          // Notes
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Notes', style: _fieldLabelStyle(theme)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _notesCtrl,
                                style: _fieldTextStyle(theme),
                                cursorColor: _teal,
                                maxLines: 6,
                                enabled: !_saving,
                                decoration: _fieldDecoration(
                                  theme,
                                  hint:
                                      'Anything important (budget notes, build phases, key contacts)…',
                                  icon: Icons.notes_outlined,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: _fieldGap),

                          // Archive toggle
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(_radius),
                              border: Border.all(
                                color: _hairlineOnSurface,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: _paper,
                                    borderRadius: BorderRadius.circular(10),
                                    border:
                                        Border.all(color: _hairlineOnSurface),
                                  ),
                                  child: const Icon(Icons.archive_outlined,
                                      color: _inkMute, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Archive',
                                        style: theme.bodyMedium.override(
                                          fontFamily: _bodyFont,
                                          color: _ink,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Keep this project hidden until you’re ready to use it.',
                                        style: _helperStyle(theme),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch.adaptive(
                                  value: _archived,
                                  onChanged: _saving
                                      ? null
                                      : (v) => setState(() => _archived = v),
                                  activeColor: _teal,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 26),

                          // Actions
                          Row(
                            children: [
                              Expanded(
                                child: _pillButton(
                                  theme: theme,
                                  text: _saving ? 'Saving…' : 'Save Project',
                                  icon: Icons.check_rounded,
                                  onTap: () => _saveProject(theme),
                                  isPrimary: true,
                                  disabled: _saving,
                                ),
                              ),
                              const SizedBox(width: _gap),
                              Expanded(
                                child: _pillButton(
                                  theme: theme,
                                  text: 'Cancel',
                                  icon: Icons.close_rounded,
                                  onTap: () {
                                    final nav = Navigator.of(context);
                                    if (nav.canPop()) nav.pop();
                                  },
                                  isPrimary: false,
                                  disabled: _saving,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          Text(
                            'This creates a new home building project.',
                            style: _helperStyle(theme),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
