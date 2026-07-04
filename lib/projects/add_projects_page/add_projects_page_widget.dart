import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'add_projects_page_model.dart';
export 'add_projects_page_model.dart';

class AddProjectsPageWidget extends StatefulWidget {
  const AddProjectsPageWidget({super.key});

  static String routeName = 'addProjectsPage';
  static String routePath = '/addProjectsPage';

  @override
  State<AddProjectsPageWidget> createState() => _AddProjectsPageWidgetState();
}

class _AddProjectsPageWidgetState extends State<AddProjectsPageWidget> {
  late AddProjectsPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddProjectsPageModel());
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
          child: custom_widgets.AddProjectsPageView(
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }
}
