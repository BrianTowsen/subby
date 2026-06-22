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

class EditProjectView extends StatefulWidget {
  const EditProjectView({
    super.key,
    this.width,
    this.height,

    /// ✅ Project reference to edit (required for wiring)
    this.projectRef,

    /// ✅ Optional: where to go after save/delete (fallback = pop)
    this.afterSaveRouteName,
    this.afterDeleteRouteName,
  });

  final double? width;
  final double? height;

  final DocumentReference? projectRef;

  final String? afterSaveRouteName;
  final String? afterDeleteRouteName;

  @override
  State<EditProjectView> createState() => _EditProjectViewState();
}

class _EditProjectViewState extends State<EditProjectView> {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  // less-is-more system · ported from Clutch Putt · lime → yellow.
  // Inline = authoritative for this file. Grep `SUBBY PALETTE (LOCK)` to sync.
  //
  // Neutrals
  static const Color _ink = Color(0xFF017374);
  static const Color _inkMute = Color(0xFF5A6675);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFEEF1F4);
  static const Color _hairline = Color(0xFFEEF1F4);
  static const Color _hairlineOnSurface = Color(0xFFD7DCE3);
  // Brand accent — TEAL.
  static const Color _teal = Color(0xFF017374);
  // Status
  static const Color _live =
      Color(0xFFE5771E); // orange — live / open-now / warning
  static const Color _coral = Color(0xFFE5771E);
  // Type
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const String _monoFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = 24;
  static const double _vPad = 24;
  static const double _radius = 12;
  static const double _gap = 12;

  final _formKey = GlobalKey<FormState>();

  // Controllers (will be hydrated from Firestore)
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  String _status = 'Active';
  String _province = 'Western Cape';

  DateTime? _startDate;
  DateTime? _endDate;

  bool _archived = false;

  bool _loading = true;
  bool _saving = false;

  // ---------------------------------------------------------
  // ✅ TYPOGRAPHY (token + explicit family, minimal overrides)
  // ---------------------------------------------------------
  TextStyle _appSubtitleStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: _bodyFont,
        color: _inkMute,
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
        color: _inkMute,
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

  // ---------------------------------------------------------
  // ✅ COLORS
  // ---------------------------------------------------------
  // Teal accent for secondary actions, switches, cursors & field focus.
  Color _projectsColor(FlutterFlowTheme theme) => _teal;

  // ---------------------------------------------------------
  // ✅ SUBBY SHELLS (NO SHADOWS) — used by the loading state
  // ---------------------------------------------------------
  Widget _subbyCardShell({
    required FlutterFlowTheme theme,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(
          color: _hairline.withOpacity(0.9),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Padding(padding: padding, child: child),
      ),
    );
  }

  // =========================================================
  // ✅ OPTION C — MINIMAL UNDERLINE FIELDS
  // =========================================================
  static const BoxDecoration _uRule = BoxDecoration(
    border: Border(bottom: BorderSide(color: _hairline, width: 1)),
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
      padding: const EdgeInsets.symmetric(vertical: 16),
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
                  enabled: !_saving,
                  cursorColor: _teal,
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
                      color: _inkMute.withOpacity(0.8),
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
      padding: const EdgeInsets.symmetric(vertical: 16),
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
          padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _uArchiveRow(FlutterFlowTheme theme, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: _uRule,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Archive this project',
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
                  'Hide it from Active Projects and keep your workspace clean.',
                  style: _helperStyle(theme),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: _archived,
            onChanged: _saving ? null : (v) => setState(() => _archived = v),
            activeColor: accent,
          ),
        ],
      ),
    );
  }

  Widget _primarySave(FlutterFlowTheme theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _saving ? null : _saveChanges,
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
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: _ink,
              borderRadius: BorderRadius.circular(999),
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
                        valueColor: AlwaysStoppedAnimation<Color>(_paper),
                      ),
                    ),
                  )
                else
                  const Icon(Icons.check_rounded, size: 18, color: _paper),
                const SizedBox(width: 8),
                Text(
                  'Save Changes',
                  style: theme.bodyMedium.override(
                    fontFamily: _bodyFont,
                    color: _paper,
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

  // ---------------------------------------------------------
  // ✅ DATE PICKERS
  // ---------------------------------------------------------
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
              primary: _teal,
              onPrimary: _paper,
              onSurface: _ink,
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

  Timestamp? _tsOrNull(DateTime? d) => d == null ? null : Timestamp.fromDate(d);

  DateTime? _dateFrom(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  // ---------------------------------------------------------
  // ✅ DROPDOWN LISTS
  // ---------------------------------------------------------
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

  // ---------------------------------------------------------
  // ✅ LOAD + WIRE FIRESTORE
  // ---------------------------------------------------------
  Future<void> _loadProject() async {
    final ref = widget.projectRef;
    if (ref == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    try {
      final snap = await ref.get();
      if (!snap.exists) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }

      final data = (snap.data() as Map<String, dynamic>? ?? {});

      // ✅ Optional safety: ensure only owner can edit
      final owner = data['ownerRef'];
      if (owner is DocumentReference &&
          currentUserReference != null &&
          owner.path != currentUserReference!.path) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You do not have permission to edit this project.',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
                      color: _paper,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.0,
                    ),
              ),
            ),
          );
          setState(() => _loading = false);
        }
        return;
      }

      if (!mounted) return;
      setState(() {
        _nameCtrl.text = (data['name'] ?? '').toString();
        _cityCtrl.text = (data['city'] ?? '').toString();
        _addressCtrl.text = (data['address'] ?? '').toString();
        _notesCtrl.text = (data['notes'] ?? '').toString();

        final status = (data['status'] ?? 'Active').toString();
        _status = _statusOptions.contains(status) ? status : 'Active';

        final province = (data['province'] ?? 'Western Cape').toString();
        _province =
            _provinceOptions.contains(province) ? province : 'Western Cape';

        _startDate = _dateFrom(data['startDate']);
        _endDate = _dateFrom(data['endDate']);

        _archived = (data['archived'] == true);

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not load project. Please try again.',
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
                  color: _paper,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.0,
                ),
          ),
        ),
      );
    }
  }

  Map<String, dynamic> _buildUpdatePayload() {
    final name = _nameCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final notes = _notesCtrl.text.trim();

    return <String, dynamic>{
      'name': name,
      'status': _status,
      'province': _province,
      'city': city,
      'address': address,
      'notes': notes,
      'archived': _archived,
      'startDate': _tsOrNull(_startDate),
      'endDate': _tsOrNull(_endDate),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastActivityAt': FieldValue.serverTimestamp(),
    };
  }

  Future<void> _saveChanges() async {
    if (_saving) return;

    final ref = widget.projectRef;
    if (ref == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Missing project reference.',
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
                  color: _paper,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.0,
                ),
          ),
        ),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    try {
      await ref.update(_buildUpdatePayload());

      if (!mounted) return;

      // ✅ show feedback BEFORE navigation so it always appears
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Project updated.',
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
                  color: _paper,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.0,
                ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      final target = (widget.afterSaveRouteName ?? '').trim();
      if (target.isNotEmpty) {
        context.pushReplacementNamed(
          target,
          extra: {
            kTransitionInfoKey: const TransitionInfo(
              hasTransition: true,
              transitionType: PageTransitionType.leftToRight,
              duration: Duration(milliseconds: 260),
            ),
          },
        );
      } else {
        context.safePop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Update failed. Please try again.',
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
                  color: _paper,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.0,
                ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteProject() async {
    final ref = widget.projectRef;
    if (ref == null) return;

    setState(() => _saving = true);

    try {
      await ref.update(<String, dynamic>{
        'archived': true,
        'deleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Project deleted.',
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
                  color: _paper,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.0,
                ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      final target = (widget.afterDeleteRouteName ?? '').trim();
      if (target.isNotEmpty) {
        context.pushReplacementNamed(
          target,
          extra: {
            kTransitionInfoKey: const TransitionInfo(
              hasTransition: true,
              transitionType: PageTransitionType.leftToRight,
              duration: Duration(milliseconds: 260),
            ),
          },
        );
      } else {
        context.safePop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Delete failed. Please try again.',
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
                  color: _paper,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.0,
                ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete(FlutterFlowTheme theme, Color accent) async {
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: _paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: _hairline.withOpacity(0.9), width: 1),
          ),
          title: Text(
            'Delete project?',
            style: theme.titleMedium.override(
              fontFamily: _displayFont,
              color: _ink,
              letterSpacing: 0.0,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            'This will archive and mark the project as deleted. You can restore it later if needed.',
            style: _helperStyle(theme),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: theme.bodyMedium.override(
                  fontFamily: _bodyFont,
                  color: _inkMute,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _deleteProject();
              },
              child: Text(
                'Delete',
                style: theme.bodyMedium.override(
                  fontFamily: _bodyFont,
                  color: accent,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProject());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final accent = _projectsColor(theme);

    // ---------------------------------------------------------
    // ✅ Loading state
    // ---------------------------------------------------------
    if (_loading) {
      return Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? double.infinity,
        color: _paper,
        child: SafeArea(
          top: true,
          bottom: true,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: _hPad, vertical: _vPad),
            child: _subbyCardShell(
              theme: theme,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Loading project…',
                      style: _helperStyle(theme)
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ---------------------------------------------------------
    // ✅ OPTION C — MINIMAL UNDERLINE
    // ---------------------------------------------------------
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: _paper,
      child: SafeArea(
        top: true,
        bottom: true,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(_hPad, 14, _hPad, _vPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== TOP ROW: back + delete =====
              Row(
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
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: _surface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 15, color: _inkMute),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap:
                          _saving ? null : () => _confirmDelete(theme, _coral),
                      borderRadius: BorderRadius.circular(999),
                      splashFactory: NoSplash.splashFactory,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                      child: Opacity(
                        opacity: _saving ? 0.7 : 1,
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.delete_outline_rounded,
                              size: 22, color: _coral),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ===== TITLE =====
              Text(
                'Edit Project',
                style: theme.titleLarge.override(
                  fontFamily: _displayFont,
                  color: _ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 30,
                  lineHeight: 1.05,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Update details, dates and notes.',
                style: _appSubtitleStyle(theme).copyWith(fontSize: 13),
              ),

              const SizedBox(height: 26),

              // ===== FORM =====
              Form(
                key: _formKey,
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
                    _uSelect(
                      theme: theme,
                      label: 'Status',
                      icon: Icons.flag_outlined,
                      value: _status,
                      items: _statusOptions,
                      onChanged: (v) => setState(() => _status = v),
                    ),
                    _uSelect(
                      theme: theme,
                      label: 'Province',
                      icon: Icons.map_outlined,
                      value: _province,
                      items: _provinceOptions,
                      onChanged: (v) => setState(() => _province = v),
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
                    _uArchiveRow(theme, accent),
                    const SizedBox(height: 28),
                    _primarySave(theme),
                    const SizedBox(height: 16),
                    Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _saving
                              ? null
                              : () {
                                  final nav = Navigator.of(context);
                                  if (nav.canPop()) nav.pop();
                                },
                          borderRadius: BorderRadius.circular(8),
                          splashFactory: NoSplash.splashFactory,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          overlayColor:
                              WidgetStateProperty.all(Colors.transparent),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Text(
                              'Cancel',
                              style: theme.bodyMedium.override(
                                fontFamily: _bodyFont,
                                color: _inkMute,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tip: This updates the selected project document and My Projects will refresh automatically (StreamBuilder).',
                      style: _helperStyle(theme),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
