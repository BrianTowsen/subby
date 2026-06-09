import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'snag_list_home_page_model.dart';
export 'snag_list_home_page_model.dart';

class SnagListHomePageWidget extends StatefulWidget {
  const SnagListHomePageWidget({
    super.key,
    required this.projectRef,
  });

  final DocumentReference? projectRef;

  static String routeName = 'snagListHomePage';
  static String routePath = '/snagListHomePage';

  @override
  State<SnagListHomePageWidget> createState() => _SnagListHomePageWidgetState();
}

class _SnagListHomePageWidgetState extends State<SnagListHomePageWidget> {
  late SnagListHomePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SnagListHomePageModel());
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
          child: custom_widgets.SnagListHomePageView(
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
