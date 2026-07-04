import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'detail_site_book_page_model.dart';
export 'detail_site_book_page_model.dart';

class DetailSiteBookPageWidget extends StatefulWidget {
  const DetailSiteBookPageWidget({
    super.key,
    this.entryRef,
  });

  final DocumentReference? entryRef;

  static String routeName = 'DetailSiteBookPage';
  static String routePath = '/detailSiteBookPage';

  @override
  State<DetailSiteBookPageWidget> createState() =>
      _DetailSiteBookPageWidgetState();
}

class _DetailSiteBookPageWidgetState extends State<DetailSiteBookPageWidget> {
  late DetailSiteBookPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DetailSiteBookPageModel());
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
          child: custom_widgets.DetailSiteBookPageView(
            width: MediaQuery.sizeOf(context).width * 1.0,
            height: MediaQuery.sizeOf(context).height * 1.0,
            entryRef: widget.entryRef,
          ),
        ),
      ),
    );
  }
}
