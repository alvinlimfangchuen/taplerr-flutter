import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Thrown when an authenticated page redirects to /login — the session
/// cookie is missing or expired. Lets screens show a clear "please sign
/// in again" message instead of silently rendering blank scraped data.
class SessionExpiredException implements Exception {
  @override
  String toString() => 'Your session has expired. Please sign in again.';
}

/// Single shared Dio + cookie jar for the whole app. Every feature service
/// (auth, profile, cards, contacts, ...) talks to the same session-cookie
/// backend described in `porting documentation/flutter/flutter-documentation.md`,
/// so they all share one client to keep the PHPSESSID cookie consistent.
class ApiClient {
  ApiClient._internal();
  static final ApiClient instance = ApiClient._internal();

  static const String baseUrl = 'https://demo.taplerr.com';

  CookieJar? _cookieJar;
  // Cache the *future*, not just the resolved Dio — AppShell mounts five
  // screens at once via IndexedStack, each calling this getter from
  // initState() before any of them has awaited anything. Caching only the
  // resolved value let concurrent callers race past a `_dio == null` check
  // and each build their own Dio + PersistCookieJar, which could leave the
  // session cookie saved by login() invisible to the instance later calls
  // ended up using.
  Future<Dio>? _dioFuture;

  Future<Dio> get dio => _dioFuture ??= _initDio();

  Future<Dio> _initDio() async {
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
    return client;
  }

  Future<void> clearSession() async {
    await _cookieJar?.deleteAll();
  }

  /// GETs an authenticated, server-rendered page and returns its HTML body.
  /// Throws [SessionExpiredException] if the backend redirected to /login
  /// instead of serving the page, so a stale/missing session surfaces as a
  /// clear error rather than a page silently scraped as all-empty.
  Future<String> getAuthedHtml(String path, {Map<String, dynamic>? queryParameters}) async {
    final res = await get(path, queryParameters: queryParameters);
    final location = res.headers.value('location') ?? '';
    if (res.statusCode != null && res.statusCode! >= 300 && res.statusCode! < 400 && location.contains('/login')) {
      throw SessionExpiredException();
    }
    return res.data is String ? res.data as String : '';
  }

  /// GETs [page] and scrapes its CSRF token out of the server-rendered
  /// HTML — there's no JSON endpoint for this (see doc §2.3). Real forms
  /// (checkout, subscription) embed it as a hidden `<input>`; pages whose
  /// CSRF-guarded action is a JS `fetch()` call instead (notifications'
  /// mark-read/mark-all-read) embed it as `const CSRF_TOKEN = "...";` —
  /// try both shapes.
  Future<String?> fetchCsrfToken(String page) async {
    final client = await dio;
    final res = await client.get(
      page,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    final html = res.data is String ? res.data as String : '';
    final inputMatch = RegExp(
      r'''name=["']csrf_token["']\s+value=["']([^"']+)["']''',
    ).firstMatch(html);
    if (inputMatch != null) return inputMatch.group(1);
    final jsMatch = RegExp(
      r'''CSRF_TOKEN\s*=\s*["']([^"']+)["']''',
    ).firstMatch(html);
    return jsMatch?.group(1);
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
