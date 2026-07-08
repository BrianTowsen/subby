import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'quotes_received_model.dart';
export 'quotes_received_model.dart';

class QuotesReceivedWidget extends StatefulWidget {
  const QuotesReceivedWidget({super.key});

  static String routeName = 'QuotesReceived';
  static String routePath = '/quotesReceived';

  @override
  State<QuotesReceivedWidget> createState() => _QuotesReceivedWidgetState();
}

class _QuotesReceivedWidgetState extends State<QuotesReceivedWidget> {
  late QuotesReceivedModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => QuotesReceivedModel());
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
          width: MediaQuery.sizeOf(context).width * 1.0,
          height: MediaQuery.sizeOf(context).height * 1.0,
          child: custom_widgets.QuotesReceivedView(
            width: MediaQuery.sizeOf(context).width * 1.0,
            height: MediaQuery.sizeOf(context).height * 1.0,
            inviteRouteName: 'Invite',
            quoteDetailRouteName: 'QuoteDetail',
          ),
        ),
      ),
    );
  }
}
