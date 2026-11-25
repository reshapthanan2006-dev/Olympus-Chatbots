import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rescuelink_assistant/main.dart';
import 'package:rescuelink_assistant/screens/assistant_screen.dart';
import 'package:rescuelink_assistant/services/rescuelink_ai.dart';
import 'package:rescuelink_assistant/services/rescuelink_faq.dart';

class RecordingAiService implements RescueLinkAiService {
  final calls = <(String, AppLanguage)>[];

  @override
  Future<RescueLinkIntent?> classify(
    String question,
    AppLanguage language,
  ) async {
    calls.add((question, language));
    throw const FormatException('Invalid classification');
  }
}

void main() {
  const endpoint = 'https://assistant.example/classify';
  const question = 'what is rescuelink lk?';

  test(
    'HTTP classifier posts only the approved question and language',
    () async {
      final service = HttpRescueLinkAiService(
        backendUrl: endpoint,
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.toString(), endpoint);
          expect(request.followRedirects, isFalse);
          expect(jsonDecode(request.body), {
            'question': question,
            'language': 'ta',
          });
          return http.Response('{"intent":"overview"}', 200);
        }),
      );
      final assistant = RescueLinkAssistant(aiService: service);
      expect(
        await assistant.reply('What is RescueLink LK?', AppLanguage.ta),
        RescueLinkFaq.tamilContent.welcomeMessage,
      );
    },
  );

  test(
    'HTTP classifier blocks sensitive inputs even when called directly',
    () async {
      final service = HttpRescueLinkAiService(
        backendUrl: endpoint,
        client: MockClient((_) async => fail('Unexpected HTTP request')),
      );
      for (final input in [
        '$question 6.9271, 79.8612',
        '$question contact me at 0771234567',
        '$question is my SOS sent?',
      ]) {
        expect(await service.classify(input, AppLanguage.en), isNull);
      }
    },
  );

  test('HTTP errors and invalid classification fall back offline', () async {
    for (final response in [
      http.Response('{"intent":"overview"}', 503),
      http.Response('{"intent":"overview"}', 302),
      http.Response('not JSON', 200),
      http.Response('{"intent":"disasterUpdates"}', 200),
      http.Response('{"intent":"overview","answer":"unapproved"}', 200),
    ]) {
      final service = HttpRescueLinkAiService(
        backendUrl: endpoint,
        client: MockClient((_) async => response),
      );
      expect(
        await RescueLinkAssistant(aiService: service)
            .reply(question, AppLanguage.en),
        RescueLinkFaq.scopeReply,
      );
    }
  });

  test('HTTP timeout falls back offline', () async {
    final pending = Completer<http.Response>();
    final service = HttpRescueLinkAiService(
      backendUrl: endpoint,
      client: MockClient((_) => pending.future),
      timeout: const Duration(milliseconds: 10),
    );
    try {
      expect(
        await RescueLinkAssistant(aiService: service)
            .reply(question, AppLanguage.en),
        RescueLinkFaq.scopeReply,
      );
    } finally {
      pending.complete(http.Response('{"intent":"overview"}', 200));
    }
  });

  testWidgets('Typed general question uses the mock and selected language', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MyApp(
        home: AssistantScreen(
          aiService: MockRescueLinkAiService(RescueLinkIntent.requestHelp),
        ),
      ),
    );
    await tester.tap(find.byType(DropdownButton<AppLanguage>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('தமிழ்').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'How do I ask for assistance in RescueLink LK?',
    );
    await tester.tap(find.text('அனுப்பு'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        RescueLinkFaq.getReplyForTopic(
          TopicId.requestHelp,
          language: AppLanguage.ta,
        ),
      ),
      findsOneWidget,
    );
  });

  test('Fixed responses and unapproved input bypass classification', () async {
    final service = RecordingAiService();
    final assistant = RescueLinkAssistant(aiService: service);
    final cases = {
      'Request Help, I am trapped': RescueLinkFaq.immediateDangerReply,
      'Is my SOS pending?': RescueLinkFaq.notSentReply,
      'Is a rescue team coming?': RescueLinkFaq.serverReceiptReply,
      'Which shelters are open?': RescueLinkFaq.findSheltersReply,
      'Any live alerts from RescueLink LK?': RescueLinkFaq.disasterUpdatesReply,
      'Show me safety instructions': RescueLinkFaq.safetyGuideReply,
      'What is RescueLink LK? My number is 0771234567':
          RescueLinkFaq.scopeReply,
      'What is the capital of Sri Lanka?': RescueLinkFaq.scopeReply,
    };
    for (final entry in cases.entries) {
      expect(await assistant.reply(entry.key, AppLanguage.en), entry.value);
    }
    expect(service.calls, isEmpty);
  });

  test(
    'Unavailable, unmatched and failed classification fall back offline',
    () async {
      const question = 'What is RescueLink LK?';
      const language = AppLanguage.si;
      final service = RecordingAiService();
      final assistants = [
        const RescueLinkAssistant(),
        const RescueLinkAssistant(aiService: MockRescueLinkAiService(null)),
        RescueLinkAssistant(aiService: service),
      ];
      for (final assistant in assistants) {
        expect(
          await assistant.reply(question, language),
          RescueLinkFaq.sinhalaContent.noMatchReply,
        );
      }
      expect(service.calls, [('what is rescuelink lk?', language)]);
    },
  );

  test(
    'Multilingual natural FAQ variations work offline with and without punctuation',
    () async {
      final service = RecordingAiService();
      final assistant = RescueLinkAssistant(aiService: service);

      final cases = <(String, AppLanguage, TopicId)>[
        ('உதவி கோருவது எப்படி', AppLanguage.ta, TopicId.requestHelp),
        ('உதவி கோருவது எப்படி?', AppLanguage.ta, TopicId.requestHelp),
        ('தங்குமிடம் எங்கே?', AppLanguage.ta, TopicId.findShelters),
        ('பேரிடர் எச்சரிக்கைகள்', AppLanguage.ta, TopicId.disasterUpdates),
        ('பாதுகாப்பு குறிப்புகள்?', AppLanguage.ta, TopicId.safetyGuide),
        ('උදව් ඉල්ලන්නේ කොහොමද', AppLanguage.si, TopicId.requestHelp),
        ('ආරක්ෂිත ස්ථාන?', AppLanguage.si, TopicId.findShelters),
        ('ආපදා තොරතුරු', AppLanguage.si, TopicId.disasterUpdates),
        ('ආරක්ෂක උපදෙස්?', AppLanguage.si, TopicId.safetyGuide),
        ('How do I request help', AppLanguage.en, TopicId.requestHelp),
        ('How do I request help?', AppLanguage.en, TopicId.requestHelp),
        ('Safety tips?', AppLanguage.en, TopicId.safetyGuide),
      ];

      for (final (question, language, topic) in cases) {
        expect(
          await assistant.reply(question, language),
          RescueLinkFaq.getReplyForTopic(topic, language: language),
        );
      }
      expect(service.calls, isEmpty);
    },
  );
}
