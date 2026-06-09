import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'project_cost_home_page_model.dart';
export 'project_cost_home_page_model.dart';

class ProjectCostHomePageWidget extends StatefulWidget {
  const ProjectCostHomePageWidget({
    super.key,
    required this.projectRef,
  });

  final DocumentReference? projectRef;

  static String routeName = 'projectCostHomePage';
  static String routePath = '/projectCostHomePage';

  @override
  State<ProjectCostHomePageWidget> createState() =>
      _ProjectCostHomePageWidgetState();
}

class _ProjectCostHomePageWidgetState extends State<ProjectCostHomePageWidget> {
  late ProjectCostHomePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProjectCostHomePageModel());
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
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          child: custom_widgets.ProjectCostHomePageView(
            width: double.infinity,
            height: double.infinity,
            dashboardRouteName: 'dashboardPage',
            projectRef: widget.projectRef,
          ),
        ),
      ),
    );
  }
}
