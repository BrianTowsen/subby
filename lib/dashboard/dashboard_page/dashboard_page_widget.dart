import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'dashboard_page_model.dart';
export 'dashboard_page_model.dart';

class DashboardPageWidget extends StatefulWidget {
  const DashboardPageWidget({super.key});

  static String routeName = 'dashboardPage';
  static String routePath = '/dashboardPage';

  @override
  State<DashboardPageWidget> createState() => _DashboardPageWidgetState();
}

class _DashboardPageWidgetState extends State<DashboardPageWidget> {
  late DashboardPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DashboardPageModel());
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
          child: custom_widgets.DashboardPageView(
            width: double.infinity,
            height: double.infinity,
            directoryRouteName: 'homePage',
            timelineRouteName: 'TimelineHomePage',
            snagListRouteName: 'snagListHomePage',
            profileRouteName: 'profilePage',
            projectsRouteName: 'MyProjectsHomePage',
            projectCostRouteName: 'projectCostHomePage',
            getQuotesRouteName: 'getQuotesHomePage',
            termsRouteName: 'termsPage',
            privacyRouteName: 'privacyPage',
            addListingRouteName: 'addListingPage',
            editListingRouteName: 'editListingPage',
          ),
        ),
      ),
    );
  }
}
