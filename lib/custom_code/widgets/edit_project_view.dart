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

import 'package:cloud_firestore/cloud_firestore.dart';
import '/auth/firebase_auth/auth_util.dart';
import 'package:flutter/services.dart'; // SystemChrome / SystemUiOverlayStyle (dark status bar over white form)

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

class _EditProjectViewState extends State<EditProjectView>
    with SingleTickerProviderStateMixin {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  // less-is-more system · ported from Clutch Putt · lime → yellow.
  // Inline = authoritative for this file. Grep `SUBBY PALETTE (LOCK)` to sync.
  //
  // Neutrals
  static const Color _ink = Color(0xFF29343A);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _hairline = Color(0xFFECF0F2);
  static const Color _hairlineOnSurface = Color(0xFFCBD8DD);
  // Brand accent — TEAL.
  static const Color _teal = Color(0xFF29343A);
  // Status
  static const Color _live =
      Color(0xFF566670); // clay — live / open-now / warning
  static const Color _coral = Color(0xFF566670);
  // Warning / destructive accent — brown.
  static const Color _warn = Color(0xFFA44200);
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
  String _scope = 'New build';

  DateTime? _startDate;
  DateTime? _endDate;

  bool _archived = false;

  bool _loading = true;
  bool _saving = false;

  // ─── Swipe-right-to-go-back (follow the thumb, snap back or pop) ──────
  double _dragX = 0;
  late final AnimationController _snapCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  Animation<double>? _snapAnim;

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

  // Wraps a page in the right-to-go-back swipe gesture.
  Widget _swipeBack(Widget child) {
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Transform.translate(
        offset: Offset(_dragX, 0),
        child: child,
      ),
    );
  }

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
    'Home Renovation',
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
                    color: sel ? _ink : _surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(o,
                      style: TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: sel ? _paper : _inkMute,
                      )),
                ),
              );
            }).toList(),
          ),
        ],
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
            padding: const EdgeInsets.symmetric(vertical: 19),
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
              backgroundColor: _ink,
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

        final scope =
            (data['category'] ?? data['type'] ?? 'New build').toString();
        _scope = _scopeOptions.contains(scope) ? scope : 'New build';

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
          backgroundColor: _ink,
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
      'category': _scope,
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
          backgroundColor: _ink,
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
          backgroundColor: _ink,
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
        // ✅ Forward the edited project's ref so the destination
        // (e.g. ProjectDetailPageView) knows which project to show.
        context.pushReplacementNamed(
          target,
          queryParameters: <String, dynamic>{
            'projectRef': serializeParam(
              ref,
              ParamType.DocumentReference,
            ),
          }.withoutNulls,
          extra: <String, dynamic>{
            'projectRef': ref,
          },
        );
      } else {
        context.safePop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _ink,
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
          backgroundColor: _ink,
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
        context.pushReplacementNamed(target);
      } else {
        context.safePop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _ink,
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

  // Action-sheet row — matches the Project Detail remove sheets so every
  // confirm / warning popup shares one style (ink header card + module rows).
  Widget _actionModuleRow({
    required FlutterFlowTheme theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final borderColor =
        destructive ? _coral.withOpacity(0.25) : _hairline.withOpacity(0.75);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: destructive
                    ? _coral.withOpacity(0.18)
                    : _hairline.withOpacity(0.35),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: iconColor.withOpacity(0.22),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodyMedium.override(
                          fontFamily: _bodyFont,
                          color: destructive ? _coral : _ink,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodySmall.override(
                          fontFamily: _bodyFont,
                          color: _inkMute,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.chevron_right_rounded,
                  color: _inkMute,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Centered destructive confirm dialog — shared "delete warning" module.
  Future<void> _showDeleteDialog({
    required FlutterFlowTheme theme,
    required String title,
    required String message,
    required String confirmLabel,
    required IconData icon,
    required Future<void> Function() onConfirm,
  }) async {
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 34),
          child: Container(
            width: 322,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _paper,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.30),
                  blurRadius: 54,
                  offset: const Offset(0, 22),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _warn.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: _warn.withOpacity(0.22), width: 1),
                  ),
                  child: Icon(icon, color: _warn, size: 30),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.titleMedium.override(
                    fontFamily: _displayFont,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.bodyMedium.override(
                    fontFamily: _bodyFont,
                    fontWeight: FontWeight.w500,
                    lineHeight: 1.5,
                    color: _inkMute,
                  ),
                ),
                const SizedBox(height: 22),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      Navigator.pop(ctx);
                      await onConfirm();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _warn,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        confirmLabel,
                        style: theme.bodyMedium.override(
                          fontFamily: _bodyFont,
                          fontWeight: FontWeight.w700,
                          color: _paper,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(ctx),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _paper,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFCBD8DD), width: 1.4),
                      ),
                      child: Text(
                        'Cancel',
                        style: theme.bodyMedium.override(
                          fontFamily: _bodyFont,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(FlutterFlowTheme theme, Color accent) async {
    await _showDeleteDialog(
      theme: theme,
      icon: Icons.delete_rounded,
      title: 'Delete project?',
      message:
          'Archives this build and marks it as deleted. You can restore it from Archived builds later.',
      confirmLabel: 'Delete project',
      onConfirm: _deleteProject,
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
    _snapCtrl.dispose();
    super.dispose();
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
  Widget _hero(FlutterFlowTheme theme) => Container(
        width: double.infinity,
        color: _ink,
        padding: EdgeInsets.fromLTRB(
            20, 6 + MediaQuery.of(context).padding.top, 20, 18),
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
                    child: Text('EDIT PROJECT',
                        style: TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                            color: _paper.withOpacity(0.5))),
                  ),
                ),
                _heroCircle(Icons.delete_outline_rounded, () {
                  if (_saving) return;
                  _confirmDelete(theme, _coral);
                }),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Edit Project',
                style: TextStyle(
                    fontFamily: _displayFont,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    height: 1.0,
                    color: _paper)),
            const SizedBox(height: 8),
            Text('Update details, dates and notes.',
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
          border: Border(top: BorderSide(color: _surface, width: 1)),
          boxShadow: [
            BoxShadow(
                color: Color(0x1F19232D),
                blurRadius: 30,
                offset: Offset(0, -10)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(_hPad, 14, _hPad, 14),
        child: SafeArea(top: false, child: _primarySave(theme)),
      );

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final accent = _projectsColor(theme);

    // White-background screen: keep dark (black) status-bar icons. Reasserts
    // dark after arriving from the ink ProjectDetail hero (which forces light).
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

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
    return _swipeBack(
      Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? double.infinity,
        color: _paper,
        child: SafeArea(
          top: false,
          bottom: true,
          child: Column(
            children: [
              _hero(theme),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(_hPad, 10, _hPad, 24),
                  child: Form(
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
                        _uScope(theme),
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
    );
  }
}
