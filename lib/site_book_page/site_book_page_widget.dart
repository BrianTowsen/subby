import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'site_book_page_model.dart';
export 'site_book_page_model.dart';

class SiteBookPageWidget extends StatefulWidget {
  const SiteBookPageWidget({
    super.key,
    this.projectRef,
  });

  final DocumentReference? projectRef;

  static String routeName = 'SiteBookPage';
  static String routePath = '/siteBookPage';

  @override
  State<SiteBookPageWidget> createState() => _SiteBookPageWidgetState();
}

class _SiteBookPageWidgetState extends State<SiteBookPageWidget> {
  late SiteBookPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SiteBookPageModel());
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
          child: custom_widgets.SiteBookPageView(
            width: MediaQuery.sizeOf(context).width * 1.0,
            height: MediaQuery.sizeOf(context).height * 1.0,
            projectRef: widget.projectRef,
          ),
        ),
      ),
    );
  }
}
