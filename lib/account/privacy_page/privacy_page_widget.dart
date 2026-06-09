import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'privacy_page_model.dart';
export 'privacy_page_model.dart';

class PrivacyPageWidget extends StatefulWidget {
  const PrivacyPageWidget({super.key});

  static String routeName = 'privacyPage';
  static String routePath = '/privacyPage';

  @override
  State<PrivacyPageWidget> createState() => _PrivacyPageWidgetState();
}

class _PrivacyPageWidgetState extends State<PrivacyPageWidget> {
  late PrivacyPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PrivacyPageModel());
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
          child: custom_widgets.PrivacyPageView(
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }
}
