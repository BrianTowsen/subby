import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'detail_task_page_model.dart';
export 'detail_task_page_model.dart';

class DetailTaskPageWidget extends StatefulWidget {
  const DetailTaskPageWidget({super.key});

  static String routeName = 'DetailTaskPage';
  static String routePath = '/detailTaskPage';

  @override
  State<DetailTaskPageWidget> createState() => _DetailTaskPageWidgetState();
}

class _DetailTaskPageWidgetState extends State<DetailTaskPageWidget> {
  late DetailTaskPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DetailTaskPageModel());
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
        body: SafeArea(
          top: true,
          child: Container(
            width: MediaQuery.sizeOf(context).width * 1.0,
            height: MediaQuery.sizeOf(context).height * 1.0,
            child: custom_widgets.DetailTaskPageView(
              width: MediaQuery.sizeOf(context).width * 1.0,
              height: MediaQuery.sizeOf(context).height * 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
