import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'get_quotes_home_page_model.dart';
export 'get_quotes_home_page_model.dart';

class GetQuotesHomePageWidget extends StatefulWidget {
  const GetQuotesHomePageWidget({
    super.key,
    required this.projectRef,
  });

  final DocumentReference? projectRef;

  static String routeName = 'getQuotesHomePage';
  static String routePath = '/getQuotesHomePage';

  @override
  State<GetQuotesHomePageWidget> createState() =>
      _GetQuotesHomePageWidgetState();
}

class _GetQuotesHomePageWidgetState extends State<GetQuotesHomePageWidget> {
  late GetQuotesHomePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => GetQuotesHomePageModel());
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
          child: custom_widgets.GetQuotesHomePageView(
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
