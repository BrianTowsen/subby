import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'project_detail_page_model.dart';
export 'project_detail_page_model.dart';

class ProjectDetailPageWidget extends StatefulWidget {
  const ProjectDetailPageWidget({
    super.key,
    required this.projectRef,
    required this.listingRef,
  });

  final DocumentReference? projectRef;
  final DocumentReference? listingRef;

  static String routeName = 'ProjectDetailPage';
  static String routePath = '/projectDetailPage';

  @override
  State<ProjectDetailPageWidget> createState() =>
      _ProjectDetailPageWidgetState();
}

class _ProjectDetailPageWidgetState extends State<ProjectDetailPageWidget> {
  late ProjectDetailPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProjectDetailPageModel());
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
          child: custom_widgets.ProjectDetailPageView(
            width: double.infinity,
            height: double.infinity,
            editProjectRouteName: 'editProjectPage',
            timelineRouteName: 'projectTimelinePage',
            projectCostRouteName: 'projectCostPage',
            getQuotesRouteName: 'getQuotesPage',
            snagListRouteName: 'snagListPage',
            projectParamName: '',
            projectRef: widget.projectRef,
            listingDetailRouteName: 'listingDetailPage',
            listingParamName: '',
            documentUploadRouteName: 'documentUploadPage',
            toDoListRouteName: 'toDoListPage',
            siteBookRouteName: 'SiteBookPage',
          ),
        ),
      ),
    );
  }
}
