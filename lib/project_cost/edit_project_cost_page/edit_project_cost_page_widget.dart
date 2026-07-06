import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'edit_project_cost_page_model.dart';
export 'edit_project_cost_page_model.dart';

class EditProjectCostPageWidget extends StatefulWidget {
  const EditProjectCostPageWidget({
    super.key,
    this.projectRef,
  });

  final DocumentReference? projectRef;

  static String routeName = 'EditProjectCostPage';
  static String routePath = '/editProjectCostPage';

  @override
  State<EditProjectCostPageWidget> createState() =>
      _EditProjectCostPageWidgetState();
}

class _EditProjectCostPageWidgetState extends State<EditProjectCostPageWidget> {
  late EditProjectCostPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EditProjectCostPageModel());
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
          width: MediaQuery.sizeOf(context).width * 1.0,
          height: MediaQuery.sizeOf(context).height * 1.0,
          child: custom_widgets.EditProjectCostPageView(
            projectRef: widget.projectRef,
            width: MediaQuery.sizeOf(context).width * 1.0,
            height: MediaQuery.sizeOf(context).height * 1.0,
          ),
        ),
      ),
    );
  }
}
