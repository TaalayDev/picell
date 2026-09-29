import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/feedback_chat_models.dart';

void main() {
  test('reads a thread page with the team\'s reply', () {
    final page = FeedbackThreadPage.fromJson({
      'thread': {'id': 7, 'status': 'open', 'submitted_at': '2026-09-29T10:00:00Z'},
      'messages': [
        {'id': 1, 'sender': 'admin', 'body': 'Thanks! Which device?', 'author': 'Taalay', 'created_at': '2026-09-29T11:00:00Z', 'read': true},
        {'id': 2, 'sender': 'user', 'body': 'Pixel 8', 'author': null, 'created_at': '2026-09-29T11:05:00Z', 'read': false},
        {'id': 'broken'},
      ],
    });

    expect(page.isClosed, isFalse);
    expect(page.submittedAt, DateTime.utc(2026, 9, 29, 10));
    expect(page.messages, hasLength(2));
    expect(page.messages.first.isMine, isFalse);
    expect(page.messages.first.author, 'Taalay');
    expect(page.messages.last.isMine, isTrue);
  });

  test('thread refs survive storage and accept string ids from the server', () {
    const thread = FeedbackThreadRef(id: 7, token: 'abc');
    expect(FeedbackThreadRef.tryParse(thread.toJson()), thread);
    expect(FeedbackThreadRef.tryParse({'id': '7', 'token': 'abc'}), thread);
    expect(FeedbackThreadRef.tryParse({'id': 7, 'token': ''}), isNull);
  });
}
