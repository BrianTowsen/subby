import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'timeline_home_page_model.dart';
export 'timeline_home_page_model.dart';

class TimelineHomePageWidget extends StatefulWidget {
  const TimelineHomePageWidget({
    super.key,
    required this.projectRef,
  });

  final DocumentReference? projectRef;

  static String routeName = 'TimelineHomePage';
  static String routePath = '/timelineHomePage';

  @override
  State<TimelineHomePageWidget> createState() => _TimelineHomePageWidgetState();
}

class _TimelineHomePageWidgetState extends State<TimelineHomePageWidget> {
  late TimelineHomePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TimelineHomePageModel());
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
          child: custom_widgets.TimelineHomePageView(
            width: double.infinity,
            height: double.infinity,
            timelineDetailRouteName: 'projectTimelinePage',
            dashboardRouteName: 'dashboardPage',
            projectRef: widget.projectRef,
          ),
        ),
      ),
    );
  }
}
