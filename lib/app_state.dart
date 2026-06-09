import 'package:flutter/material.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {}

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  String _appProvince = '';
  String get appProvince => _appProvince;
  set appProvince(String value) {
    _appProvince = value;
  }

  String _appCity = '';
  String get appCity => _appCity;
  set appCity(String value) {
    _appCity = value;
  }

  String _appProvinceSlug = '';
  String get appProvinceSlug => _appProvinceSlug;
  set appProvinceSlug(String value) {
    _appProvinceSlug = value;
  }

  String _appCategory = '';
  String get appCategory => _appCategory;
  set appCategory(String value) {
    _appCategory = value;
  }
}
