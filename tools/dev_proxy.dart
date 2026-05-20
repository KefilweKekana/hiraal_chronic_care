/// Simple development proxy for Flutter web → ERPNext.
///
/// Solves the cross-origin cookie issue: browsers can't send HttpOnly
/// cookies via JavaScript, but Frappe v13 requires the `sid` cookie
/// for POST requests. This proxy adds it server-side.
///
/// Usage:
///   dart run tools/dev_proxy.dart <SID>
///
/// Then run Flutter with:
///   flutter run -d chrome --dart-define=BASE_URL=http://localhost:8089
///     --dart-define=USE_MOCK=false

import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tools/dev_proxy.dart <SID>');
    exit(1);
  }

  final sid = args[0];
  const targetHost = 'alfuraat.com';
  const targetScheme = 'https';
  const port = 8089;

  final server = await HttpServer.bind('127.0.0.1', port);
  print('Dev proxy listening on http://127.0.0.1:$port');
  print('Forwarding to $targetScheme://$targetHost with sid auth');
  print('Press Ctrl+C to stop\n');

  await for (final request in server) {
    _handleRequest(request, sid, targetHost, targetScheme);
  }
}

Future<void> _handleRequest(
  HttpRequest request,
  String sid,
  String targetHost,
  String targetScheme,
) async {
  // CORS – echo the request origin so credentialed requests work
  final origin = request.headers.value('origin') ?? '*';
  request.response.headers
    ..add('Access-Control-Allow-Origin', origin)
    ..add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
    ..add('Access-Control-Allow-Headers',
        request.headers.value('access-control-request-headers') ??
            'Content-Type, Accept, Authorization, Cookie')
    ..add('Access-Control-Allow-Credentials', 'true')
    ..add('Access-Control-Max-Age', '86400');

  if (request.method == 'OPTIONS') {
    request.response.statusCode = 204;
    await request.response.close();
    return;
  }

  try {
    final client = HttpClient();
    final targetUri = Uri(
      scheme: targetScheme,
      host: targetHost,
      path: request.uri.path,
      query: request.uri.query.isNotEmpty ? request.uri.query : null,
    );

    final proxyReq = await client.openUrl(request.method, targetUri);

    // Forward relevant headers
    request.headers.forEach((name, values) {
      final lower = name.toLowerCase();
      if (lower == 'host' ||
          lower == 'cookie' ||
          lower == 'origin' ||
          lower == 'accept-encoding') return;
      for (final v in values) {
        proxyReq.headers.add(name, v);
      }
    });

    // Inject session cookie — request identity (no gzip from upstream)
    proxyReq.headers.set('Cookie', 'sid=$sid');
    proxyReq.headers.set('Host', targetHost);
    proxyReq.headers.set('Accept-Encoding', 'identity');

    // Forward body
    final body = await utf8.decodeStream(request);
    if (body.isNotEmpty) {
      proxyReq.write(body);
    }

    final proxyResp = await proxyReq.close();

    // Copy status + headers back
    request.response.statusCode = proxyResp.statusCode;
    proxyResp.headers.forEach((name, values) {
      final lower = name.toLowerCase();
      if (lower == 'transfer-encoding' ||
          lower == 'access-control-allow-origin') return;
      for (final v in values) {
        request.response.headers.add(name, v);
      }
    });

    // Stream body back
    await proxyResp.pipe(request.response);

    final status = proxyResp.statusCode;
    final emoji = status < 300 ? '✓' : '✗';
    print('$emoji ${request.method} ${request.uri.path} → $status');
  } catch (e) {
    print('✗ ${request.method} ${request.uri.path} → ERROR: $e');
    request.response.statusCode = 502;
    request.response.write(json.encode({'error': e.toString()}));
    await request.response.close();
  }
}
