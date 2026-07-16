import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'check_list_page_model.dart';
export 'check_list_page_model.dart';

class CheckListPageWidget extends StatefulWidget {
  const CheckListPageWidget({super.key});

  static String routeName = 'CheckListPage';
  static String routePath = '/checkListPage';

  @override
  State<CheckListPageWidget> createState() => _CheckListPageWidgetState();
}

class _CheckListPageWidgetState extends State<CheckListPageWidget> {
  late CheckListPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CheckListPageModel());
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
          width: double.infinity,
          height: double.infinity,
          child: custom_widgets.CheckListPageView(
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }
}
