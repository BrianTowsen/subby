import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'add_snag_page_model.dart';
export 'add_snag_page_model.dart';

class AddSnagPageWidget extends StatefulWidget {
  const AddSnagPageWidget({super.key});

  static String routeName = 'AddSnagPage';
  static String routePath = '/addSnagPage';

  @override
  State<AddSnagPageWidget> createState() => _AddSnagPageWidgetState();
}

class _AddSnagPageWidgetState extends State<AddSnagPageWidget> {
  late AddSnagPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddSnagPageModel());
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
        body: SafeArea(
          top: true,
          child: Container(
            width: MediaQuery.sizeOf(context).width * 1.0,
            height: MediaQuery.sizeOf(context).height * 1.0,
            child: custom_widgets.AddSnagPageView(
              width: MediaQuery.sizeOf(context).width * 1.0,
              height: MediaQuery.sizeOf(context).height * 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
