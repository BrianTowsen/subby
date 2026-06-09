import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'to_do_list_home_page_model.dart';
export 'to_do_list_home_page_model.dart';

class ToDoListHomePageWidget extends StatefulWidget {
  const ToDoListHomePageWidget({
    super.key,
    required this.projectRef,
  });

  final DocumentReference? projectRef;

  static String routeName = 'toDoListHomePage';
  static String routePath = '/toDoListHomePage';

  @override
  State<ToDoListHomePageWidget> createState() => _ToDoListHomePageWidgetState();
}

class _ToDoListHomePageWidgetState extends State<ToDoListHomePageWidget> {
  late ToDoListHomePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ToDoListHomePageModel());
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
          child: custom_widgets.ToDoListHomePageView(
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
