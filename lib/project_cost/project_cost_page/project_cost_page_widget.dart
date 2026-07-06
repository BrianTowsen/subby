import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'project_cost_page_model.dart';
export 'project_cost_page_model.dart';

class ProjectCostPageWidget extends StatefulWidget {
  const ProjectCostPageWidget({super.key});

  static String routeName = 'projectCostPage';
  static String routePath = '/projectCostPage';

  @override
  State<ProjectCostPageWidget> createState() => _ProjectCostPageWidgetState();
}

class _ProjectCostPageWidgetState extends State<ProjectCostPageWidget> {
  late ProjectCostPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProjectCostPageModel());
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
          child: custom_widgets.ProjectCostView(
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }
}
