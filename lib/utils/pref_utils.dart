//ignore: unused_import
import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

 class PrefUtils {
  static SharedPreferences? _sharedPreferences;

  PrefUtils() {
    // init();
    SharedPreferences.getInstance().then((value) {
      _sharedPreferences = value;
    });
  }

  static Future<void> init() async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
    log('SharedPreference Initialized');
  }

  ///will clear all the data stored in preference
  static void clearPreferencesData() async {
    _sharedPreferences!.clear();
  }

  static Future<void> setThemeData(String value) {
    return _sharedPreferences!.setString('themeData', value);
  }

  static String getThemeData() {
    try {
      return _sharedPreferences!.getString('themeData')!;
    } catch (e) {
      return 'primary';
    }
  }


  static Future<void> setUserId(String value) {
    // log("accessToken : $value");
    return _sharedPreferences!.setString('uid', value);
  }

  static String? getUserId() {
    try {
      // log("accessToken : ${_sharedPreferences!.getString('accessToken')!}");
      return _sharedPreferences?.getString('uid');
    } catch (e) {
      log('error : $e');
     return null;
    }
  }

  static Future<void> setLocalProfilePath(String value) {
    return _sharedPreferences!.setString('profileImg', value);
  }

  static String? getLocalProfilePath() {
    try {
      return _sharedPreferences?.getString('profileImg');
    } catch (e) {
      log('error : $e');
     return null;
    }
  }

  // Future<void> setLocalIdentityPath(String value) {
  //   return _sharedPreferences!.setString('profileImg', value);
  // }
  //
  // String? getLocalProfilePath() {
  //   try {
  //     return _sharedPreferences?.getString('profileImg');
  //   } catch (e) {
  //     print('error : $e');
  //    return null;
  //   }
  // }
  // Future<void> setResumePath(String value) {
  //   return _sharedPreferences!.setString('profileImg', value);
  // }
  //
  // String? getResumePath() {
  //   try {
  //     return _sharedPreferences?.getString('profileImg');
  //   } catch (e) {
  //     print('error : $e');
  //    return null;
  //   }
  // }
  // Future<void> setLocalProfilePath(String value) {
  //   return _sharedPreferences!.setString('profileImg', value);
  // }
  //
  // String? getLocalProfilePath() {
  //   try {
  //     return _sharedPreferences?.getString('profileImg');
  //   } catch (e) {
  //     print('error : $e');
  //    return null;
  //   }
  // }
  //



  static bool isUserAuthenticated() {
    return _sharedPreferences?.getString('uid') != null && _sharedPreferences?.getString('uid') != '';
    // return false;
  }
}
