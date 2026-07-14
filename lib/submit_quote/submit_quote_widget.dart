import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'submit_quote_model.dart';
export 'submit_quote_model.dart';

class SubmitQuoteWidget extends StatefulWidget {
  const SubmitQuoteWidget({super.key});

  static String routeName = 'SubmitQuote';
  static String routePath = '/submitQuote';

  @override
  State<SubmitQuoteWidget> createState() => _SubmitQuoteWidgetState();
}

class _SubmitQuoteWidgetState extends State<SubmitQuoteWidget> {
  late SubmitQuoteModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SubmitQuoteModel());
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
          child: custom_widgets.SubmitQuoteView(
            width: MediaQuery.sizeOf(context).width * 1.0,
            height: MediaQuery.sizeOf(context).height * 1.0,
            dashboardRouteName: 'dashboardPage',
          ),
        ),
      ),
    );
  }
}
