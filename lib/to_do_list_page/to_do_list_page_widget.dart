import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'to_do_list_page_model.dart';
export 'to_do_list_page_model.dart';

class ToDoListPageWidget extends StatefulWidget {
  const ToDoListPageWidget({super.key});

  static String routeName = 'toDoListPage';
  static String routePath = '/toDoListPage';

  @override
  State<ToDoListPageWidget> createState() => _ToDoListPageWidgetState();
}

class _ToDoListPageWidgetState extends State<ToDoListPageWidget> {
  late ToDoListPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ToDoListPageModel());
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
          child: custom_widgets.ToDoListPageView(
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }
}
