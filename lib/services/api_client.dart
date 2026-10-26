import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Single shared Dio + cookie jar for the whole app. Every feature service
/// (auth, profile, cards, contacts, ...) talks to the same session-cookie
/// backend described in `porting documentation/flutter/flutter-documentation.md`,
/// so they all share one client to keep the PHPSESSID cookie consistent.
class ApiClient {
  ApiClient._internal();
  static final ApiClient instance = ApiClient._internal();

  static const String baseUrl = 'https://demo.taplerr.com';

  Dio? _dio;
  CookieJar? _cookieJar;

  Future<Dio> get dio async {
    if (_dio != null) return _dio!;

    _cookieJar = kIsWeb
        ? CookieJar()
        : PersistCookieJar(
            storage: FileStorage(
              '${(await getApplicationDocumentsDirectory()).path}/.cookies/',
            ),
          );

    final client = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        followRedirects: false,
        validateStatus: (code) => code != null && code < 500,
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
    client.interceptors.add(CookieManager(_cookieJar!));
    _dio = client;
    return client;
  }

  Future<void> clearSession() async {
    await _cookieJar?.deleteAll();
  }

  /// GETs [page] and scrapes the hidden `csrf_token` field out of the
  /// server-rendered HTML — there's no JSON endpoint for this (see doc §2.3).
  Future<String?> fetchCsrfToken(String page) async {
    final client = await dio;
    final res = await client.get(
      page,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    final html = res.data is String ? res.data as String : '';
    final match = RegExp(
      r'''name=["']csrf_token["']\s+value=["']([^"']+)["']''',
    ).firstMatch(html);
    return match?.group(1);
  }

  /// POSTs [path] with [data] and returns true if the response redirected
  /// away from [awayFrom] — the standard "success" signal for endpoints that
  /// don't return JSON (login/register/most account mutations).
  Future<bool> postExpectRedirectAwayFrom(
    String path,
    Map<String, dynamic> data, {
    required String awayFrom,
  }) async {
    final client = await dio;
    final res = await client.post(path, data: data);
    final location = res.headers.value('location') ?? '';
    return res.statusCode == 302 && !location.contains(awayFrom);
  }

  /// POSTs [path] and returns the raw `Response` for callers that need to
  /// inspect the redirect `Location` / query params themselves (bind-card,
  /// relink/unlink, contacts approve/reject, etc. all signal outcome via
  /// `?status=success|error` on the redirect target rather than a body).
  Future<Response> post(String path, {Map<String, dynamic>? data}) async {
    final client = await dio;
    return client.post(path, data: data);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final client = await dio;
    return client.get(path, queryParameters: queryParameters);
  }

  /// For authenticated binary downloads (contacts export CSV, contacts
  /// vCard) that must carry the session cookie — unlike the public
  /// qr/vcard-download endpoints, these can't just be opened in an external
  /// browser (no cookie there), so fetch the bytes through this client.
  Future<List<int>> getBytes(String path, {Map<String, dynamic>? queryParameters}) async {
    final client = await dio;
    final res = await client.get<List<int>>(
      path,
      queryParameters: queryParameters,
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? const [];
  }
}
