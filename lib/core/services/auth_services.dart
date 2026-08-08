import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService._();

  static const _loginKey = 'is_logged_in';

  // Hardcoded answer
  static const String secretAnswer = 'k-adilnoor';

  static Future<bool> login(String answer) async {
    if (answer.trim().toLowerCase() ==
        secretAnswer.toLowerCase()) {
      final prefs =
      await SharedPreferences.getInstance();

      await prefs.setBool(_loginKey, true);

      return true;
    }

    return false;
  }

  static Future<bool> isLoggedIn() async {
    final prefs =
    await SharedPreferences.getInstance();

    return prefs.getBool(_loginKey) ?? false;
  }

  static Future<void> logout() async {
    final prefs =
    await SharedPreferences.getInstance();

    await prefs.remove(_loginKey);
  }
}