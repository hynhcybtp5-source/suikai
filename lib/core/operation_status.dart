import 'package:flutter/material.dart';

/// Shared vocabulary for async work. Screens can keep their own layout while
/// presenting consistent, meaningful feedback instead of a bare spinner.
enum OperationStatus { idle, loading, submitting, success, failed }

class LoadingStatusView extends StatelessWidget {
  final String message;
  final double? progress;
  final bool compact;

  const LoadingStatusView({
    super.key,
    required this.message,
    this.progress,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: message,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: compact ? 22 : 38,
          height: compact ? 22 : 38,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: compact ? 2.5 : 3,
          ),
        ),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}
