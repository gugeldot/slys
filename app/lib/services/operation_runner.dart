import 'package:flutter/material.dart';

import '../src/rust/api/operations.dart';

/// Human text for each stage of an operation.
String stageLabel(Stage s) {
  switch (s) {
    case Stage.deriving:
      return 'Deriving the key (this is slow on purpose)…';
    case Stage.encrypting:
      return 'Fragmenting and encrypting…';
    case Stage.verifying:
      return 'Checking that the file can be rebuilt…';
    case Stage.rebuilding:
      return 'Rebuilding the file…';
    case Stage.cleaning:
      return 'Cleaning up…';
  }
}

/// Shows a progress dialog while the Rust core works, and returns its final event
/// (`fragmented`, `recomposed` or `failed`). The UI thread never blocks: the work runs in Rust
/// on a worker thread and reports through a stream.
Future<OperationEvent?> runOperation(
  BuildContext context,
  Stream<OperationEvent> events, {
  required String title,
}) async {
  final progress = ValueNotifier<OperationEvent_Progress?>(null);
  var dialogOpen = true;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 360,
          child: ValueListenableBuilder<OperationEvent_Progress?>(
            valueListenable: progress,
            builder: (_, p, __) {
              final total = p?.total ?? BigInt.zero;
              final value = (p == null || total == BigInt.zero)
                  ? null
                  : p.done.toDouble() / total.toDouble();
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p == null ? 'Starting…' : stageLabel(p.stage),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: value),
                ],
              );
            },
          ),
        ),
      ),
    ),
  ).whenComplete(() => dialogOpen = false);

  OperationEvent? last;
  try {
    await for (final e in events) {
      if (e is OperationEvent_Progress) {
        progress.value = e;
      } else {
        last = e;
      }
    }
  } finally {
    if (dialogOpen && context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    progress.dispose();
  }
  return last;
}

/// One simple dialog for messages.
Future<void> showMessage(BuildContext context, String title, String message) {
  if (!context.mounted) return Future.value();
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.grey[850],
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: SelectableText(message, style: const TextStyle(color: Colors.white70)),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
      ],
    ),
  );
}
