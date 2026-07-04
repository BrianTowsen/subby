import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'edit_project_timeline_page_model.dart';
export 'edit_project_timeline_page_model.dart';

class EditProjectTimelinePageWidget extends StatefulWidget {
  const EditProjectTimelinePageWidget({
    super.key,
    this.projectRef,
  });

  final DocumentReference? projectRef;

  static String routeName = 'EditProjectTimelinePage';
  static String routePath = '/editProjectTimelinePage';

  @override
  State<EditProjectTimelinePageWidget> createState() =>
      _EditProjectTimelinePageWidgetState();
}

class _EditProjectTimelinePageWidgetState
    extends State<EditProjectTimelinePageWidget> {
  late EditProjectTimelinePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EditProjectTimelinePageModel());
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
          child: custom_widgets.EditTimelinePageView(
            width: MediaQuery.sizeOf(context).width * 1.0,
            height: MediaQuery.sizeOf(context).height * 1.0,
            projectRef: widget.projectRef,
          ),
        ),
      ),
    );
  }
}
