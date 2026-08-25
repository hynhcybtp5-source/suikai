import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

enum SubmissionState { submitting, submitted, failed }

enum SubmissionStartResult { allowed, alreadySubmitting, alreadySubmitted }

class SubmissionRecord {
  final SubmissionState state;
  final DateTime updatedAt;
  final String? referenceId;

  const SubmissionRecord({
    required this.state,
    required this.updatedAt,
    this.referenceId,
  });

  Map<String, Object?> toJson() => {
    'state': state.name,
    'updatedAt': updatedAt.toIso8601String(),
    'referenceId': referenceId,
  };

  static SubmissionRecord? fromJson(String raw) {
    try {
      final value = jsonDecode(raw) as Map<String, dynamic>;
      final state = SubmissionState.values.byName(value['state'] as String);
      return SubmissionRecord(
        state: state,
        updatedAt: DateTime.parse(value['updatedAt'] as String),
        referenceId: value['referenceId'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Persists a per-form submission lock across navigation and app restarts.
/// A form receives a fresh session key when it is genuinely started again, so
/// two distinct products with identical names are never treated as duplicates.
class SubmissionGuard {
  static const _prefix = 'submission_guard.';
  static const _submittedTtl = Duration(hours: 24);
  static const _failedTtl = Duration(minutes: 15);
  static final Set<String> _inFlight = <String>{};

  static String newSessionKey({required String flow, String? scopeId}) =>
      '$flow:${scopeId ?? 'personal'}:${const Uuid().v4()}';

  static Future<SubmissionStartResult> begin(String key) async {
    if (_inFlight.contains(key)) return SubmissionStartResult.alreadySubmitting;
    // Reserve synchronously, before awaiting SharedPreferences. Without this,
    // two taps in the same event loop can both observe an unlocked cache.
    _inFlight.add(key);
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_prefix$key';
    final existing = SubmissionRecord.fromJson(prefs.getString(cacheKey) ?? '');
    final now = DateTime.now();
    if (existing != null) {
      final age = now.difference(existing.updatedAt);
      if (existing.state == SubmissionState.submitted && age < _submittedTtl) {
        _inFlight.remove(key);
        return SubmissionStartResult.alreadySubmitted;
      }
      if (existing.state == SubmissionState.submitting && age < _failedTtl) {
        _inFlight.remove(key);
        return SubmissionStartResult.alreadySubmitting;
      }
    }
    await prefs.setString(
      cacheKey,
      jsonEncode(
        SubmissionRecord(
          state: SubmissionState.submitting,
          updatedAt: now,
        ).toJson(),
      ),
    );
    return SubmissionStartResult.allowed;
  }

  static Future<void> succeed(String key, {String? referenceId}) async {
    _inFlight.remove(key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefix$key',
      jsonEncode(
        SubmissionRecord(
          state: SubmissionState.submitted,
          updatedAt: DateTime.now(),
          referenceId: referenceId,
        ).toJson(),
      ),
    );
  }

  static Future<void> fail(String key) async {
    _inFlight.remove(key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefix$key',
      jsonEncode(
        SubmissionRecord(
          state: SubmissionState.failed,
          updatedAt: DateTime.now(),
        ).toJson(),
      ),
    );
  }
}
