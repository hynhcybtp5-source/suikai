import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:suikai/core/supabase_endpoint_bootstrap.dart';

final _direct = Uri.parse('https://ppyqkkwfnlyvyzxmhtvz.supabase.co');
final _fallback = Uri.parse('https://api.suikai.shop');

const _response = SupabaseEndpointProbeResponse(statusCode: 401);

void main() {
  SupabaseEndpointSelector selector(SupabaseEndpointProbe probe) =>
      SupabaseEndpointSelector(
        probe: probe,
        timeout: const Duration(seconds: 1),
      );

  Future<SupabaseEndpointProbeResponse> after(
    Duration delay, {
    bool fail = false,
  }) async {
    await Future<void>.delayed(delay);
    if (fail) throw const SupabaseEndpointNetworkException();
    return _response;
  }

  test('uses a seven second maximum timeout per probe', () {
    expect(
      SupabaseEndpointSelector(probe: (_) async => _response).timeout,
      const Duration(seconds: 7),
    );
  });

  test('direct at 500ms beats proxy at 1000ms', () async {
    final selection = await selector(
      (endpoint) => after(
        endpoint == _direct
            ? const Duration(milliseconds: 500)
            : const Duration(milliseconds: 1000),
      ),
    ).select(direct: _direct, fallback: _fallback);

    expect(selection.kind, SupabaseEndpointKind.direct);
  });

  test('proxy at 800ms beats direct at 5000ms', () async {
    final selection = await selector(
      (endpoint) => after(
        endpoint == _direct
            ? const Duration(milliseconds: 5000)
            : const Duration(milliseconds: 800),
      ),
    ).select(direct: _direct, fallback: _fallback);

    expect(selection.kind, SupabaseEndpointKind.fallback);
  });

  test('direct failure waits for and selects a successful proxy', () async {
    final selection = await selector(
      (endpoint) => after(
        endpoint == _direct
            ? const Duration(milliseconds: 2)
            : const Duration(milliseconds: 8),
        fail: endpoint == _direct,
      ),
    ).select(direct: _direct, fallback: _fallback);

    expect(selection.kind, SupabaseEndpointKind.fallback);
  });

  test('proxy failure waits for and selects a successful direct', () async {
    final selection = await selector(
      (endpoint) => after(
        endpoint == _fallback
            ? const Duration(milliseconds: 2)
            : const Duration(milliseconds: 8),
        fail: endpoint == _fallback,
      ),
    ).select(direct: _direct, fallback: _fallback);

    expect(selection.kind, SupabaseEndpointKind.direct);
  });

  test('any HTTP status, including 5xx, wins the race', () async {
    final selection = await selector(
      (endpoint) async => SupabaseEndpointProbeResponse(
        statusCode: endpoint == _direct ? 500 : 200,
      ),
    ).select(direct: _direct, fallback: _fallback);

    expect(selection.kind, SupabaseEndpointKind.direct);
  });

  test('both network failures continue to Network Blocked flow', () async {
    expect(
      () => selector(
        (_) async => throw const SupabaseEndpointNetworkException(),
      ).select(direct: _direct, fallback: _fallback),
      throwsA(isA<SupabaseEndpointsUnavailableException>()),
    );
  });

  test('a late loser response cannot change the selected endpoint', () async {
    final lateDirect = Completer<SupabaseEndpointProbeResponse>();
    final bootstrap = SupabaseEndpointBootstrap(
      direct: _direct,
      fallback: _fallback,
      selector: selector(
        (endpoint) =>
            endpoint == _direct ? lateDirect.future : Future.value(_response),
      ),
    );

    await bootstrap.initialize((_) async {});
    expect(bootstrap.selection.kind, SupabaseEndpointKind.fallback);
    lateDirect.complete(_response);
    await Future<void>.delayed(Duration.zero);

    expect(bootstrap.selection.kind, SupabaseEndpointKind.fallback);
  });

  test('initializes the SDK once with the race winner', () async {
    var initialized = 0;
    final bootstrap = SupabaseEndpointBootstrap(
      direct: _direct,
      fallback: _fallback,
      selector: selector(
        (endpoint) async => endpoint == _direct
            ? _response
            : await after(const Duration(milliseconds: 10)),
      ),
    );

    Future<void> initialize(SupabaseEndpointSelection selection) async {
      initialized++;
      expect(selection.kind, SupabaseEndpointKind.direct);
    }

    await Future.wait([
      bootstrap.initialize(initialize),
      bootstrap.initialize(initialize),
    ]);
    await bootstrap.initialize(initialize);

    expect(initialized, 1);
  });
}
