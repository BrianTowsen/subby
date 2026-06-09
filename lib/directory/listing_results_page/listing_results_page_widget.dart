import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'listing_results_page_model.dart';
export 'listing_results_page_model.dart';

class ListingResultsPageWidget extends StatefulWidget {
  const ListingResultsPageWidget({
    super.key,
    required this.province,
    required this.city,
    required this.speciality,
    required this.category,
    required this.searchText,
    required this.provinceSlug,
    required this.categorySlug,
    required this.specialitySlug,
  });

  final String? province;
  final String? city;
  final String? speciality;
  final String? category;
  final String? searchText;
  final String? provinceSlug;
  final String? categorySlug;
  final String? specialitySlug;

  static String routeName = 'ListingResultsPage';
  static String routePath = '/listingResultsPage';

  @override
  State<ListingResultsPageWidget> createState() =>
      _ListingResultsPageWidgetState();
}

class _ListingResultsPageWidgetState extends State<ListingResultsPageWidget> {
  late ListingResultsPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ListingResultsPageModel());
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
          child: custom_widgets.ListingResultsPageView(
            width: double.infinity,
            height: double.infinity,
            province: widget.province,
            city: widget.city,
            speciality: widget.speciality,
            category: widget.category,
            searchText: widget.searchText,
            provinceSlug: widget.provinceSlug,
            categorySlug: widget.categorySlug,
            specialitySlug: widget.specialitySlug,
          ),
        ),
      ),
    );
  }
}
