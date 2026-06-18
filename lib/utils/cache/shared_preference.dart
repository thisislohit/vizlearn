import 'package:shared_preferences/shared_preferences.dart';

import 'local_storage.dart';

class SharedPreferenceStorage implements LocalStorage {
  final SharedPreferences _prefs;
  const SharedPreferenceStorage(this._prefs);

  @override
  Future<String> load({required String key, String? boxName}) async {
    final result = _prefs.getString(key);


    return result ?? "";
  }

  @override
  Future<void> save({
    required String key,
    required value,
    String? boxName,
  }) async {
    await _prefs.setString(key, value);
  }

  @override
  Future<void> delete({required String key, String? boxName}) async {
    await _prefs.remove(key);
  }

  @override
  Future<void> clearAll() async{
    await _prefs.clear();
  }
}
