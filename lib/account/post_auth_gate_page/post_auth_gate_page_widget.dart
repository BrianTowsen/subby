import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'post_auth_gate_page_model.dart';
export 'post_auth_gate_page_model.dart';

class PostAuthGatePageWidget extends StatefulWidget {
  const PostAuthGatePageWidget({super.key});

  static String routeName = 'PostAuthGatePage';
  static String routePath = '/postAuthGatePage';

  @override
  State<PostAuthGatePageWidget> createState() => _PostAuthGatePageWidgetState();
}

class _PostAuthGatePageWidgetState extends State<PostAuthGatePageWidget> {
  late PostAuthGatePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PostAuthGatePageModel());
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
          child: custom_widgets.PostAuthGatePageView(
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }
}
