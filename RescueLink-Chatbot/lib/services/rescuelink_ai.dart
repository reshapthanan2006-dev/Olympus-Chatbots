import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'rescuelink_faq.dart';

enum RescueLinkIntent { overview, requestHelp }

// Only complete, approved questions can cross the service boundary.
final _generalQuestion = RegExp(
  r'^(?:(?:what is|what can i do with|how (?:do i use|does)) '
  r'rescuelink(?: lk)?(?: work)?|how do i (?:ask for assistance|get started) '
  r'(?:in|with) rescuelink(?: lk)?|'
  r'rescuelink lk යනු කුමක්ද|rescuelink lk என்றால் என்ன)\??$',
);

bool _isApprovedQuestion(String question) =>
    _generalQuestion.firstMatch(question)?.end == question.length;

/// Classifies approved general questions. Replies come from the offline FAQ.
abstract interface class RescueLinkAiService {
  Future<RescueLinkIntent?> classify(String question, AppLanguage language);
}

class MockRescueLinkAiService implements RescueLinkAiService {
  const MockRescueLinkAiService(this.intent);

  final RescueLinkIntent? intent;

  @override
  Future<RescueLinkIntent?> classify(
    String question,
    AppLanguage language,
  ) async {
    return intent;
  }
}

class HttpRescueLinkAiService implements RescueLinkAiService {
  const HttpRescueLinkAiService({
    this.backendUrl = const String.fromEnvironment('RESCUELINK_AI_BACKEND_URL'),
    this.client,
    this.timeout = const Duration(milliseconds: 2800),
  });

  final String backendUrl;
  final http.Client? client;
  final Duration timeout;

  @override
  Future<RescueLinkIntent?> classify(
    String question,
    AppLanguage language,
  ) async {
    final url = Uri.tryParse(backendUrl);
    if (!_isApprovedQuestion(question) ||
        url == null ||
        url.host.isEmpty ||
        url.userInfo.isNotEmpty ||
        url.hasQuery ||
        url.hasFragment ||
        !(url.scheme == 'https' ||
            (url.scheme == 'http' &&
                const {'localhost', '127.0.0.1', '::1'}.contains(url.host)))) {
      return null;
    }

    final httpClient = client ?? http.Client();
    final abort = Completer<void>();
    final request =
        http.AbortableRequest('POST', url, abortTrigger: abort.future)
          ..followRedirects = false
          ..headers['content-type'] = 'application/json'
          ..body = jsonEncode({
            'question': question,
            'language': language.name,
          });

    try {
      final response = await httpClient
          .send(request)
          .then(http.Response.fromStream)
          .timeout(
            timeout,
            onTimeout: () {
              abort.complete();
              throw TimeoutException('Classification timed out');
            },
          );
      if (response.statusCode != 200) return null;
      final payload = jsonDecode(utf8.decode(response.bodyBytes));
      if (payload is! Map<String, dynamic> || payload.length != 1) return null;
      return switch (payload) {
        {'intent': 'overview'} => RescueLinkIntent.overview,
        {'intent': 'requestHelp'} => RescueLinkIntent.requestHelp,
        _ => null,
      };
    } on Exception {
      return null;
    } finally {
      if (client == null) httpClient.close();
    }
  }
}

class RescueLinkAssistant {
  const RescueLinkAssistant({this.aiService});

  final RescueLinkAiService? aiService;

  Future<String> reply(String input, AppLanguage language) async {
    final content = RescueLinkFaq.getContent(language);
    final offlineReply = RescueLinkFaq.getReply(input, language: language);
    final service = aiService ?? const HttpRescueLinkAiService();
    final question = input.trim().toLowerCase();
    if (offlineReply != content.noMatchReply ||
        !_isApprovedQuestion(question)) {
      return offlineReply;
    }

    try {
      final intent = await service
          .classify(question, language)
          .timeout(const Duration(seconds: 3));
      return switch (intent) {
        RescueLinkIntent.overview => content.welcomeMessage,
        RescueLinkIntent.requestHelp =>
          content.topicReplies[TopicId.requestHelp]!,
        null => offlineReply,
      };
    } on Exception {
      return offlineReply;
    }
  }
}
