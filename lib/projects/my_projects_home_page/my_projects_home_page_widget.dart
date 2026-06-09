import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'my_projects_home_page_model.dart';
export 'my_projects_home_page_model.dart';

class MyProjectsHomePageWidget extends StatefulWidget {
  const MyProjectsHomePageWidget({super.key});

  static String routeName = 'MyProjectsHomePage';
  static String routePath = '/myProjectsHomePage';

  @override
  State<MyProjectsHomePageWidget> createState() =>
      _MyProjectsHomePageWidgetState();
}

class _MyProjectsHomePageWidgetState extends State<MyProjectsHomePageWidget> {
  late MyProjectsHomePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MyProjectsHomePageModel());
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
          child: custom_widgets.MyProjectsHomePageView(
            width: double.infinity,
            height: double.infinity,
            projectDetailRouteName: 'ProjectDetailPage',
            dashboardRouteName: 'dashboardPage',
            addProjectsRouteName: 'addProjectsPage',
            projectParamName: '',
          ),
        ),
      ),
    );
  }
}
