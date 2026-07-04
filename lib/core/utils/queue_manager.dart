import 'dart:async';

import 'package:flutter/foundation.dart';

class _QueueEntry {
  _QueueEntry(this.task, {this.key});

  Future<void> Function() task;
  final String? key;
  final Completer<void> completer = Completer<void>();
}

/// Runs async tasks strictly one at a time, in FIFO order.
///
/// Tasks enqueued with [addCoalesced] and the same key are latest-wins:
/// if a task with that key is still waiting to run, its work is replaced
/// by the newer task and both callers' futures complete together.
class QueueManager {
  static final QueueManager _instance = QueueManager._internal();
  factory QueueManager() => _instance;
  QueueManager._internal();

  final _queue = <_QueueEntry>[];
  final _pendingByKey = <String, _QueueEntry>{};
  bool _isRunning = false;

  Future<void> add(Future<void> Function() task) {
    return _enqueue(_QueueEntry(task));
  }

  Future<void> addCoalesced(String key, Future<void> Function() task) {
    final pending = _pendingByKey[key];
    if (pending != null) {
      pending.task = task;
      return pending.completer.future;
    }
    final entry = _QueueEntry(task, key: key);
    _pendingByKey[key] = entry;
    return _enqueue(entry);
  }

  Future<void> _enqueue(_QueueEntry entry) {
    _queue.add(entry);
    if (!_isRunning) {
      _isRunning = true;
      _run();
    }
    return entry.completer.future;
  }

  Future<void> _run() async {
    while (_queue.isNotEmpty) {
      final entry = _queue.removeAt(0);
      // Once a task starts it can no longer be coalesced away.
      if (entry.key != null) {
        _pendingByKey.remove(entry.key);
      }
      try {
        await entry.task();
        entry.completer.complete();
      } catch (e, st) {
        debugPrint('QueueManager task failed: $e\n$st');
        // Complete normally: callers rarely await these futures, and an
        // unawaited error future would surface as an unhandled zone error.
        entry.completer.complete();
      }
    }
    _isRunning = false;
  }
}
