import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SpData {
  static const _isSelectedMethod = "isSelectedMethod";
  static const _tokenValue = "tokenValue";
  static const _userData = "userData";
  static const _storeId = "storeId";


  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> setUseMethod(bool data) {
    return _prefs.setBool(_isSelectedMethod, data);
  }

  static bool? getUseMethod() {
    return _prefs.getBool(_isSelectedMethod);
  }

  static Future<void> setTokenValue(String data) {
    return _prefs.setString(_tokenValue, data);
  }

  static Future<void> removeTokenValue() {
    return _prefs.remove(_tokenValue);
  }

  static String? getTokenValue() {
    return _prefs.getString(_tokenValue);
  }

  static Future<void> setStoreId(String storeId) {
    return _prefs.setString(_storeId, storeId);
  }

  static Future<void> removeStoreId() {
    return _prefs.remove(_storeId);
  }

  static String? getStoreId() {
    return _prefs.getString(_storeId);
  }

  static const String _apiResponseKey = 'api_response';

}