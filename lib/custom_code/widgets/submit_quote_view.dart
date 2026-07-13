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

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/auth/firebase_auth/auth_util.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// SubmitQuoteView — a trade submits a quote to a project.
/// Upload-first, then the key figures (amount + VAT, lead time, deposit) and
/// inclusions/exclusions. Writes to projects/{id}/quotes/{tradeUid}.
class SubmitQuoteView extends StatefulWidget {
  const SubmitQuoteView({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<SubmitQuoteView> createState() => _SubmitQuoteViewState();
}

class _SubmitQuoteViewState extends State<SubmitQuoteView> {
  static const Color _ink = Color(0xFF1E282E);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _border = Color(0xFFEAEEF0);
  static const Color _line = Color(0xFFF2F5F6);
  static const Color _green = Color(0xFF4E504F);
  static const Color _lime = Color(0xFFE7E247); // primary CTA / positive accent
  static const Color _sage = Color(0xFFF2F5F6);
  static const Color _sageBorder = Color(0xFFCBD8DD);
  static const Color _coral = Color(0xFF566670);
  static const String _display = 'Inter Tight';
  static const String _body = 'Inter';

  static const String _kActiveProjectPath = 'subby_active_project_path';
  static const String _kActiveQuotePath = 'subby_active_quote_path';
  static const int _vatPct = 15;

  DocumentReference<Map<String, dynamic>>? _projectRef;
  DocumentReference<Map<String, dynamic>>? _quoteRef;
  String _projectName = 'Project';
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _projSub;

  final TextEditingController _amountCtl = TextEditingController();
  final TextEditingController _notesCtl = TextEditingController();
  bool _vatIncluded = true;
  int _leadWeeks = 2;
  int _depositPct = 40;
  bool _fileAttached = false;
  String _fileName = '';
  String _fileUrl = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadActiveProject();
  }

  @override
  void dispose() {
    _projSub?.cancel();
    _amountCtl.dispose();
    _notesCtl.dispose();
    super.dispose();
  }

  Future<void> _loadActiveProject() async {
    final prefs = await SharedPreferences.getInstance();
    final quotePath = (prefs.getString(_kActiveQuotePath) ?? '').trim();
    DocumentReference<Map<String, dynamic>>? ref;
    if (quotePath.isNotEmpty) {
      _quoteRef = FirebaseFirestore.instance.doc(quotePath);
      ref = _quoteRef!.parent.parent;
    } else {
      // Legacy fallback: active project + this trade's uid.
      final path = (prefs.getString(_kActiveProjectPath) ?? '').trim();
      if (path.isNotEmpty) {
        ref = FirebaseFirestore.instance.doc(path);
        final uid = currentUserReference?.id;
        if (uid != null) _quoteRef = ref.collection('quotes').doc(uid);
      }
    }
    if (ref == null) return;
    _projectRef = ref;
    _projSub = ref.snapshots().listen((snap) {
      final raw = snap.data();
      final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
      final name =
          (data['name'] ?? data['projectName'] ?? data['title'] ?? 'Project')
              .toString();
      if (mounted) setState(() => _projectName = name);
    });
  }

  double get _amountExcl => double.tryParse(_amountCtl.text.trim()) ?? 0;
  double get _vat => _vatIncluded ? _amountExcl * _vatPct / 100.0 : 0;
  double get _total => _amountExcl + _vat;

  String _fmt(num v) {
    final n = v.round();
    final s = n.abs().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
      b.write(s[i]);
    }
    return '${n < 0 ? '-' : ''}$b';
  }

  String _money(num v) => 'R ${_fmt(v)}';

  // Opens the native file picker, then uploads the chosen file to Firebase
  // Storage and stores the download URL in _fileName.
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final picked = result.files.first;
      final name = picked.name;

      // Show the chip immediately with the local name.
      setState(() {
        _fileAttached = true;
        _fileName = name;
      });

      // Upload to Storage (quotes/<uid>/<timestamp>-<name>) if we have bytes.
      final bytes = picked.bytes;
      final uid = currentUserReference?.id ?? 'anon';
      if (bytes != null) {
        final ref = FirebaseStorage.instance
            .ref('quotes/$uid/${DateTime.now().millisecondsSinceEpoch}-$name');
        await ref.putData(bytes);
        final url = await ref.getDownloadURL();
        if (mounted) setState(() => _fileName = name); // keep display name
        _fileUrl = url;
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
              backgroundColor: _ink,
              content: Text('Couldn\'t attach that file.',
                  style: TextStyle(
                      fontFamily: _body,
                      fontWeight: FontWeight.w700,
                      color: _paper))));
      }
    }
  }

  // Detaches the currently attached file.
  void _removeFile() {
    setState(() {
      _fileAttached = false;
      _fileName = '';
      _fileUrl = '';
    });
  }

  Future<void> _submit() async {
    final qref = _quoteRef;
    if (qref == null || _saving) return;
    setState(() => _saving = true);
    try {
      // Writes to the SAME doc InviteView created (listing-id keyed) —
      // listingRef/providerRef set at invite time are preserved by merge.
      await qref.set({
        'status': 'submitted',
        'amountExcl': _amountExcl,
        'vatIncluded': _vatIncluded,
        'total': _total,
        'leadWeeks': _leadWeeks,
        'depositPct': _depositPct,
        'notes': _notesCtl.text.trim(),
        'fileName': _fileName,
        'fileUrl': _fileUrl,
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          backgroundColor: _ink,
          content: const Text('Quote submitted.',
              style: TextStyle(
                  fontFamily: _body,
                  fontWeight: FontWeight.w700,
                  color: _paper)),
        ));
      final nav = Navigator.of(context);
      if (nav.canPop()) nav.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
              backgroundColor: _ink,
              content: Text('Couldn\'t submit — check your connection.',
                  style: TextStyle(
                      fontFamily: _body,
                      fontWeight: FontWeight.w700,
                      color: _paper))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;
    final canSubmit = _amountExcl > 0;

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: _paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // hero
          Container(
            width: double.infinity,
            color: const Color(
                0xFF3F5C69), // steel — matches DashboardPageView hero
            padding: EdgeInsets.fromLTRB(20, top + 14, 20, 18),
            child: Row(
              children: [
                _circleBtn(Icons.arrow_back_ios_new_rounded, () {
                  final nav = Navigator.of(context);
                  if (nav.canPop()) nav.pop();
                }),
                Expanded(
                  child: Column(
                    children: [
                      const Text('Submit your quote',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontFamily: _body,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _paper)),
                      const SizedBox(height: 2),
                      Text(_projectName.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontFamily: _body,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                              color: _paper.withOpacity(0.5))),
                    ],
                  ),
                ),
                const SizedBox(width: 38),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              children: [
                _label('1 · UPLOAD YOUR QUOTE'),
                const SizedBox(height: 10),
                _uploadBox(),
                const SizedBox(height: 20),
                _label('2 · KEY FIGURES'),
                const SizedBox(height: 10),
                _figuresCard(),
                const SizedBox(height: 20),
                _label('3 · INCLUSIONS / EXCLUSIONS'),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: _paper,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  padding: const EdgeInsets.all(13),
                  child: TextField(
                    controller: _notesCtl,
                    maxLines: 4,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                        fontFamily: _body,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                        height: 1.45),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText:
                          'What\'s included, what\'s excluded, deposit terms…',
                      hintStyle: TextStyle(color: _faint),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // submit bar
          Container(
            decoration: const BoxDecoration(
              color: _paper,
              border: Border(top: BorderSide(color: _surface)),
            ),
            padding: EdgeInsets.fromLTRB(20, 14, 20, bottom + 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: canSubmit && !_saving ? _submit : null,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: canSubmit ? _lime : const Color(0xFFB7C2C7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(_ink)))
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.send_rounded, size: 19, color: _ink),
                              SizedBox(width: 8),
                              Text('Submit quote',
                                  style: TextStyle(
                                      fontFamily: _body,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: _ink)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.lock_outline_rounded, size: 13, color: _faint),
                    SizedBox(width: 5),
                    Text('Only the project owner sees your quote',
                        style: TextStyle(
                            fontFamily: _body,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _faint)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) => Material(
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

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          fontFamily: _body,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: _inkMute));

  Widget _uploadBox() {
    if (_fileAttached) {
      return Container(
        decoration: BoxDecoration(
          color: _sage,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: _ink, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.picture_as_pdf_rounded,
                  size: 21, color: _paper),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: _body,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _ink)),
                  const SizedBox(height: 2),
                  const Text('Attached',
                      style: TextStyle(
                          fontFamily: _body,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _inkMute)),
                ],
              ),
            ),
            InkWell(
              onTap: _removeFile,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close_rounded, size: 19, color: _inkMute),
              ),
            ),
          ],
        ),
      );
    }
    return InkWell(
      onTap: _pickFile,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: _sage,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: _ink, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.upload_file_rounded,
                  size: 28, color: _paper),
            ),
            const SizedBox(height: 12),
            const Text('Drop your quote PDF',
                style: TextStyle(
                    fontFamily: _display,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _ink)),
            const SizedBox(height: 4),
            const Text('or take a photo of a paper quote',
                style: TextStyle(
                    fontFamily: _body,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _inkMute)),
          ],
        ),
      ),
    );
  }

  Widget _figuresCard() {
    return Container(
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          // amount
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Amount (excl. VAT)',
                      style: TextStyle(
                          fontFamily: _body,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _ink)),
                ),
                Container(
                  width: 140,
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                      color: _surface, borderRadius: BorderRadius.circular(9)),
                  child: Row(
                    children: [
                      const Text('R',
                          style: TextStyle(
                              fontFamily: 'Roboto Mono',
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _faint)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _amountCtl,
                          textInputAction: TextInputAction.done,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          textAlign: TextAlign.right,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                              fontFamily: 'Roboto Mono',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _ink),
                          decoration: const InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: '0',
                            hintStyle: TextStyle(color: _faint),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: _line),
          // vat toggle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Add VAT @ 15%',
                      style: TextStyle(
                          fontFamily: _body,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _ink)),
                ),
                _switch(_vatIncluded,
                    () => setState(() => _vatIncluded = !_vatIncluded)),
              ],
            ),
          ),
          Container(height: 1, color: _line),
          // lead time
          _stepperRow(
              'Can start in',
              '$_leadWeeks wks',
              () => setState(() => _leadWeeks = (_leadWeeks - 1).clamp(0, 99)),
              () => setState(() => _leadWeeks = (_leadWeeks + 1).clamp(0, 99))),
          Container(height: 1, color: _line),
          // deposit
          _stepperRow(
              'Deposit',
              '$_depositPct%',
              () =>
                  setState(() => _depositPct = (_depositPct - 5).clamp(0, 100)),
              () => setState(
                  () => _depositPct = (_depositPct + 5).clamp(0, 100))),
          Container(height: 1, color: _line),
          // total
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Total',
                      style: TextStyle(
                          fontFamily: _body,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _ink)),
                ),
                Text(_money(_total),
                    style: const TextStyle(
                        fontFamily: 'Roboto Mono',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _switch(bool on, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 46,
          height: 27,
          padding: const EdgeInsets.all(3),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
              color: on ? _green : const Color(0xFFCBD8DD),
              borderRadius: BorderRadius.circular(999)),
          child: Container(
            width: 21,
            height: 21,
            decoration:
                const BoxDecoration(color: _paper, shape: BoxShape.circle),
          ),
        ),
      );

  Widget _stepperRow(
      String label, String value, VoidCallback minus, VoidCallback plus) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontFamily: _body,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _ink)),
          ),
          _round(Icons.remove_rounded, false, minus),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(value,
                style: const TextStyle(
                    fontFamily: _display,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _ink)),
          ),
          _round(Icons.add_rounded, true, plus),
        ],
      ),
    );
  }

  Widget _round(IconData icon, bool solid, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: solid ? _ink : _paper,
            shape: BoxShape.circle,
            border: solid ? null : Border.all(color: const Color(0xFFDCE3E6)),
          ),
          child: Icon(icon, size: 16, color: solid ? _paper : _ink),
        ),
      );
}
