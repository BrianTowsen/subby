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
  static const double _hPad = 24;
  static const double _vPad = 24;
  static const double _radius = 16;

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

  TextStyle _titleStyle(FlutterFlowTheme theme) {
    return theme.titleLarge.copyWith(
      fontWeight: FontWeight.w900,
      letterSpacing: 0.2,
    );
  }

  TextStyle _subtitleStyle(FlutterFlowTheme theme) {
    return theme.bodySmall.override(
      fontFamily: theme.bodySmallFamily,
      color: theme.secondaryText,
    );
  }

  Widget _cardShell(FlutterFlowTheme theme, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: theme.alternate.withOpacity(0.9)),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: theme.primaryBackground,
      child: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: _hPad, vertical: _vPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  InkWell(
                    onTap: _handleBack,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.primaryBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: theme.alternate.withOpacity(0.9),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 22,
                        color: theme.primaryText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('To Do List',
                            style: _titleStyle(theme)
                                .copyWith(color: theme.primaryText)),
                        const SizedBox(height: 4),
                        Text('Tasks and assignments',
                            style: _subtitleStyle(theme)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Project preview (proof it’s wired)
              if (_projectRef == null)
                _cardShell(
                  theme,
                  Text(
                    'No project selected.',
                    style: theme.bodyMedium.override(
                      fontFamily: theme.bodyMediumFamily,
                      color: theme.secondaryText,
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

                    return _cardShell(
                      theme,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: theme.titleMedium.override(
                              fontFamily: theme.titleMediumFamily,
                              color: theme.primaryText,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'To Do content coming next.',
                            style: theme.bodySmall.override(
                              fontFamily: theme.bodySmallFamily,
                              color: theme.secondaryText,
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
