import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:poker_http/poker_http.dart';

void main() {
  test(
    'same operation selects two exact services; body/auth stay separate',
    () async {
      for (final service in [ServiceId.auth, ServiceId.accounts]) {
        final adapter = GatewayHttp(
          'https://gateway.invalid',
          service,
          client: MockClient((request) async {
            expect(request.url.path, '/technicalProbe');
            expect(request.headers[serviceIdHeader], service.wire);
            expect(request.headers['Authorization'], isNull);
            expect(jsonDecode(request.body), {
              'payload': {'synthetic': true},
            });
            return http.Response('{"ok":true,"result":7}', 200);
          }),
        );
        addTearDown(adapter.close);
        expect(
          await adapter.call('technicalProbe', {'synthetic': true}, (v) => v),
          7,
        );
      }
    },
  );
  test(
    'bearer boundary preserves 403 without echoing body in exception',
    () async {
      final adapter = GatewayHttp(
        'https://gateway.invalid',
        ServiceId.accounts,
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer synthetic-only');
          return http.Response(
            '{"ok":false,"result":null,"error":"FIXTURE_FORBIDDEN"}',
            403,
          );
        }),
      );
      addTearDown(adapter.close);
      await expectLater(
        adapter.call(
          'technicalProbe',
          null,
          (v) => v,
          authentication: BearerAuthentication('synthetic-only'),
        ),
        throwsA(
          isA<GatewayException>()
              .having((e) => e.status, 'status', 403)
              .having((e) => e.code, 'code', 'FIXTURE_FORBIDDEN'),
        ),
      );
      expect(
        () => GatewayHttp(
          'https://gateway.invalid/api/authService',
          ServiceId.auth,
        ),
        throwsFormatException,
      );
    },
  );
  test(
    'real loopback request supports native cancellation and closes resources',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final seen = Completer<void>();
      final subscription = server.listen((request) {
        seen.complete();
      });
      final adapter = GatewayHttp(
        'http://127.0.0.1:${server.port}',
        ServiceId.auth,
      );
      final cancel = Completer<void>();
      try {
        final pending = adapter.call(
          'technicalProbe',
          null,
          (v) => v,
          abortTrigger: cancel.future,
        );
        final assertion = expectLater(
          pending,
          throwsA(isA<http.RequestAbortedException>()),
        );
        await seen.future;
        cancel.complete();
        await assertion;
      } finally {
        adapter.close();
        await subscription.cancel();
        await server.close(force: true);
      }
    },
  );
}
