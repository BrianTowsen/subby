import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'document_upload_page_model.dart';
export 'document_upload_page_model.dart';

class DocumentUploadPageWidget extends StatefulWidget {
  const DocumentUploadPageWidget({
    super.key,
    required this.projectRef,
  });

  final DocumentReference? projectRef;

  static String routeName = 'documentUploadPage';
  static String routePath = '/documentUploadPage';

  @override
  State<DocumentUploadPageWidget> createState() =>
      _DocumentUploadPageWidgetState();
}

class _DocumentUploadPageWidgetState extends State<DocumentUploadPageWidget> {
  late DocumentUploadPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DocumentUploadPageModel());
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
          child: custom_widgets.DocumentUploadPageView(
            width: double.infinity,
            height: double.infinity,
            projectRef: widget.projectRef,
          ),
        ),
      ),
    );
  }
}
