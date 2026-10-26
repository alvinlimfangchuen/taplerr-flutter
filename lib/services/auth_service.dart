import 'package:dio/dio.dart';
import 'api_client.dart';

/// Thrown when the backend rejects credentials/input. The PHP backend
/// doesn't return a JSON error body (see flutter-documentation.md §2.1),
/// so [message] is a client-side best guess, not server-reported text.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

/// Talks to the Taplerr PHP backend the same way a browser does: a
/// session cookie, not a bearer token. See
/// `porting documentation/flutter/flutter-documentation.md` §2 for the
/// contract this class implements.
class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  final ApiClient _client = ApiClient.instance;

  /// POST /login — success is "redirected away from /login with a fresh
  /// session cookie", not a parseable JSON body.
  Future<void> login({required String email, required String password}) async {
    bool loggedIn;
    try {
      loggedIn = await _client.postExpectRedirectAwayFrom(
        '/login',
        {'email': email, 'password': password},
        awayFrom: '/login',
      );
    } on DioException {
      throw AuthException('Could not reach the server. Check your connection and try again.');
    }
    if (!loggedIn) throw AuthException('Invalid email or password.');
  }

  /// POST /register — password policy (8-64 chars, upper+lower+digit) is
  /// enforced server-side too, but we validate client-side first so
  /// failures here are rare (see §2.4: failure gives no JSON reason).
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    bool created;
    try {
      created = await _client.postExpectRedirectAwayFrom(
        '/register',
        {
          'name': name,
          'email': email,
          'password': password,
          'confirm_password': confirmPassword,
        },
        awayFrom: '/register',
      );
    } on DioException {
      throw AuthException('Could not reach the server. Check your connection and try again.');
    }
    if (!created) {
      throw AuthException('Could not create your account. Please check your details and try again.');
    }
  }

  /// POST /forgot-password — the backend always behaves the same
  /// regardless of whether the email exists (no account enumeration),
  /// so this is fire-and-forget per §2.5.
  Future<void> forgotPassword({required String email}) async {
    try {
      await _client.post('/forgot-password', data: {'email': email});
    } on DioException {
      throw AuthException('Could not reach the server. Check your connection and try again.');
    }
  }

  /// GET /logout destroys the session server-side; clear the local jar too.
  Future<void> logout() async {
    try {
      await _client.get('/logout');
    } on DioException {
      // Best-effort — still clear local cookies below.
    } finally {
      await _client.clearSession();
    }
  }
}
