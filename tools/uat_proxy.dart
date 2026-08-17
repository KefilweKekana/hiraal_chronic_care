/// Local debug server for web builds: serves the compiled Flutter web app AND
/// proxies /api/* to https://uat.dagaartech.com — a single origin, so no CORS
/// or private-network issues can bite. Logs every API call + error bodies.
///
/// Usage:
///   flutter build web --release --dart-define=USE_MOCK=false \
///     --dart-define=BASE_URL=http://localhost:8090
///   dart tools/uat_proxy.dart            then open http://localhost:8090
import 'dart:convert';
import 'dart:io';

const String targetHost = 'uat.dagaartech.com';
const int port = 8090;
const String webRoot = 'build/web';

final HttpClient _client = HttpClient()
  ..connectionTimeout = const Duration(seconds: 30);

Future<void> main() async {
  // anyIPv6 + v6Only:false accepts both ::1 and 127.0.0.1 (Chrome resolves
  // localhost to ::1 first on this machine).
  final server = await HttpServer.bind(InternetAddress.anyIPv6, port);
  print('Serving $webRoot + /api→$targetHost on http://localhost:$port');
  await for (final request in server) {
    if (request.uri.path.startsWith('/api/')) {
      _proxy(request);
    } else {
      _serveStatic(request);
    }
  }
}

// ── Static web build ────────────────────────────────────────────────────────

const _types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript',
  '.mjs': 'application/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.txt': 'text/plain',
  '.wasm': 'application/wasm',
};

Future<void> _serveStatic(HttpRequest req) async {
  if (req.method != 'GET' && req.method != 'HEAD') {
    req.response.statusCode = 405;
    await req.response.close();
    return;
  }
  var path = Uri.decodeComponent(req.uri.path);
  if (path == '/' || path.isEmpty) path = '/index.html';
  // Prevent path escapes, fall back to index.html for client-side routes.
  final file = File('$webRoot$path');
  final resolved = (await file.exists()) && !path.contains('..')
      ? file
      : File('$webRoot/index.html');

  final ext = path.contains('.') ? '.${path.split('.').last}' : '';
  req.response.headers.contentType =
      ContentType.parse(_types[ext.toLowerCase()] ?? 'application/octet-stream');
  try {
    await resolved.openRead().pipe(req.response);
  } catch (_) {
    req.response.statusCode = 404;
    await req.response.close();
  }
}

// ── API proxy ───────────────────────────────────────────────────────────────

Future<void> _proxy(HttpRequest req) async {
  final sw = Stopwatch()..start();
  try {
    final uri = Uri.https(targetHost, req.uri.path,
        req.uri.queryParameters.isEmpty ? null : req.uri.queryParameters);
    final upstream = await _client.openUrl(req.method, uri);
    req.headers.forEach((name, values) {
      final n = name.toLowerCase();
      if (n == 'host' ||
          n == 'origin' ||
          n == 'referer' ||
          n == 'accept-encoding' ||
          n == 'content-length') {
        return;
      }
      for (final v in values) {
        upstream.headers.set(name, v);
      }
    });
    upstream.headers.set('host', targetHost);
    final reqBody = await utf8.decodeStream(req);
    if (reqBody.isNotEmpty) upstream.write(reqBody);
    final resp = await upstream.close();
    final respBody = await utf8.decodeStream(resp);

    req.response.statusCode = resp.statusCode;
    req.response.headers.contentType =
        resp.headers.contentType ?? ContentType.json;
    req.response.write(respBody);
    await req.response.close();

    print('${req.method} ${req.uri.path} → ${resp.statusCode} '
        '(${sw.elapsedMilliseconds}ms)');
    if (req.method == 'POST' && reqBody.isNotEmpty) {
      print('   REQ: ${_truncate(reqBody, 300)}');
    }
    if (resp.statusCode >= 400) {
      print('   ERR: ${_truncate(respBody, 500)}');
    }
  } catch (e) {
    print('${req.method} ${req.uri.path} → PROXY-ERROR $e');
    req.response.statusCode = 502;
    req.response.write(jsonEncode({'error': e.toString()}));
    await req.response.close();
  }
}

String _truncate(String s, int n) => s.length > n ? '${s.substring(0, n)}…' : s;
