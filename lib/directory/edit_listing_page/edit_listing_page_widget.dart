import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'edit_listing_page_model.dart';
export 'edit_listing_page_model.dart';

class EditListingPageWidget extends StatefulWidget {
  const EditListingPageWidget({
    super.key,
    required this.listingRef,
  });

  final DocumentReference? listingRef;

  static String routeName = 'editListingPage';
  static String routePath = '/editListingPage';

  @override
  State<EditListingPageWidget> createState() => _EditListingPageWidgetState();
}

class _EditListingPageWidgetState extends State<EditListingPageWidget> {
  late EditListingPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EditListingPageModel());
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
          child: custom_widgets.EditListingPageView(
            width: double.infinity,
            height: double.infinity,
            listingRef: widget.listingRef,
          ),
        ),
      ),
    );
  }
}
