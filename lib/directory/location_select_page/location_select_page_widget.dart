import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'location_select_page_model.dart';
export 'location_select_page_model.dart';

class LocationSelectPageWidget extends StatefulWidget {
  const LocationSelectPageWidget({
    super.key,
    required this.speciality,
    this.initialProvince,
    required this.category,
    required this.searchText,
    required this.preselectedProvince,
    required this.initialRegion,
  });

  final String? speciality;
  final String? initialProvince;
  final String? category;
  final String? searchText;
  final String? preselectedProvince;
  final String? initialRegion;

  static String routeName = 'LocationSelectPage';
  static String routePath = '/locationSelectPage';

  @override
  State<LocationSelectPageWidget> createState() =>
      _LocationSelectPageWidgetState();
}

class _LocationSelectPageWidgetState extends State<LocationSelectPageWidget> {
  late LocationSelectPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LocationSelectPageModel());
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
          child: custom_widgets.LocationSelectPageView(
            width: double.infinity,
            height: double.infinity,
            initialProvince: widget.initialProvince,
            category: widget.category,
            searchText: widget.searchText,
            initialRegion: widget.initialRegion,
          ),
        ),
      ),
    );
  }
}
