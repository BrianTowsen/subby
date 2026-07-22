// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom widgets

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'invite_member_view.dart' show showInviteMemberSheet;

class AdminMembersView extends StatefulWidget {
  const AdminMembersView({
    Key? key,
    this.width,
    this.height,
    this.role,
  }) : super(key: key);

  final double? width;
  final double? height;

  /// 'office' | 'client' | 'provider'. Defaults to 'office' when embedded.
  final String? role;

  @override
  State<AdminMembersView> createState() => _AdminMembersViewState();
}

class _AdminMembersViewState extends State<AdminMembersView> {
  static const String _kActiveProjectPath = 'subby_active_project_path';

  DocumentReference? _projectRef;
  String _projectName = 'Project';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final path = (prefs.getString(_kActiveProjectPath) ?? '').trim();
    if (path.isNotEmpty) {
      final ref = FirebaseFirestore.instance.doc(path);
      try {
        final snap = await ref.get();
        final d = snap.data() as Map<String, dynamic>? ?? const {};
        _projectName = (d['name'] ?? 'Project').toString();
      } catch (_) {}
      _projectRef = ref;
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 1.8),
        ),
      );
    }
    if (_projectRef == null) {
      return const Center(
        child: Text('No active project selected.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 13)),
      );
    }
    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      child: _AdminMembersSheet(
        projectRef: _projectRef!,
        projectName: _projectName,
        role: widget.role ?? 'office',
        embedded: true,
      ),
    );
  }
}

/// Opens the per-role manage sheet from the project page's ADMIN tiles.
/// role: 'office' | 'client' | 'provider'.
Future<void> showAdminMembersSheet(
  BuildContext context, {
  required DocumentReference projectRef,
  required String projectName,
  required String role,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _AdminMembersSheet(
        projectRef: projectRef,
        projectName: projectName,
        role: role,
      ),
    ),
  );
}

class _AdminMembersSheet extends StatefulWidget {
  const _AdminMembersSheet({
    required this.projectRef,
    required this.projectName,
    required this.role,
    this.embedded = false,
  });

  final DocumentReference projectRef;
  final String projectName;
  final String role;
  final bool embedded;

  @override
  State<_AdminMembersSheet> createState() => _AdminMembersSheetState();
}

class _AdminMembersSheetState extends State<_AdminMembersSheet> {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  static const Color _ink = Color(0xFF1E282E);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _hairline = Color(0xFFEAEEF0);
  static const Color _spark = Color(0xFFE7E247);
  static const Color _sparkInk = Color(0xFF1E282E);
  static const Color _warn = Color(0xFFAC0C0C);
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  // Self-contained permission model (do NOT import from generated schema
  // files — FlutterFlow regenerates those).
  static const List<Map<String, String>> _permDefs = [
    {'key': 'viewTimeline', 'label': 'View timeline'},
    {'key': 'viewDocs', 'label': 'View documents & drawings'},
    {'key': 'viewCost', 'label': 'View costs & quote amounts'},
    {'key': 'editTasks', 'label': 'Work on tasks'},
    {'key': 'siteBook', 'label': 'Post in site book'},
    {'key': 'snags', 'label': 'Work on snags'},
    {'key': 'quotes', 'label': 'View quotes module'},
  ];

  static const Map<String, Map<String, bool>> _roleDefaults = {
    'office': {
      'viewTimeline': true,
      'viewDocs': true,
      'viewCost': false,
      'editTasks': true,
      'siteBook': true,
      'snags': true,
      'quotes': true,
    },
    'foreman': {
      'viewTimeline': true,
      'viewDocs': true,
      'viewCost': false,
      'editTasks': true,
      'siteBook': true,
      'snags': true,
      'quotes': false,
    },
    'client': {
      'viewTimeline': true,
      'viewDocs': true,
      'viewCost': false,
      'editTasks': false,
      'siteBook': false,
      'snags': false,
      'quotes': false,
    },
  };

  String? _expandedMemberPath;
  Map<String, bool> _editPerms = {};
  bool _saving = false;

  String get _roleTitle {
    switch (widget.role) {
      case 'office':
        return 'Office / Team';
      case 'foreman':
        return 'Site Foreman';
      case 'client':
        return 'Owner / Guest';
      case 'provider':
        return 'Service Providers';
      default:
        return widget.role;
    }
  }

  String get _roleSubtitle {
    switch (widget.role) {
      case 'office':
        return 'Your staff working on this project — no Network listing '
            'needed.';
      case 'foreman':
        return 'Runs the site day-to-day — tasks, site book, snags and '
            'drawings. No Network listing needed.';
      case 'client':
        return 'The client or a guest following the project — view access '
            'by default.';
      case 'provider':
        return 'Tradespeople join the project team with their Subby Network '
            'listing. New invitees without a listing are guided through '
            'registration first.';
      default:
        return '';
    }
  }

  // ── Data ───────────────────────────────────────────────────────────

  Stream<QuerySnapshot<Map<String, dynamic>>> _membersStream() =>
      FirebaseFirestore.instance
          .collection('project_members')
          .where('projectRef', isEqualTo: widget.projectRef)
          .where('role', isEqualTo: widget.role)
          .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> _invitesStream() =>
      FirebaseFirestore.instance
          .collection('project_invites')
          .where('projectRef', isEqualTo: widget.projectRef)
          .where('status', isEqualTo: 'pending')
          .snapshots();

  Map<String, bool> _effectivePerms(Map<String, dynamic> member) {
    final defaults = _roleDefaults[widget.role] ?? const <String, bool>{};
    final out = <String, bool>{...defaults};
    final raw = member['permissions'];
    if (raw is Map) {
      for (final d in _permDefs) {
        final k = d['key']!;
        if (raw[k] is bool) out[k] = raw[k] as bool;
      }
    } else if (member['canViewCost'] is bool) {
      out['viewCost'] = member['canViewCost'] as bool;
    }
    return out;
  }

  Future<void> _savePerms(DocumentReference memberRef) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await memberRef.update({
        'permissions': _editPerms,
        'canViewCost': _editPerms['viewCost'] == true,
      });
      if (!mounted) return;
      setState(() {
        _saving = false;
        _expandedMemberPath = null;
      });
      showAppToast(context, 'Permissions updated.', true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppToast(context, 'Could not save permissions.', false);
    }
  }

  Future<void> _removeMember(
      DocumentReference memberRef, String displayName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Remove from project?',
            style: TextStyle(
                fontFamily: _displayFont,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _ink)),
        content: Text(
            '$displayName will lose access to “${widget.projectName}”.',
            style: const TextStyle(
                fontFamily: _bodyFont,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _inkMute)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(
                    fontFamily: _bodyFont,
                    fontWeight: FontWeight.w700,
                    color: _inkMute)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove',
                style: TextStyle(
                    fontFamily: _bodyFont,
                    fontWeight: FontWeight.w800,
                    color: _warn)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await memberRef.delete();
      if (!mounted) return;
      showAppToast(context, 'Removed from project.', true);
    } catch (_) {
      if (!mounted) return;
      showAppToast(context, 'Could not remove member.', false);
    }
  }

  Future<void> _revokeInvite(DocumentReference inviteRef) async {
    try {
      await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('revokeProjectInvite')
          .call(<String, dynamic>{'invitePath': inviteRef.path});
      if (!mounted) return;
      showAppToast(context, 'Invite revoked.', true);
    } catch (_) {
      if (!mounted) return;
      showAppToast(context, 'Could not revoke the invite.', false);
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 18),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontFamily: _bodyFont,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: _faint,
          ),
        ),
      );

  Widget _memberRow(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final userRef = data['userRef'];
    final company = (data['displayCompany'] ?? '').toString().trim();
    final expanded = _expandedMemberPath == doc.reference.path;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              if (expanded) {
                _expandedMemberPath = null;
              } else {
                _expandedMemberPath = doc.reference.path;
                _editPerms = _effectivePerms(data);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _hairline, width: 1)),
            ),
            child: Row(children: [
              Expanded(
                child: FutureBuilder<DocumentSnapshot>(
                  // future is nullable — a member doc without a userRef just
                  // renders the fallback labels instead of crashing.
                  future: userRef is DocumentReference ? userRef.get() : null,
                  builder: (context, snap) {
                    final u =
                        snap.data?.data() as Map<String, dynamic>? ?? const {};
                    final name = (u['display_name'] ?? '').toString().trim();
                    final email = (u['email'] ?? '').toString().trim();
                    final title = name.isNotEmpty
                        ? name
                        : (email.isNotEmpty ? email : 'Member');
                    final sub = company.isNotEmpty
                        ? company
                        : (name.isNotEmpty ? email : '');
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontFamily: _bodyFont,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _ink)),
                        if (sub.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(sub,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontFamily: _bodyFont,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: _faint)),
                        ],
                      ],
                    );
                  },
                ),
              ),
              Icon(
                expanded ? Icons.expand_less_rounded : Icons.tune_rounded,
                size: 18,
                color: _inkMute,
              ),
            ]),
          ),
        ),
        if (expanded) _permEditor(doc.reference),
      ],
    );
  }

  Widget _permEditor(DocumentReference memberRef) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._permDefs.map((d) {
            final k = d['key']!;
            return Row(children: [
              Expanded(
                child: Text(d['label']!,
                    style: const TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _ink)),
              ),
              Switch(
                value: _editPerms[k] ?? false,
                activeColor: _sparkInk,
                activeTrackColor: _spark,
                onChanged: (v) => setState(() => _editPerms[k] = v),
              ),
            ]);
          }),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: _saving ? null : () => _savePerms(memberRef),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _spark,
                    foregroundColor: _sparkInk,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9)),
                  ),
                  child: Text(_saving ? 'Saving…' : 'Save permissions',
                      style: const TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _sparkInk)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 40,
              child: OutlinedButton(
                onPressed: () async {
                  final snap = await memberRef.get();
                  final data = snap.data() as Map<String, dynamic>? ?? const {};
                  final userRef = data['userRef'];
                  String name = 'This member';
                  if (userRef is DocumentReference) {
                    try {
                      final u = await userRef.get();
                      final ud = u.data() as Map<String, dynamic>? ?? const {};
                      final n = (ud['display_name'] ?? '').toString().trim();
                      if (n.isNotEmpty) name = n;
                    } catch (_) {}
                  }
                  if (!mounted) return;
                  _removeMember(memberRef, name);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _warn,
                  side: const BorderSide(color: _warn, width: 1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9)),
                ),
                child: const Text('Remove',
                    style: TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _membersSection() {
    if (widget.role == 'provider') {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'Providers who join appear under PROJECT TEAM on the project '
          'page, with their Network listing.',
          style: const TextStyle(
            fontFamily: _bodyFont,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            height: 1.4,
            color: _inkMute,
          ),
        ),
      );
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _membersStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text('Loading…',
                style: TextStyle(
                    fontFamily: _bodyFont, fontSize: 12, color: _faint)),
          );
        }
        final docs = snap.data?.docs ?? const [];
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text('Nobody here yet — send an invite below.',
                style: TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _faint)),
          );
        }
        return Column(children: docs.map(_memberRow).toList());
      },
    );
  }

  Widget _invitesSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _invitesStream(),
      builder: (context, snap) {
        final docs = (snap.data?.docs ?? const [])
            .where((d) => (d.data()['role'] ?? '') == widget.role)
            .toList();
        if (docs.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Pending invites'),
            ...docs.map((d) {
              final data = d.data();
              final code = (data['code'] ?? '').toString();
              final name = (data['inviteeName'] ?? '').toString().trim();
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: const BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: _hairline, width: 1)),
                ),
                child: Row(children: [
                  Expanded(
                    child: Text(
                      name.isEmpty ? code : '$name · $code',
                      style: const TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _ink),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _revokeInvite(d.reference),
                    icon:
                        const Icon(Icons.close_rounded, size: 18, color: _warn),
                    tooltip: 'Revoke invite',
                  ),
                ]),
              );
            }),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: widget.embedded
            ? BorderRadius.zero
            : const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.embedded)
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: _hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          Text(_roleTitle,
              style: const TextStyle(
                fontFamily: _displayFont,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: _ink,
              )),
          const SizedBox(height: 3),
          Text(_roleSubtitle,
              style: const TextStyle(
                fontFamily: _bodyFont,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: _inkMute,
              )),
          const SizedBox(height: 8),
          _membersSection(),
          _invitesSection(),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () => showInviteMemberSheet(
                context,
                projectRef: widget.projectRef,
                projectName: widget.projectName,
                fixedRole: widget.role,
                showPendingList: false,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _spark,
                foregroundColor: _sparkInk,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.person_add_alt, size: 18),
              label: Text(
                widget.role == 'provider'
                    ? 'Invite a service provider'
                    : 'Invite ${_roleTitle.toLowerCase()}',
                style: const TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _sparkInk),
              ),
            ),
          ),
        ],
      ),
    );
    if (widget.embedded) return SingleChildScrollView(child: content);
    return SafeArea(top: false, child: SingleChildScrollView(child: content));
  }
}
