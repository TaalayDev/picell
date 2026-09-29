import 'package:equatable/equatable.dart';

/// The app's key to one feedback conversation: the feedback id and the
/// secret token the server returned when it was submitted.
class FeedbackThreadRef extends Equatable {
  const FeedbackThreadRef({required this.id, required this.token});

  final int id;
  final String token;

  Map<String, dynamic> toJson() => {'id': id, 'token': token};

  static FeedbackThreadRef? tryParse(Object? json) {
    if (json is! Map) return null;
    final rawId = json['id'];
    final id = rawId is int ? rawId : int.tryParse('$rawId');
    final token = json['token'];
    if (id == null || token is! String || token.isEmpty) return null;
    return FeedbackThreadRef(id: id, token: token);
  }

  @override
  List<Object?> get props => [id, token];
}

enum FeedbackMessageSender { user, admin }

class FeedbackChatMessage extends Equatable {
  const FeedbackChatMessage({
    required this.id,
    required this.sender,
    required this.body,
    required this.createdAt,
    this.author,
    this.read = false,
  });

  final int id;
  final FeedbackMessageSender sender;
  final String body;
  final DateTime createdAt;

  /// The replying admin's display name, if they set one.
  final String? author;

  /// Whether the other side has seen it.
  final bool read;

  bool get isMine => sender == FeedbackMessageSender.user;

  static FeedbackChatMessage? tryParse(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    try {
      return FeedbackChatMessage(
        id: json['id'] as int,
        sender: json['sender'] == 'admin' ? FeedbackMessageSender.admin : FeedbackMessageSender.user,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        author: json['author'] as String?,
        read: json['read'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [id, sender, body, createdAt, author, read];
}

/// One page of `GET /feedback/{id}/thread`.
class FeedbackThreadPage extends Equatable {
  const FeedbackThreadPage({required this.isClosed, required this.submittedAt, required this.messages});

  final bool isClosed;
  final DateTime? submittedAt;
  final List<FeedbackChatMessage> messages;

  static FeedbackThreadPage fromJson(Map<String, dynamic> json) {
    final thread = json['thread'] as Map<String, dynamic>? ?? const {};
    return FeedbackThreadPage(
      isClosed: thread['status'] == 'closed',
      submittedAt: DateTime.tryParse(thread['submitted_at'] as String? ?? ''),
      messages: [
        for (final item in json['messages'] as List? ?? const [])
          if (FeedbackChatMessage.tryParse(item) case final message?) message,
      ],
    );
  }

  @override
  List<Object?> get props => [isClosed, submittedAt, messages];
}
