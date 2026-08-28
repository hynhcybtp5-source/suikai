import 'dart:async';

import 'package:http/http.dart' as http;

/// Marks failures where an endpoint could not be contacted at the network
/// layer. HTTP responses are deliberately not represented by this exception:
/// even 401, 403, and 404 prove that the endpoint is reachable.
class SupabaseEndpointNetworkException implements Exception {
  const SupabaseEndpointNetworkException([this.cause]);

  final Object? cause;
}

class SupabaseEndpointsUnavailableException implements Exception {
  const SupabaseEndpointsUnavailableException();

  @override
  String toString() => 'supabase_endpoints_unavailable';
}

enum SupabaseEndpointKind { direct, fallback }

class SupabaseEndpointSelection {
  const SupabaseEndpointSelection(this.endpoint, this.kind);

  final Uri endpoint;
  final SupabaseEndpointKind kind;

  bool get isFallback => kind == SupabaseEndpointKind.fallback;
}

class SupabaseEndpointProbeResponse {
  const SupabaseEndpointProbeResponse({
    required this.statusCode,
    this.projectRef,
  });

  final int statusCode;
  final String? projectRef;
}

class SupabaseEndpointProbeResult {
  const SupabaseEndpointProbeResult({
    required this.kind,
    required this.elapsed,
    required this.reachable,
  });

  final SupabaseEndpointKind kind;
  final Duration elapsed;
  final bool reachable;
}

typedef SupabaseEndpointProbe =
    Future<SupabaseEndpointProbeResponse> Function(Uri endpoint);
typedef SupabaseEndpointProbeObserver =
    void Function(SupabaseEndpointProbeResult result);
typedef SupabaseEndpointInitializer =
    Future<void> Function(SupabaseEndpointSelection selection);

/// Selects one endpoint before the SDK is initialized. The selection is then
/// retained by [SupabaseEndpointBootstrap] for the lifetime of the process.
class SupabaseEndpointSelector {
  const SupabaseEndpointSelector({
    required this.probe,
    this.timeout = const Duration(seconds: 7),
    this.onProbeCompleted,
  });

  final SupabaseEndpointProbe probe;
  final Duration timeout;
  final SupabaseEndpointProbeObserver? onProbeCompleted;

  Future<SupabaseEndpointSelection> select({
    required Uri direct,
    required Uri fallback,
  }) async {
    // Start both requests before awaiting either one. The first HTTP response
    // wins; a network failure only removes that contender from the race.
    final directProbe = _probe(direct, SupabaseEndpointKind.direct);
    final fallbackProbe = _probe(fallback, SupabaseEndpointKind.fallback);
    final first = await Future.any([directProbe, fallbackProbe]);
    if (first.reachable) {
      return _selectionFor(first, direct, fallback);
    }
    final remaining = first.kind == SupabaseEndpointKind.direct
        ? fallbackProbe
        : directProbe;
    final second = await remaining;
    if (second.reachable) {
      return _selectionFor(second, direct, fallback);
    }
    throw const SupabaseEndpointsUnavailableException();
  }

  SupabaseEndpointSelection _selectionFor(
    SupabaseEndpointProbeResult result,
    Uri direct,
    Uri fallback,
  ) => SupabaseEndpointSelection(
    result.kind == SupabaseEndpointKind.direct ? direct : fallback,
    result.kind,
  );

  Future<SupabaseEndpointProbeResult> _probe(
    Uri endpoint,
    SupabaseEndpointKind kind,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      await probe(endpoint).timeout(timeout);
      // Any HTTP status is reachability. In particular, an unauthenticated
      // probe can legitimately receive 401/403/404 from a live Supabase host.
      return _result(kind, stopwatch.elapsed, true);
    } on TimeoutException {
      return _result(kind, stopwatch.elapsed, false);
    } on SupabaseEndpointNetworkException {
      return _result(kind, stopwatch.elapsed, false);
    }
  }

  SupabaseEndpointProbeResult _result(
    SupabaseEndpointKind kind,
    Duration elapsed,
    bool reachable,
  ) {
    final result = SupabaseEndpointProbeResult(
      kind: kind,
      elapsed: elapsed,
      reachable: reachable,
    );
    onProbeCompleted?.call(result);
    return result;
  }
}

/// A lightweight, read-only probe that does not require a user session or a
/// privileged key. Completing an HTTP request is enough to establish reachability.
Future<SupabaseEndpointProbeResponse> probeSupabaseEndpoint(
  Uri endpoint,
) async {
  final probeUri = endpoint.resolve('/rest/v1/');
  try {
    final response = await http.get(probeUri);
    final projectRef = response.headers['sb-project-ref'];
    if (projectRef != null &&
        projectRef.isNotEmpty &&
        projectRef != 'ppyqkkwfnlyvyzxmhtvz') {
      throw const SupabaseEndpointNetworkException();
    }
    return SupabaseEndpointProbeResponse(
      statusCode: response.statusCode,
      projectRef: projectRef,
    );
  } on http.ClientException catch (error) {
    throw SupabaseEndpointNetworkException(error);
  }
}

/// Coordinates selection and SDK initialization so the SDK is initialized at
/// most once. Failed startup attempts remain retryable until initialization
/// has completed successfully.
class SupabaseEndpointBootstrap {
  SupabaseEndpointBootstrap({
    required this.direct,
    required this.fallback,
    required this.selector,
  });

  final Uri direct;
  final Uri fallback;
  final SupabaseEndpointSelector selector;
  SupabaseEndpointSelection? _selection;
  Future<void>? _initialization;

  SupabaseEndpointSelection get selection {
    final value = _selection;
    if (value == null) throw StateError('supabase_endpoint_not_selected');
    return value;
  }

  Future<void> initialize(SupabaseEndpointInitializer initializer) {
    return _initialization ??= _initialize(initializer);
  }

  Future<void> _initialize(SupabaseEndpointInitializer initializer) async {
    try {
      final selection = _selection ??= await selector.select(
        direct: direct,
        fallback: fallback,
      );
      await initializer(selection);
    } catch (_) {
      // Do not cache a failed attempt: Network Blocked's retry action must be
      // able to probe again. A successful selection is still never switched.
      _initialization = null;
      rethrow;
    }
  }
}
