import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'listing_detail_page_model.dart';
export 'listing_detail_page_model.dart';

class ListingDetailPageWidget extends StatefulWidget {
  const ListingDetailPageWidget({
    super.key,
    required this.listingRef,
  });

  final DocumentReference? listingRef;

  static String routeName = 'listingDetailPage';
  static String routePath = '/listingDetailPage';

  @override
  State<ListingDetailPageWidget> createState() =>
      _ListingDetailPageWidgetState();
}

class _ListingDetailPageWidgetState extends State<ListingDetailPageWidget> {
  late ListingDetailPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ListingDetailPageModel());
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SubbyListingsRecord>(
      stream: SubbyListingsRecord.getDocument(widget.listingRef!),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FlutterFlowTheme.of(context).primary,
                  ),
                ),
              ),
            ),
          );
        }

        final listingDetailPageSubbyListingsRecord = snapshot.data!;

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
              child: custom_widgets.ListingDetailPageView(
                width: double.infinity,
                height: double.infinity,
                listingRef: widget.listingRef,
              ),
            ),
          ),
        );
      },
    );
  }
}
