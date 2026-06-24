import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'snag_list_page_model.dart';
export 'snag_list_page_model.dart';

class SnagListPageWidget extends StatefulWidget {
  const SnagListPageWidget({super.key});

  static String routeName = 'snagListPage';
  static String routePath = '/snagListPage';

  @override
  State<SnagListPageWidget> createState() => _SnagListPageWidgetState();
}

class _SnagListPageWidgetState extends State<SnagListPageWidget> {
  late SnagListPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SnagListPageModel());
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
      child: PopScope(
        canPop: false,
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          body: Container(
            width: double.infinity,
            height: double.infinity,
            child: custom_widgets.SnagListPageView(
              width: double.infinity,
              height: double.infinity,
              addSnagRouteName: 'AddSnagPage',
              snagDetailRouteName: 'DetailSnagPage',
              backRouteName: '',
            ),
          ),
        ),
      ),
    );
  }
}
