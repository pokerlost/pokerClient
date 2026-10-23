/// Explicit gateway HTTP adapter; independent from gameplay/realtime presentation.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:poker_http/src/environment.dart';
import 'package:poker_http/src/service_id.dart';

export 'package:poker_http/src/environment.dart';
export 'package:poker_http/src/service_id.dart';

sealed class Authentication {
  const Authentication();
}

final class PublicAuthentication extends Authentication {
  const PublicAuthentication();
}

final class BearerAuthentication extends Authentication {
  BearerAuthentication(this.token, {this.environment, this.origin}) {
    if (!RegExp(r'^[\x21-\x7e]+$').hasMatch(token)) {
      throw ArgumentError('Invalid authentication configuration');
    }
  }
  final String token;
  final Environment? environment;
  final String? origin;
}

final class GatewayException implements Exception {
  const GatewayException(this.status, this.code);
  final int status;
  final String code;
  @override
  String toString() => 'Gateway request failed ($status)';
}

Uri _gatewayOrigin(String value, Environment? environment) {
  Uri origin;
  try {
    origin = Uri.parse(value);
  } on FormatException {
    throw const FormatException('Invalid gateway configuration');
  }
  final loopback = ['localhost', '127.0.0.1', '::1'].contains(origin.host);
  if ((origin.scheme == 'http' && !loopback) ||
      (environment != null &&
          environment != Environment.local &&
          origin.scheme != 'https') ||
      (environment == Environment.local && !loopback) ||
      RegExp(r'[\s\\]').hasMatch(value) ||
      !['https', 'http'].contains(origin.scheme) ||
      origin.host.isEmpty ||
      origin.userInfo.isNotEmpty ||
      !['', '/'].contains(origin.path) ||
      origin.hasQuery ||
      origin.hasFragment) {
    throw const FormatException('Invalid gateway configuration');
  }
  return origin;
}

/// Own and close this adapter with its controller/composition lifecycle.
/// It implements no business operations, retries, credential store or WebSocket.
Duration _validTimeout(Duration value) {
  if (value <= Duration.zero) throw ArgumentError('Timeout must be positive');
  return value;
}

final class GatewayHttp {
  GatewayHttp(
    String origin,
    this.serviceId, {
    http.Client? client,
    this.environment,
    Duration timeout = const Duration(seconds: 10),
  }) : origin = _gatewayOrigin(origin, environment),
       timeout = _validTimeout(timeout),
       _client = client ?? http.Client();

  GatewayHttp.forEnvironment(
    EnvironmentConfig config,
    ServiceId serviceId, {
    http.Client? client,
    Duration timeout = const Duration(seconds: 10),
  }) : this(
         config.resolveOrigin(),
         serviceId,
         client: client,
         timeout: timeout,
         environment: config.environment,
       );

  final Environment? environment;
  final Uri origin;
  final ServiceId serviceId;
  final Duration timeout;
  final http.Client _client;

  Future<T> call<T>(
    String operation,
    Object? payload,
    T Function(Object?) decode, {
    Authentication authentication = const PublicAuthentication(),
    Future<void>? abortTrigger,
  }) async {
    if (!RegExp(r'^[a-z][A-Za-z0-9]*$').hasMatch(operation)) {
      throw ArgumentError('Invalid operation');
    }
    String body;
    try {
      body = jsonEncode({'payload': payload});
    } on JsonUnsupportedObjectError {
      throw const FormatException('Invalid JSON payload');
    }
    final abort = Completer<void>();
    void cancel() {
      if (!abort.isCompleted) abort.complete();
    }

    var timedOut = false;
    final timer = Timer(timeout, () {
      timedOut = true;
      cancel();
    });
    if (abortTrigger != null) {
      unawaited(
        abortTrigger.then<void>(
          (_) => cancel(),
          onError: (Object _, StackTrace _) => cancel(),
        ),
      );
    }
    final request =
        http.AbortableRequest(
            'POST',
            origin.resolve('/$operation'),
            abortTrigger: abort.future,
          )
          ..followRedirects = false
          ..headers['Content-Type'] = 'application/json'
          ..headers[serviceIdHeader] = serviceId.wire
          ..body = body;
    if (authentication case BearerAuthentication(:final token)) {
      if (environment != null &&
          (authentication.environment != environment ||
              authentication.origin != origin.origin)) {
        timer.cancel();
        throw ArgumentError(
          'Authentication target does not match client target',
        );
      }
      request.headers['Authorization'] = 'Bearer $token';
    }
    try {
      final response = await _client.send(request);
      final responseBody = await response.stream.bytesToString();
      Object? decoded;
      try {
        decoded = jsonDecode(responseBody);
      } on FormatException {
        throw GatewayException(response.statusCode, 'PROTOCOL_ERROR');
      }
      if (decoded is! Map<String, Object?> ||
          decoded['ok'] is! bool ||
          decoded.keys.any(
            (key) => !const {
              'ok',
              'result',
              'error',
              'error_message',
              'retry_after',
            }.contains(key),
          )) {
        throw GatewayException(response.statusCode, 'PROTOCOL_ERROR');
      }
      final error = decoded['error'];
      final message = decoded['error_message'];
      final retryAfter = decoded['retry_after'];
      if ((error != null && error is! String) ||
          (message != null && message is! String) ||
          (retryAfter != null &&
              (retryAfter is! num || !retryAfter.isFinite || retryAfter < 0))) {
        throw GatewayException(response.statusCode, 'PROTOCOL_ERROR');
      }
      if (decoded['ok'] == false) {
        if (decoded['result'] != null || error is! String || error.isEmpty) {
          throw GatewayException(response.statusCode, 'PROTOCOL_ERROR');
        }
        throw GatewayException(response.statusCode, error);
      }
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          error != null ||
          message != null ||
          retryAfter != null) {
        throw GatewayException(response.statusCode, 'PROTOCOL_ERROR');
      }
      return decode(decoded['result']);
    } on http.RequestAbortedException {
      if (timedOut) throw TimeoutException('Gateway request timed out');
      rethrow;
    } finally {
      timer.cancel();
    }
  }

  void close() => _client.close();
}
