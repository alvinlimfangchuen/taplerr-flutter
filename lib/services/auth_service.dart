import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

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

  static const String baseUrl = 'https://demo.taplerr.com';

  Dio? _dio;
  CookieJar? _cookieJar;

  Future<Dio> _client() async {
    if (_dio != null) return _dio!;

    _cookieJar = kIsWeb
        ? CookieJar()
        : PersistCookieJar(
            storage: FileStorage(
              '${(await getApplicationDocumentsDirectory()).path}/.cookies/',
            ),
          );

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        followRedirects: false,
        validateStatus: (code) => code != null && code < 500,
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
    dio.interceptors.add(CookieManager(_cookieJar!));
    _dio = dio;
    return dio;
  }

  /// POST /login — success is "redirected away from /login with a fresh
  /// session cookie", not a parseable JSON body.
  Future<void> login({required String email, required String password}) async {
    final dio = await _client();
    final Response res;
    try {
      res = await dio.post('/login', data: {'email': email, 'password': password});
    } on DioException {
      throw AuthException('Could not reach the server. Check your connection and try again.');
    }

    final location = res.headers.value('location') ?? '';
    final loggedIn = res.statusCode == 302 && !location.contains('/login');
    if (!loggedIn) {
      throw AuthException('Invalid email or password.');
    }
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
    final dio = await _client();
    final Response res;
    try {
      res = await dio.post(
        '/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'confirm_password': confirmPassword,
        },
      );
    } on DioException {
      throw AuthException('Could not reach the server. Check your connection and try again.');
    }

    final location = res.headers.value('location') ?? '';
    final created = res.statusCode == 302 && location.contains('/login');
    if (!created) {
      throw AuthException('Could not create your account. Please check your details and try again.');
    }
  }

  /// POST /forgot-password — the backend always behaves the same
  /// regardless of whether the email exists (no account enumeration),
  /// so this is fire-and-forget per §2.5.
  Future<void> forgotPassword({required String email}) async {
    final dio = await _client();
    try {
      await dio.post('/forgot-password', data: {'email': email});
    } on DioException {
      throw AuthException('Could not reach the server. Check your connection and try again.');
    }
  }

  /// GET /logout destroys the session server-side; clear the local jar too.
  Future<void> logout() async {
    final dio = await _client();
    try {
      await dio.get('/logout');
    } on DioException {
      // Best-effort — still clear local cookies below.
    } finally {
      await _cookieJar?.deleteAll();
    }
  }
}
