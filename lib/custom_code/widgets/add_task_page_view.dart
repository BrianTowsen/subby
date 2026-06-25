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

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/auth/firebase_auth/auth_util.dart';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

class AddTaskPageView extends StatefulWidget {
  const AddTaskPageView({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<AddTaskPageView> createState() => _AddTaskPageViewState();
}

class _AddTaskPageViewState extends State<AddTaskPageView> {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  static const Color _ink = Color(0xFF2A6FDB);
  static const Color _inkMute = Color(0xFF5A6675);
  static const Color _faint = Color(0xFF93A0B0);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFEEF1F4);
  static const Color _hairline = Color(0xFFEEF1F2);
  static const Color _hairlineOnSurface = Color(0xFFE2E7EE);
  static const Color _teal = Color(0xFF2A6FDB);
  static const Color _tealTint = Color(0xFFE7EFFB);
  static const Color _live = Color(0xFFC7E87A);
  static const Color _coral = Color(0xFFCA2E55);
  static const Color _navy = Color(0xFF1D2834);
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = 24;
  static const double _radius = 12;

  static const String _kActiveProjectPath = 'subby_active_project_path';

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _newItemCtrl = TextEditingController();

  DocumentReference? _projectRef;
  bool _resolved = false;

  String _priority = 'med'; // 'low' | 'med' | 'high'
  DateTime? _dueDate;

  // checklist: [{ 'text', 'done' }]
  final List<Map<String, dynamic>> _checklist = [];

  // attachments: [{ 'url', 'type' ('image'|'file'), 'name', 'storagePath' }]
  final List<Map<String, dynamic>> _attachments = [];

  DocumentReference? _listingRef;
  String _listingName = '';
  String _listingSubtitle = '';

  DocumentReference? _userRef;
  String _userName = '';
  String _userSubtitle = '';

  bool _uploading = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolved) return;
    _resolved = true;
    _projectRef = _readRefFromRoute('projectRef', 'projects');
    if (_projectRef == null) _loadActiveProject();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _newItemCtrl.dispose();
    super.dispose();
  }

  DocumentReference? _readRefFromRoute(String key, String fallbackCollection) {
    try {
      final qp = GoRouterState.of(context).uri.queryParameters;
      var s = (qp[key] ?? '').trim();
      if (s.isEmpty) return null;
      s = s.replaceAll('"', '');
      if (s.startsWith('{')) {
        final m = RegExp(r'([A-Za-z0-9_]+/[A-Za-z0-9_]+(?:/[A-Za-z0-9_]+)*)')
            .firstMatch(s);
        if (m != null) s = m.group(1)!;
      }
      if (s.contains('/')) return FirebaseFirestore.instance.doc(s);
      return FirebaseFirestore.instance.collection(fallbackCollection).doc(s);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadActiveProject() async {
    final prefs = await SharedPreferences.getInstance();
    final path = (prefs.getString(_kActiveProjectPath) ?? '').trim();
    if (path.isEmpty || !mounted) return;
    setState(() => _projectRef = FirebaseFirestore.instance.doc(path));
  }

  void _handleBack() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      context.safePop();
    }
  }

  // =========================================================
  // Typography helpers
  // =========================================================
  TextStyle _uLabel() => const TextStyle(
        fontFamily: _bodyFont,
        color: _inkMute,
        letterSpacing: 0.6,
        fontWeight: FontWeight.w800,
        fontSize: 11,
      );

  TextStyle _fieldText() => const TextStyle(
        fontFamily: _bodyFont,
        color: _ink,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      );

  static const BoxDecoration _uRule = BoxDecoration(
    border: Border(bottom: BorderSide(color: _hairline, width: 1)),
  );

  Widget _minBack() => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleBack,
          borderRadius: BorderRadius.circular(999),
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

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '–';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  // =========================================================
  // Underline text field
  // =========================================================
  Widget _uText({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final multiline = maxLines > 1;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: _uRule,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: _uLabel()),
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
                  style: _fieldText(),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: hint,
                    hintStyle: const TextStyle(
                        fontFamily: _bodyFont,
                        color: Color(0xCC5A6675),
                        fontWeight: FontWeight.w600,
                        fontSize: 16),
                    errorStyle: const TextStyle(
                        fontFamily: _bodyFont,
                        color: _coral,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // Due date
  // =========================================================
  Widget _dueDateField() {
    final label =
        _dueDate == null ? 'Select date' : dateTimeFormat('d MMM y', _dueDate!);
    return GestureDetector(
      onTap: _saving ? null : _pickDueDate,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: _uRule,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DUE DATE', style: _uLabel()),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_month_outlined,
                    size: 19, color: _teal),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(label,
                      style: _fieldText()
                          .copyWith(color: _dueDate == null ? _inkMute : _ink)),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFFC7D0DA)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: _teal),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() => _dueDate = picked);
  }

  // =========================================================
  // Priority
  // =========================================================
  Widget _priorityField() {
    Widget pill(String key, String label) {
      final sel = _priority == key;
      final isHigh = key == 'high';
      final selFg = isHigh ? _live : _teal;
      final selBg = isHigh ? const Color(0x33C7E87A) : _tealTint;
      return GestureDetector(
        onTap: () => setState(() => _priority = key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: sel ? selBg : _surface,
            borderRadius: BorderRadius.circular(999),
            border: sel ? Border.all(color: selFg, width: 1.5) : null,
          ),
          child: Text(label,
              style: TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 12,
                  fontWeight: sel ? FontWeight.w800 : FontWeight.w700,
                  color: sel ? selFg : _faint)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: _uRule,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PRIORITY', style: _uLabel()),
          const SizedBox(height: 10),
          Row(
            children: [
              pill('low', 'Low'),
              const SizedBox(width: 8),
              pill('med', 'Medium'),
              const SizedBox(width: 8),
              pill('high', 'High'),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // Assignee rows (listing + person)
  // =========================================================
  Widget _assignRow({
    required String label,
    required bool isPerson,
    required bool has,
    required String name,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _saving ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: _uRule,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: _uLabel()),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: has ? _tealTint : _surface,
                    borderRadius: BorderRadius.circular(isPerson ? 19 : 10),
                  ),
                  child: has
                      ? Text(_initials(name),
                          style: const TextStyle(
                              fontFamily: _displayFont,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _ink))
                      : Icon(
                          isPerson
                              ? Icons.person_outline
                              : Icons.handyman_outlined,
                          size: 19,
                          color: _faint),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: has
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontFamily: _displayFont,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _navy)),
                            if (subtitle.isNotEmpty) ...[
                              const SizedBox(height: 1),
                              Text(subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontFamily: _bodyFont,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _faint)),
                            ],
                          ],
                        )
                      : Text(
                          isPerson
                              ? 'Choose a project member'
                              : 'Choose a listing on this project',
                          style: const TextStyle(
                              fontFamily: _bodyFont,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _inkMute)),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFFC7D0DA)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAssignee({required bool isPerson}) async {
    final projectRef = _projectRef;
    if (projectRef == null) {
      _toast('Select a project first.');
      return;
    }
    FocusScope.of(context).unfocus();

    final query = isPerson
        ? FirebaseFirestore.instance
            .collection('project_members')
            .where('projectRef', isEqualTo: projectRef)
            .get()
        : FirebaseFirestore.instance
            .collection('project_listings')
            .where('projectRef', isEqualTo: projectRef)
            .get();

    await showModalBottomSheet(
      context: context,
      backgroundColor: _paper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: _hairlineOnSurface,
                        borderRadius: BorderRadius.circular(999)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(isPerson ? 'Assign to person' : 'Assign to listing',
                    style: const TextStyle(
                        fontFamily: _displayFont,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: _ink)),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    future: query,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(_teal)),
                            ),
                          ),
                        );
                      }
                      final docs = snap.data?.docs ?? const [];
                      if (docs.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Text(
                            isPerson
                                ? 'No project members yet.'
                                : 'No listings added to this project yet.',
                            style: const TextStyle(
                                fontFamily: _bodyFont,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _faint),
                          ),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: docs.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: _hairline),
                        itemBuilder: (context, i) {
                          final d = docs[i].data();
                          final name = (isPerson
                                  ? (d['name'] ??
                                      d['displayName'] ??
                                      d['userName'] ??
                                      'Member')
                                  : (d['title'] ?? d['name'] ?? 'Listing'))
                              .toString();
                          final subtitle = (isPerson
                                  ? (d['role'] ??
                                      d['title'] ??
                                      'Project member')
                                  : (d['subtitle'] ??
                                      d['ratingText'] ??
                                      'Added to project'))
                              .toString();
                          final ref = isPerson
                              ? (d['userRef'] ?? d['memberRef'])
                                  as DocumentReference?
                              : d['listingRef'] as DocumentReference?;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (isPerson) {
                                  _userRef = ref ?? docs[i].reference;
                                  _userName = name;
                                  _userSubtitle = subtitle;
                                } else {
                                  _listingRef = ref ?? docs[i].reference;
                                  _listingName = name;
                                  _listingSubtitle = subtitle;
                                }
                              });
                              Navigator.of(ctx).pop();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _tealTint,
                                      borderRadius: BorderRadius.circular(
                                          isPerson ? 20 : 10),
                                    ),
                                    child: Text(_initials(name),
                                        style: const TextStyle(
                                            fontFamily: _displayFont,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: _ink)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontFamily: _displayFont,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: _navy)),
                                        const SizedBox(height: 2),
                                        Text(subtitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontFamily: _bodyFont,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: _faint)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // Checklist builder
  // =========================================================
  Widget _checklistField() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: _uRule,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CHECKLIST', style: _uLabel()),
          const SizedBox(height: 6),
          for (int i = 0; i < _checklist.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 11),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _checklist[i]['done'] =
                        !(_checklist[i]['done'] == true)),
                    child: Icon(
                      _checklist[i]['done'] == true
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      size: 19,
                      color: _checklist[i]['done'] == true ? _teal : _faint,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      (_checklist[i]['text'] ?? '').toString(),
                      style: const TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _inkMute),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _checklist.removeAt(i)),
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: Color(0xFFC7D0DA)),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                const Icon(Icons.add_rounded, size: 19, color: _teal),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _newItemCtrl,
                    cursorColor: _teal,
                    style: const TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _navy),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Add checklist item',
                      hintStyle: TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _faint),
                    ),
                    onSubmitted: (_) => _addChecklistItem(),
                  ),
                ),
                GestureDetector(
                  onTap: _addChecklistItem,
                  child: const Text('Add',
                      style: TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _teal)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addChecklistItem() {
    final t = _newItemCtrl.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _checklist.add({'text': t, 'done': false});
      _newItemCtrl.clear();
    });
  }

  // =========================================================
  // Attachments
  // =========================================================
  Widget _attachmentsField() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ATTACHMENTS', style: _uLabel()),
          const SizedBox(height: 11),
          SizedBox(
            height: 64,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                GestureDetector(
                  onTap: _pickAttachment,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(_radius),
                      border: Border.all(
                          color: const Color(0xFFC7D0DA), width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _uploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(_teal)),
                              )
                            : const Icon(Icons.attach_file_rounded,
                                size: 20, color: _teal),
                        const SizedBox(height: 3),
                        Text(_uploading ? '…' : 'Add',
                            style: const TextStyle(
                                fontFamily: _bodyFont,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: _inkMute)),
                      ],
                    ),
                  ),
                ),
                for (int i = 0; i < _attachments.length; i++) ...[
                  const SizedBox(width: 10),
                  _attachThumb(i),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _attachThumb(int i) {
    final a = _attachments[i];
    final isImage = (a['type'] ?? 'file') == 'image';
    final url = (a['url'] ?? '').toString();
    final name = (a['name'] ?? 'file').toString();
    final ext = name.contains('.')
        ? name.substring(name.lastIndexOf('.') + 1).toUpperCase()
        : 'FILE';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: _hairlineOnSurface),
            color: const Color(0xFFF7FAFA),
            image: (isImage && url.isNotEmpty)
                ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
                : null,
          ),
          child: isImage
              ? null
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.description_rounded,
                        size: 20, color: _inkMute),
                    const SizedBox(height: 2),
                    Text(ext,
                        style: const TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: _faint)),
                  ],
                ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: () => _removeAttachment(i),
            child: Container(
              width: 22,
              height: 22,
              decoration:
                  const BoxDecoration(color: _ink, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, size: 14, color: _paper),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickAttachment() async {
    if (_uploading || _saving) return;
    final projectRef = _projectRef;
    if (projectRef == null) {
      _toast('Select a project first.');
      return;
    }
    FocusScope.of(context).unfocus();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      setState(() => _uploading = true);

      for (final f in result.files) {
        final Uint8List? bytes = f.bytes;
        if (bytes == null || bytes.isEmpty) continue;

        final fileName = p.basename(f.name.isNotEmpty ? f.name : 'file');
        final safeName = fileName.replaceAll(RegExp(r'[^\w\.\- ]+'), '_');
        final ts = DateTime.now().millisecondsSinceEpoch;
        final storagePath = 'projects/${projectRef.id}/tasks/${ts}_$safeName';
        final contentType = lookupMimeType(fileName, headerBytes: bytes) ??
            'application/octet-stream';
        final kind = contentType.startsWith('image') ? 'image' : 'file';

        final ref = FirebaseStorage.instance.ref().child(storagePath);
        await ref.putData(bytes, SettableMetadata(contentType: contentType));
        final url = await ref.getDownloadURL();

        _attachments.add({
          'url': url,
          'type': kind,
          'name': fileName,
          'storagePath': storagePath,
        });
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('🔥 Attachment upload failed: $e');
      _toast('Upload failed. Please try again.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _removeAttachment(int i) {
    final sp = (_attachments[i]['storagePath'] ?? '').toString();
    if (sp.isNotEmpty) {
      FirebaseStorage.instance
          .ref()
          .child(sp)
          .delete()
          .catchError((e) => debugPrint('⚠️ attach delete skipped: $e'));
    }
    setState(() => _attachments.removeAt(i));
  }

  // =========================================================
  // Save
  // =========================================================
  Future<void> _save() async {
    if (_saving || _uploading) return;
    final projectRef = _projectRef;
    if (projectRef == null) {
      _toast('No project selected.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final now = Timestamp.now();
      final docRef = FirebaseFirestore.instance.collection('tasks').doc();
      await docRef.set(<String, dynamic>{
        'projectRef': projectRef,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'priority': _priority,
        'status': 'todo',
        'dueDate': _dueDate == null ? null : Timestamp.fromDate(_dueDate!),
        'checklist': _checklist,
        'attachments': _attachments,
        'assignedListingRef': _listingRef,
        'assignedListingName': _listingName,
        'readByListingAt': null,
        'createdBy': currentUserReference,
        'createdByName': currentUserDisplayName,
        'createdAt': now,
        'updatedAt': now,
      }.withoutNulls);

      if (!mounted) return;
      _toast('Task added.');
      _handleBack();
    } catch (e) {
      debugPrint('🔥 Add task failed: $e');
      if (mounted) _toast('Could not save. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        backgroundColor: _ink,
        content: Text(msg,
            style: const TextStyle(
                fontFamily: _bodyFont,
                color: _paper,
                fontWeight: FontWeight.w700)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: _paper,
      child: SafeArea(
        top: true,
        bottom: true,
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(_hPad, 14, _hPad, 96),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _minBack(),
                    const SizedBox(height: 16),
                    const Text('Add Task',
                        style: TextStyle(
                            fontFamily: _displayFont,
                            color: _ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 30,
                            height: 1.05,
                            letterSpacing: -0.5)),
                    const SizedBox(height: 8),
                    const Text('Plan work, set a due date and assign it',
                        style: TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _faint)),
                    const SizedBox(height: 16),
                    _uText(
                      label: 'Title',
                      controller: _titleCtrl,
                      icon: Icons.title_rounded,
                      hint: 'e.g. Confirm tiler site visit',
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? 'Give the task a title'
                          : null,
                    ),
                    _uText(
                      label: 'Notes',
                      controller: _descCtrl,
                      icon: Icons.notes_rounded,
                      hint: 'Any detail or context…',
                      maxLines: 3,
                    ),
                    _dueDateField(),
                    _priorityField(),
                    _assignRow(
                      label: 'Assign to listing',
                      isPerson: false,
                      has: _listingRef != null,
                      name: _listingName,
                      subtitle: _listingSubtitle,
                      onTap: () => _pickAssignee(isPerson: false),
                    ),
                    _checklistField(),
                    _attachmentsField(),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _save,
                  borderRadius: BorderRadius.circular(_radius),
                  child: Opacity(
                    opacity: (_saving || _uploading) ? 0.7 : 1,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: _teal,
                        borderRadius: BorderRadius.circular(_radius),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_saving)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(_paper)),
                            )
                          else
                            const Icon(Icons.add_rounded,
                                color: _paper, size: 20),
                          const SizedBox(width: 9),
                          Text(_saving ? 'Saving…' : 'Add Task',
                              style: const TextStyle(
                                  fontFamily: _bodyFont,
                                  color: _paper,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
