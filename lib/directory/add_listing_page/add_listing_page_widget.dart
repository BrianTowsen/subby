import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'add_listing_page_model.dart';
export 'add_listing_page_model.dart';

class AddListingPageWidget extends StatefulWidget {
  const AddListingPageWidget({super.key});

  static String routeName = 'addListingPage';
  static String routePath = '/addListingPage';

  @override
  State<AddListingPageWidget> createState() => _AddListingPageWidgetState();
}

class _AddListingPageWidgetState extends State<AddListingPageWidget> {
  late AddListingPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddListingPageModel());
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
          child: custom_widgets.AddListingPageView(
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }
}
