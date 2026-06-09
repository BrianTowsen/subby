import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'get_quotes_page_model.dart';
export 'get_quotes_page_model.dart';

class GetQuotesPageWidget extends StatefulWidget {
  const GetQuotesPageWidget({super.key});

  static String routeName = 'getQuotesPage';
  static String routePath = '/getQuotesPage';

  @override
  State<GetQuotesPageWidget> createState() => _GetQuotesPageWidgetState();
}

class _GetQuotesPageWidgetState extends State<GetQuotesPageWidget> {
  late GetQuotesPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => GetQuotesPageModel());
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
          child: custom_widgets.GetQuotesPageView(
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }
}
