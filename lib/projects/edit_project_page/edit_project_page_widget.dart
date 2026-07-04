import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'edit_project_page_model.dart';
export 'edit_project_page_model.dart';

class EditProjectPageWidget extends StatefulWidget {
  const EditProjectPageWidget({
    super.key,
    required this.projectRef,
  });

  final DocumentReference? projectRef;

  static String routeName = 'editProjectPage';
  static String routePath = '/editProjectPage';

  @override
  State<EditProjectPageWidget> createState() => _EditProjectPageWidgetState();
}

class _EditProjectPageWidgetState extends State<EditProjectPageWidget> {
  late EditProjectPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EditProjectPageModel());
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        resizeToAvoidBottomInset: false,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          child: custom_widgets.EditProjectView(
            width: double.infinity,
            height: double.infinity,
            afterSaveRouteName: 'ProjectDetailPage',
            afterDeleteRouteName: 'dashboardPage',
            projectRef: widget.projectRef,
          ),
        ),
      ),
    );
  }
}
