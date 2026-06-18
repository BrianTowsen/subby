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
  static const Color _ink = Color(0xFF16202E);
  static const Color _inkMute = Color(0xFF5A6675);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFEEF1F4);
  static const Color _hairline = Color(0xFFEEF1F4);
  static const Color _hairlineOnSurface = Color(0xFFD7DCE3);
  // Brand accent — YELLOW. Always ink foreground, never white.
  static const Color _spark = Color(0xFFAEE03F); // primary CTA / ranked accent
  static const Color _sparkInk = Color(0xFF16202E);
  // Status
  static const Color _live =
      Color(0xFFFF6A2B); // orange — live / open-now / warning
  static const Color _coral = Color(0xFFE0531C);
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
  TextStyle _appTitleStyle(FlutterFlowTheme t) => t.titleLarge.override(
        fontFamily: _displayFont,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.2,
      );

  TextStyle _appSubtitleStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: _bodyFont,
        color: _inkMute,
      );

  // ✅ Keep section titles consistent across Subby
  TextStyle _sectionTitleStyle(FlutterFlowTheme t) => t.titleMedium.override(
        fontFamily: _displayFont,
        color: _ink,
        fontWeight: FontWeight.w900,
      );

  TextStyle _fieldLabelStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: _bodyFont,
        color: _inkMute,
        letterSpacing: 0.0,
        fontWeight: FontWeight.w700,
      );

  TextStyle _fieldTextStyle(FlutterFlowTheme t) => t.bodyMedium.override(
        fontFamily: _bodyFont,
        color: _ink,
        letterSpacing: 0.0,
        fontWeight: FontWeight.w700,
      );

  TextStyle _helperStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: _bodyFont,
        color: _inkMute,
        letterSpacing: 0.0,
        fontWeight: FontWeight.w600,
      );

  // ---------------------------------------------------------
  // ✅ COLORS
  // ---------------------------------------------------------
  Color _projectsColor(FlutterFlowTheme theme) {
    try {
      final c = (theme as dynamic).projectsColour as Color?;
      return c ?? _ink;
    } catch (_) {
      return _ink;
    }
  }

  // Match AddProjectsPageView: high-contrast field fill + clearer borders
  Color _fieldFill(FlutterFlowTheme theme) {
    final sb = _surface;
    if (sb != _paper) return sb;
    return _hairline.withOpacity(0.10);
  }

  Color _fieldBorder(FlutterFlowTheme theme) => _hairline.withOpacity(0.95);

  // ---------------------------------------------------------
  // ✅ SUBBY SHELLS (NO SHADOWS)
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
        // ✅ NO SHADOWS (matches Dashboard + other pages)
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Padding(padding: padding, child: child),
      ),
    );
  }

  InputDecoration _fieldDecoration(
    FlutterFlowTheme theme, {
    required String hint,
    IconData? icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: theme.bodySmall.override(
        fontFamily: _bodyFont,
        color: _inkMute.withOpacity(0.85),
        letterSpacing: 0.0,
        fontWeight: FontWeight.w600,
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
        borderSide: BorderSide(color: _ink, width: 1.7),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide(color: _coral, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide(color: _coral, width: 1.2),
      ),
    );
  }

  Widget _pillButton({
    required FlutterFlowTheme theme,
    required Color accent,
    required String text,
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _saving ? null : onTap,
        borderRadius: BorderRadius.circular(999),

        // ✅ kill splash/highlight/overlay
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),

        child: Opacity(
          opacity: _saving ? 0.7 : 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isPrimary ? _spark : accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isPrimary ? _spark : accent.withOpacity(0.25),
                width: 1,
              ),
              // ✅ NO SHADOWS
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_saving && isPrimary)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isPrimary ? _sparkInk : accent,
                        ),
                      ),
                    ),
                  )
                else
                  Icon(
                    icon,
                    size: 18,
                    color: isPrimary ? _sparkInk : accent,
                  ),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: theme.bodyMedium.override(
                    fontFamily: _bodyFont,
                    color: isPrimary ? _sparkInk : accent,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w900,
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

  Widget _dropdownField({
    required FlutterFlowTheme theme,
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    icon: Icon(Icons.keyboard_arrow_down_rounded,
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
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: _inkMute),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

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

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: _paper,
      child: SafeArea(
        top: true,
        bottom: true,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: _hPad, vertical: _vPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =========================================================
                // ✅ HEADER (No flash taps)
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
                        borderRadius: BorderRadius.circular(12),
                        splashFactory: NoSplash.splashFactory,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        overlayColor:
                            WidgetStateProperty.all(Colors.transparent),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _paper,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _hairline.withOpacity(0.9),
                            ),
                          ),
                          child: Icon(Icons.arrow_back_rounded,
                              size: 22, color: _ink),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(_radius),
                      ),
                      child: const Icon(Icons.edit_rounded,
                          color: _paper, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Project',
                            style: _appTitleStyle(theme).copyWith(
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Update details, dates and notes.',
                            style: _appSubtitleStyle(theme),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _saving
                            ? null
                            : () => _confirmDelete(theme, accent),
                        borderRadius: BorderRadius.circular(12),
                        splashFactory: NoSplash.splashFactory,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        overlayColor:
                            WidgetStateProperty.all(Colors.transparent),
                        child: Opacity(
                          opacity: _saving ? 0.7 : 1,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _paper,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _hairline.withOpacity(0.9),
                              ),
                            ),
                            child: Icon(Icons.delete_outline_rounded,
                                size: 22, color: _coral),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // =========================================================
                // ✅ FORM
                // =========================================================
                Text('Project Details', style: _sectionTitleStyle(theme)),
                const SizedBox(height: 10),

                _subbyCardShell(
                  theme: theme,
                  padding: const EdgeInsets.all(16),
                  child: Form(
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
                              cursorColor: accent,
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

                        const SizedBox(height: _gap),

                        // Status + Province
                        Row(
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
                                onChanged: (v) => setState(() => _province = v),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: _gap),

                        // City
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('City / Area', style: _fieldLabelStyle(theme)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _cityCtrl,
                              style: _fieldTextStyle(theme),
                              cursorColor: accent,
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

                        const SizedBox(height: _gap),

                        // Address
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Address', style: _fieldLabelStyle(theme)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _addressCtrl,
                              style: _fieldTextStyle(theme),
                              cursorColor: accent,
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

                        const SizedBox(height: _gap),

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

                        const SizedBox(height: _gap),

                        // Notes
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Notes', style: _fieldLabelStyle(theme)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _notesCtrl,
                              style: _fieldTextStyle(theme),
                              cursorColor: accent,
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

                        const SizedBox(height: _gap),

                        // Archive toggle
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(_radius),
                            border: Border.all(
                              color: _hairline.withOpacity(0.9),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _hairline.withOpacity(0.35),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.archive_outlined,
                                    color: _inkMute, size: 20),
                              ),
                              const SizedBox(width: 12),
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
                                        fontWeight: FontWeight.w900,
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
                              Switch.adaptive(
                                value: _archived,
                                onChanged: _saving
                                    ? null
                                    : (v) => setState(() => _archived = v),
                                activeColor: accent,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Actions
                        Row(
                          children: [
                            Expanded(
                              child: _pillButton(
                                theme: theme,
                                accent: accent,
                                text: 'Save Changes',
                                icon: Icons.check_rounded,
                                onTap: _saveChanges,
                                isPrimary: true,
                              ),
                            ),
                            const SizedBox(width: _gap),
                            Expanded(
                              child: _pillButton(
                                theme: theme,
                                accent: accent,
                                text: 'Cancel',
                                icon: Icons.close_rounded,
                                onTap: () {
                                  final nav = Navigator.of(context);
                                  if (nav.canPop()) nav.pop();
                                },
                                isPrimary: false,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),
                        Text(
                          'Tip: This updates the selected project document and My Projects will refresh automatically (StreamBuilder).',
                          style: _helperStyle(theme),
                        ),
                      ],
                    ),
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
