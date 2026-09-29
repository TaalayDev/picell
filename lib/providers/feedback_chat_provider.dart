import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/models/feedback_chat_models.dart';
import '../data/repo/feedback_api_repo.dart';
import '../data/storage/local_storage.dart';
import 'providers.dart';

final feedbackAPIRepoProvider = Provider<FeedbackAPIRepo>((ref) => FeedbackAPIRepo(ref.read(apiClientProvider)));

/// Feedback conversations this device can open, oldest first. The token in
/// each is the only way back into a thread, so they are kept locally.
final feedbackThreadsProvider =
    NotifierProvider<FeedbackThreadsNotifier, List<FeedbackThreadRef>>(FeedbackThreadsNotifier.new);

class FeedbackThreadsNotifier extends Notifier<List<FeedbackThreadRef>> {
  static const _storageKey = 'feedback_threads_v1';

  @override
  List<FeedbackThreadRef> build() {
    try {
      final json = LocalStorage.instance.getString(_storageKey);
      if (json == null || json.isEmpty) return const [];
      return [
        for (final item in jsonDecode(json) as List)
          if (FeedbackThreadRef.tryParse(item) case final thread?) thread,
      ];
    } catch (e) {
      debugPrint('Failed to read feedback threads: $e');
      return const [];
    }
  }

  FeedbackThreadRef? get latest => state.isEmpty ? null : state.last;

  void add(FeedbackThreadRef thread) {
    state = [...state.where((existing) => existing.id != thread.id), thread];
    try {
      LocalStorage.instance.setString(_storageKey, jsonEncode([for (final item in state) item.toJson()]));
    } catch (e) {
      debugPrint('Failed to save feedback threads: $e');
    }
  }
}

@immutable
class FeedbackChatState {
  const FeedbackChatState({
    this.messages = const [],
    this.isLoading = true,
    this.isSending = false,
    this.isClosed = false,
    this.submittedAt,
    this.loadFailed = false,
  });

  final List<FeedbackChatMessage> messages;
  final bool isLoading;
  final bool isSending;
  final bool isClosed;
  final DateTime? submittedAt;
  final bool loadFailed;

  int get lastMessageId => messages.isEmpty ? 0 : messages.last.id;

  FeedbackChatState copyWith({
    List<FeedbackChatMessage>? messages,
    bool? isLoading,
    bool? isSending,
    bool? isClosed,
    DateTime? submittedAt,
    bool? loadFailed,
  }) {
    return FeedbackChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      isClosed: isClosed ?? this.isClosed,
      submittedAt: submittedAt ?? this.submittedAt,
      loadFailed: loadFailed ?? this.loadFailed,
    );
  }
}

/// One conversation. Not real time: it loads on open, then asks for newer
/// messages every [_pollInterval] while the chat is on screen.
final feedbackChatProvider = NotifierProvider.autoDispose
    .family<FeedbackChatNotifier, FeedbackChatState, FeedbackThreadRef>(FeedbackChatNotifier.new);

class FeedbackChatNotifier extends AutoDisposeFamilyNotifier<FeedbackChatState, FeedbackThreadRef> {
  static const _pollInterval = Duration(seconds: 20);

  Timer? _poll;
  bool _disposed = false;
  bool _refreshing = false;

  @override
  FeedbackChatState build(FeedbackThreadRef arg) {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _poll?.cancel();
    });
    Future.microtask(refresh);
    _poll = Timer.periodic(_pollInterval, (_) => refresh());
    return const FeedbackChatState();
  }

  /// Fetches messages newer than the last one shown.
  Future<void> refresh() async {
    if (_refreshing || _disposed) return;
    _refreshing = true;
    try {
      final response = await ref.read(feedbackAPIRepoProvider).getThread(arg, afterId: state.lastMessageId);
      final page = response.data;
      if (_disposed) return;
      if (!response.success || page == null) {
        state = state.copyWith(isLoading: false, loadFailed: state.messages.isEmpty);
        return;
      }
      final known = {for (final message in state.messages) message.id};
      state = state.copyWith(
        messages: [...state.messages, ...page.messages.where((message) => !known.contains(message.id))],
        isLoading: false,
        isClosed: page.isClosed,
        submittedAt: page.submittedAt,
        loadFailed: false,
      );
      // The server marked the team's replies read when it sent them.
      ref.read(feedbackRepliesProvider.notifier).markSeen();
    } catch (e) {
      debugPrint('Failed to load feedback thread: $e');
      if (!_disposed) state = state.copyWith(isLoading: false, loadFailed: state.messages.isEmpty);
    } finally {
      _refreshing = false;
    }
  }

  /// Sends a message; returns whether it arrived.
  Future<bool> send(String body) async {
    final text = body.trim();
    if (text.isEmpty || state.isSending) return false;
    state = state.copyWith(isSending: true);
    try {
      final response = await ref.read(feedbackAPIRepoProvider).sendMessage(arg, text);
      if (_disposed) return response.success;
      final message = response.data;
      state = state.copyWith(
        isSending: false,
        // Writing reopens a closed conversation on the server too.
        isClosed: response.success ? false : state.isClosed,
        messages: message == null ? state.messages : [...state.messages, message],
      );
      return response.success;
    } catch (e) {
      debugPrint('Failed to send feedback message: $e');
      if (!_disposed) state = state.copyWith(isSending: false);
      return false;
    }
  }
}

/// Replies from the team the user has not seen, across all conversations.
/// Checked on start and when the app comes back; the notification host
/// announces an increase.
final feedbackRepliesProvider = NotifierProvider<FeedbackRepliesNotifier, int>(FeedbackRepliesNotifier.new);

class FeedbackRepliesNotifier extends Notifier<int> {
  static const _minInterval = Duration(minutes: 2);

  DateTime? _lastCheck;
  bool _checking = false;

  @override
  int build() => 0;

  Future<void> check({bool force = false}) async {
    final threads = ref.read(feedbackThreadsProvider);
    if (threads.isEmpty || _checking) return;
    final last = _lastCheck;
    if (!force && last != null && DateTime.now().difference(last) < _minInterval) return;
    _checking = true;
    try {
      final repo = ref.read(feedbackAPIRepoProvider);
      var unread = 0;
      for (final thread in threads) {
        final response = await repo.getUnread(thread);
        unread += response.data ?? 0;
      }
      state = unread;
    } catch (e) {
      debugPrint('Failed to check feedback replies: $e');
    } finally {
      _lastCheck = DateTime.now();
      _checking = false;
    }
  }

  void markSeen() {
    if (state != 0) state = 0;
  }
}
