import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;

import 'nearfix_chatbot_engine.dart';

/// Supported structured intents returned by the NearFix AI assistant.
enum NearFixAiIntent {
  faq,
  serviceProblem,
  followUp,
  clarification,
  unconfirmed,
  unrelated,
  fallback,
}

/// Structured AI response object containing validated categorization
/// and grounded response metadata.
class NearFixAiResult {
  final NearFixAiIntent intent;
  final String? detectedLanguage; // 'en' or 'ta'
  final String? serviceId;
  final String? faqId;
  final String? replyMessage;
  final bool clarificationNeeded;
  final String? clarificationType;
  final double confidence;
  final Map<String, dynamic> rawJson;

  const NearFixAiResult({
    required this.intent,
    this.detectedLanguage,
    this.serviceId,
    this.faqId,
    this.replyMessage,
    this.clarificationNeeded = false,
    this.clarificationType,
    this.confidence = 1.0,
    this.rawJson = const {},
  });

  factory NearFixAiResult.fromJson(Map<String, dynamic> json) {
    final rawIntent = json['intent'] as String? ?? 'fallback';
    NearFixAiIntent intent;
    switch (rawIntent.toLowerCase()) {
      case 'faq':
        intent = NearFixAiIntent.faq;
        break;
      case 'service_problem':
      case 'serviceproblem':
        intent = NearFixAiIntent.serviceProblem;
        break;
      case 'follow_up':
      case 'followup':
        intent = NearFixAiIntent.followUp;
        break;
      case 'clarification':
        intent = NearFixAiIntent.clarification;
        break;
      case 'unconfirmed':
        intent = NearFixAiIntent.unconfirmed;
        break;
      case 'unrelated':
      case 'out_of_scope':
        intent = NearFixAiIntent.unrelated;
        break;
      default:
        intent = NearFixAiIntent.fallback;
    }

    return NearFixAiResult(
      intent: intent,
      detectedLanguage:
          json['language'] as String? ?? json['detected_language'] as String?,
      serviceId: json['service_id'] as String?,
      faqId: json['faq_id'] as String?,
      replyMessage:
          json['reply'] as String? ?? json['reply_message'] as String?,
      clarificationNeeded: json['clarification_needed'] as bool? ?? false,
      clarificationType: json['clarification_type'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      rawJson: json,
    );
  }

  Map<String, dynamic> toJson() => {
        'intent': intent.name,
        'language': detectedLanguage,
        'service_id': serviceId,
        'faq_id': faqId,
        'reply': replyMessage,
        'clarification_needed': clarificationNeeded,
        'clarification_type': clarificationType,
        'confidence': confidence,
      };
}

/// Abstract service interface for NearFix AI processing.
abstract class NearFixAiService {
  /// Whether this AI service is properly configured with an endpoint or active mock.
  bool get isConfigured;

  /// Whether this service represents a live remote connection.
  bool get isLiveBackend;

  /// Human-readable description of the service connection.
  String get connectionDescription;

  /// Resolves the default AI service based on compile-time environment variables.
  ///
  /// Selection order:
  /// 1. If `NEARFIX_AI_BACKEND_URL` is set and non-empty, returns [HttpNearFixAiService].
  /// 2. If `NEARFIX_AI_USE_MOCK` is true, returns [MockNearFixAiService].
  /// 3. Otherwise returns `null`, causing the engine to use the deterministic rule-based fallback.
  static NearFixAiService? resolveDefault() {
    const backendUrl =
        String.fromEnvironment('NEARFIX_AI_BACKEND_URL', defaultValue: '');
    if (backendUrl.trim().isNotEmpty) {
      return HttpNearFixAiService(backendUrl: backendUrl.trim());
    }

    const useMock =
        bool.fromEnvironment('NEARFIX_AI_USE_MOCK', defaultValue: false);
    if (useMock) {
      return const MockNearFixAiService();
    }

    return null;
  }

  /// Processes a customer message and returns a structured intent.
  Future<NearFixAiResult?> processMessage({
    required String userMessage,
    required String currentStage,
    required String? currentServiceId,
    required String? currentArea,
    required ChatLanguage currentLanguage,
    required List<NearFixFaqItem> candidateFaqs,
    required List<NearFixServiceCategory> categories,
  });
}

/// Real HTTP client that calls a backend proxy endpoint.
///
/// NOTE: Flutter applications NEVER embed API keys, secrets, or provider tokens directly.
/// All live AI calls route through a secured backend proxy URL specified via
/// [backendUrl] or compile-time environment variable `NEARFIX_AI_BACKEND_URL`.
class HttpNearFixAiService implements NearFixAiService {
  final String backendUrl;
  final Duration timeout;
  final HttpClient? _customClient;

  HttpNearFixAiService({
    String? backendUrl,
    this.timeout = const Duration(seconds: 8),
    HttpClient? client,
  })  : backendUrl = backendUrl ??
            const String.fromEnvironment('NEARFIX_AI_BACKEND_URL',
                defaultValue: ''),
        _customClient = client;

  @override
  bool get isConfigured => backendUrl.trim().isNotEmpty;

  @override
  bool get isLiveBackend => isConfigured;

  @override
  String get connectionDescription => isConfigured
      ? 'Live backend proxy configured ($backendUrl)'
      : 'Live backend proxy not configured (NEARFIX_AI_BACKEND_URL is unset)';

  @override
  Future<NearFixAiResult?> processMessage({
    required String userMessage,
    required String currentStage,
    required String? currentServiceId,
    required String? currentArea,
    required ChatLanguage currentLanguage,
    required List<NearFixFaqItem> candidateFaqs,
    required List<NearFixServiceCategory> categories,
  }) async {
    if (!isConfigured) return null;

    final client = _customClient ?? HttpClient();
    try {
      final uri = Uri.parse(backendUrl);
      final request = await client.postUrl(uri).timeout(timeout);
      request.headers.contentType = ContentType.json;

      // Provide model with ONLY the minimal conversation context and relevant NearFix entries.
      final payload = jsonEncode({
        'message': userMessage,
        'current_stage': currentStage,
        'current_service_id': currentServiceId,
        'language': currentLanguage.name,
        'candidate_faqs': candidateFaqs.take(8).map((f) => {
              'id': f.id,
              'topic': f.topic,
              'question': f.localizedQuestion(currentLanguage),
            }).toList(),
        'categories': categories.map((c) => {
              'id': c.id,
              'name': c.localizedName(currentLanguage),
            }).toList(),
      });

      request.write(payload);
      final response = await request.close().timeout(timeout);

      if (response.statusCode != 200) {
        debugPrint(
          '[NearFixAI] Backend HTTP error (status=${response.statusCode}); falling back.',
        );
        return null;
      }

      final responseBody =
          await response.transform(utf8.decoder).join().timeout(timeout);
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final result = NearFixAiResult.fromJson(decoded);
      debugPrint(
        '[NearFixAI] Backend request succeeded (status=200, intent=${result.intent.name}).',
      );
      return result;
    } catch (e) {
      // Graceful fallback on network failure, timeout, or invalid JSON.
      debugPrint(
        '[NearFixAI] Backend request failed (${e.runtimeType}); falling back.',
      );
      return null;
    } finally {
      if (_customClient == null) {
        client.close(force: true);
      }
    }
  }
}

/// Offline Mock AI service grounded strictly in NearFix knowledge base.
///
/// Handles natural English and Tamil phrasings, unconfirmed pricing questions,
/// ambiguous battery problems, prompt injection attempts, out-of-scope queries,
/// and fresh intake after request completion.
class MockNearFixAiService implements NearFixAiService {
  final bool simulateNetworkError;

  const MockNearFixAiService({
    this.simulateNetworkError = false,
  });

  @override
  bool get isConfigured => true;

  @override
  bool get isLiveBackend => false;

  @override
  String get connectionDescription =>
      'Mock NearFix AI Service (local grounded model; live backend not configured)';

  static final RegExp _tamilScriptRegex = RegExp(r'[\u0B80-\u0BFF]');

  bool _detectIsTamil(String text) => _tamilScriptRegex.hasMatch(text);

  bool _isPromptInjection(String text) {
    final lower = text.toLowerCase();
    return (lower.contains('ignore') &&
            (lower.contains('instruction') ||
                lower.contains('rule') ||
                lower.contains('guideline') ||
                lower.contains('prompt'))) ||
        lower.contains('disregard') ||
        lower.contains('you are now') ||
        lower.contains('jailbreak') ||
        lower.contains('bypass restrictions') ||
        lower.contains('முந்தைய வழிமுறைகளை') ||
        lower.contains('விதியை மீறு');
  }

  bool _isUnrelatedTopic(String text) {
    final lower = text.toLowerCase();
    return lower.contains('capital of') ||
        lower.contains('weather') ||
        lower.contains('forecast') ||
        lower.contains('cricket') ||
        lower.contains('football') ||
        lower.contains('who won') ||
        lower.contains('recipe') ||
        lower.contains('cook') ||
        lower.contains('president') ||
        lower.contains('movie') ||
        lower.contains('song') ||
        lower.contains('poem') ||
        lower.contains('joke') ||
        lower.contains('helplink') ||
        lower.contains('rescuelink') ||
        lower.contains('ngo') ||
        lower.contains('donor') ||
        lower.contains('disaster relief') ||
        lower.contains('வானிலை') ||
        lower.contains('கிரிக்கெட்') ||
        lower.contains('சினிமா') ||
        lower.contains('சமையல்') ||
        lower.contains('நன்கொடை');
  }

  bool _isUnconfirmedPolicyOrPricing(String text) {
    final lower = text.toLowerCase();
    return lower.contains('how much does a plumber charge per hour') ||
        lower.contains('charge per hour') ||
        lower.contains('hourly rate') ||
        lower.contains('hourly price') ||
        lower.contains('fixed price') ||
        lower.contains('fixed rate') ||
        lower.contains('discount code') ||
        lower.contains('how much will it cost') ||
        lower.contains('exact price') ||
        lower.contains('subscription fee') ||
        lower.contains('monthly subscription') ||
        lower.contains('pay with credit card') ||
        lower.contains('pay online right now') ||
        lower.contains('ஒரு மணி நேர') ||
        lower.contains('மணி நேர') ||
        lower.contains('மணித்தியால') ||
        lower.contains('எவ்வளவு கட்டணம்') ||
        lower.contains('கட்டணம் எவ்வளவு') ||
        lower.contains('நிலையான விலை') ||
        lower.contains('சந்தா கட்டணம்') ||
        lower.contains('கிரெடிட் கார்டு மூலம் செலுத்தலாமா');
  }

  bool _isAmbiguousBattery(String text) {
    final lower = text.toLowerCase();
    final hasBattery =
        lower.contains('battery') || lower.contains('பேட்டரி');
    final hasVehicle = lower.contains('bike') ||
        lower.contains('car') ||
        lower.contains('motorcycle') ||
        lower.contains('vehicle') ||
        lower.contains('பைக்') ||
        lower.contains('கார்') ||
        lower.contains('வாகனம்');
    final hasPhone = lower.contains('phone') ||
        lower.contains('mobile') ||
        lower.contains('smartphone') ||
        lower.contains('கைபேசி') ||
        lower.contains('மொபைல்');
    return hasBattery && !hasVehicle && !hasPhone;
  }

  @override
  Future<NearFixAiResult?> processMessage({
    required String userMessage,
    required String currentStage,
    required String? currentServiceId,
    required String? currentArea,
    required ChatLanguage currentLanguage,
    required List<NearFixFaqItem> candidateFaqs,
    required List<NearFixServiceCategory> categories,
  }) async {
    if (simulateNetworkError) {
      throw const SocketException('Simulated network error connecting to AI proxy');
    }

    final trimmed = userMessage.trim();
    final isTamil = _detectIsTamil(trimmed);
    final lower = trimmed.toLowerCase();

    // 1. Prompt injection / adversarial instructions -> refuse and remain grounded in NearFix.
    if (_isPromptInjection(lower)) {
      return NearFixAiResult(
        intent: NearFixAiIntent.unrelated,
        detectedLanguage: isTamil ? 'ta' : 'en',
        replyMessage: isTamil
            ? 'மன்னிக்கவும், என்னால் NearFix சேவைகள் மற்றும் கேள்விகளுக்கு மட்டுமே உதவ முடியும். வழிகாட்டுதல்களை மீறவோ எனது பாத்திரத்தை மாற்றவோ முடியாது.'
            : 'Sorry, I can only assist with NearFix customer questions and service requests. I cannot follow instructions to change my role or disregard guidelines.',
        confidence: 0.99,
      );
    }

    // 2. Unrelated / out-of-scope topics.
    if (_isUnrelatedTopic(lower)) {
      return NearFixAiResult(
        intent: NearFixAiIntent.unrelated,
        detectedLanguage: isTamil ? 'ta' : 'en',
        replyMessage: isTamil
            ? 'மன்னிக்கவும், இந்தக் கேள்விக்கு என்னிடம் உறுதிப்படுத்தப்பட்ட NearFix தகவல் இல்லை; இந்த மாதிரியில் NearFix வாடிக்கையாளர் கேள்விகளுக்குப் பதிலளிக்கவும் கற்பனை மாதிரி சேவை வழங்குநர்களைக் காட்டவும் மட்டுமே முடியும்.'
            : 'Sorry, I do not have documented NearFix facts for that question, and this standalone prototype can only answer NearFix customer questions and match fictional demo providers.',
        confidence: 0.98,
      );
    }

    // 3. Unconfirmed policies, pricing, or live capabilities.
    if (_isUnconfirmedPolicyOrPricing(lower)) {
      return NearFixAiResult(
        intent: NearFixAiIntent.unconfirmed,
        detectedLanguage: isTamil ? 'ta' : 'en',
        faqId: 'NF-FAQ-026',
        replyMessage: isTamil
            ? 'NearFix ஆவணங்களில் நிலையான பழுதுபார்ப்பு விலைகளோ மணிநேரக் கட்டணங்களோ உறுதிப்படுத்தப்படவில்லை. இறுதித் தொகை சேவை வழங்குநர், வேலை, பொருட்கள் ஆகியவற்றைப் பொறுத்தே அமையும். நேரடி கட்டண வசதி இன்னும் இந்த மாதிரியில் செயல்படுத்தப்படவில்லை.'
            : 'NearFix does not specify fixed repair prices or hourly rates in this prototype. The final amount depends on the independent provider, work, and materials. Live payment or checkout is not confirmed.',
        confidence: 0.96,
      );
    }

    // 4. Ambiguous battery problem -> ask focused clarifying question.
    if (_isAmbiguousBattery(lower)) {
      return NearFixAiResult(
        intent: NearFixAiIntent.clarification,
        detectedLanguage: isTamil ? 'ta' : 'en',
        clarificationNeeded: true,
        clarificationType: 'battery',
        replyMessage: isTamil
            ? 'பேட்டரி பிரச்சினை என்று குறிப்பிட்டீர்கள். இது வாகனத்திற்கா (கார்/மோட்டார் சைக்கிள்) அல்லது கைபேசிக்கா?'
            : 'You mentioned a battery problem. Is this for a vehicle (car/motorcycle) or a mobile phone?',
        confidence: 0.97,
      );
    }

    // 5. Intake after completion: A clear new problem in 'done' stage starts a fresh request.
    // e.g. "Now my kitchen pipe is leaking" or "இப்போது சமையலறை குழாயில் கசிவு"
    final detectedService = _detectServiceFromNaturalText(lower);
    if (detectedService != null) {
      final isNewProblemPhrasing = lower.contains('now') ||
          lower.contains('pipe is leaking') ||
          lower.contains('leaking') ||
          lower.contains('drip') ||
          lower.contains('dripping') ||
          lower.contains('keeps dripping') ||
          lower.contains('tap') ||
          lower.contains('overflow') ||
          lower.contains('spark') ||
          lower.contains('broken') ||
          lower.contains('not starting') ||
          lower.contains('flat tyre') ||
          lower.contains('locked out') ||
          lower.contains('stuck') ||
          lower.contains('கசிவு') ||
          lower.contains('சொட்டு') ||
          lower.contains('இப்போது') ||
          lower.contains('வேலை செய்யவில்லை') ||
          lower.contains('ஸ்டார்ட் ஆகவில்லை') ||
          lower.contains('பூட்டு');

      if (currentStage == 'done' && isNewProblemPhrasing) {
        return NearFixAiResult(
          intent: NearFixAiIntent.serviceProblem,
          detectedLanguage: isTamil ? 'ta' : 'en',
          serviceId: detectedService,
          replyMessage: isTamil
              ? 'இது ${_serviceLabelTa(detectedService)} தொடர்பான புதிய பிரச்சினையாகத் தெரிகிறது. எந்த ஊர் அல்லது பகுதியில் உதவி தேவை?'
              : 'This sounds like a ${_serviceLabelEn(detectedService)} issue. Which town or area do you need help in?',
          confidence: 0.95,
        );
      }

      if (currentStage == 'service' || currentStage == 'problem') {
        return NearFixAiResult(
          intent: NearFixAiIntent.serviceProblem,
          detectedLanguage: isTamil ? 'ta' : 'en',
          serviceId: detectedService,
          replyMessage: isTamil
              ? 'இது ${_serviceLabelTa(detectedService)} தொடர்பான பிரச்சினையாகத் தெரிகிறது. எந்த ஊர் அல்லது பகுதியில் உதவி தேவை?'
              : 'This sounds like a ${_serviceLabelEn(detectedService)} issue. Which town or area do you need help in?',
          confidence: 0.95,
        );
      }
    }

    // 6. Natural phrasing FAQ questions.
    final matchedFaq = _matchNaturalFaq(lower, candidateFaqs);
    if (matchedFaq != null) {
      final lang = isTamil ? ChatLanguage.ta : ChatLanguage.en;
      return NearFixAiResult(
        intent: NearFixAiIntent.faq,
        detectedLanguage: isTamil ? 'ta' : 'en',
        faqId: matchedFaq.id,
        replyMessage: matchedFaq.localizedAnswer(lang),
        confidence: 0.94,
      );
    }

    // 7. Area input during 'area' stage.
    if (currentStage == 'area') {
      if (['yes', 'no', 'ok', 'not sure', 'sure', 'ஆம்', 'இல்லை', 'சரி', 'தெரியாது']
              .contains(lower) ||
          trimmed.length < 3) {
        return null;
      }
      return NearFixAiResult(
        intent: NearFixAiIntent.followUp,
        detectedLanguage: isTamil ? 'ta' : 'en',
        confidence: 0.92,
      );
    }

    // Fallback: Return null to signal fallback to rule-based engine.
    return null;
  }

  String? _detectServiceFromNaturalText(String lower) {
    if (lower.contains('pipe') ||
        lower.contains('leak') ||
        lower.contains('leaking') ||
        lower.contains('water') ||
        lower.contains('tap') ||
        lower.contains('sink') ||
        lower.contains('toilet') ||
        lower.contains('drain') ||
        lower.contains('plumber') ||
        lower.contains('plumbing') ||
        lower.contains('குழாய்') ||
        lower.contains('நீர் கசிவு') ||
        lower.contains('தண்ணீர்') ||
        lower.contains('குழாய்ப்பணி')) {
      return 'plumber';
    }
    if (lower.contains('bike') ||
        lower.contains('car') ||
        lower.contains('motorcycle') ||
        lower.contains('scooter') ||
        lower.contains('engine') ||
        lower.contains('tyre') ||
        lower.contains('tire') ||
        lower.contains('mechanic') ||
        lower.contains('puncture') ||
        lower.contains('breakdown') ||
        lower.contains('பைக்') ||
        lower.contains('கார்') ||
        lower.contains('மோட்டார்') ||
        lower.contains('மெக்கானிக்') ||
        lower.contains('வாகனம்')) {
      return 'mechanic';
    }
    if (lower.contains('electric') ||
        lower.contains('wiring') ||
        lower.contains('spark') ||
        lower.contains('sparks') ||
        lower.contains('socket') ||
        lower.contains('switch') ||
        lower.contains('electrician') ||
        lower.contains('power problem') ||
        lower.contains('மின்சாரம்') ||
        lower.contains('மின்கம்பி') ||
        lower.contains('தீப்பொறி')) {
      return 'electrician';
    }
    if (lower.contains('air conditioner') ||
        lower.contains('air conditioning') ||
        lower.contains('aircon') ||
        lower.contains('not cooling') ||
        lower.contains('ac repair') ||
        lower.contains('ac ') ||
        lower.endsWith('ac') ||
        lower.contains('குளிரூட்டி') ||
        lower.contains('ஏசி')) {
      return 'ac';
    }
    if (lower.contains('lock') ||
        lower.contains('locked out') ||
        lower.contains('key') ||
        lower.contains('locksmith') ||
        lower.contains('பூட்டு') ||
        lower.contains('சாவி')) {
      return 'locksmith';
    }
    if (lower.contains('carpenter') ||
        lower.contains('furniture') ||
        lower.contains('woodwork') ||
        lower.contains('cupboard') ||
        lower.contains('wooden door') ||
        lower.contains('தச்சு') ||
        lower.contains('மர வேலை')) {
      return 'carpenter';
    }
    if (lower.contains('cleaning') ||
        lower.contains('cleaner') ||
        lower.contains('clean house') ||
        lower.contains('சுத்தம்')) {
      return 'cleaning';
    }
    if (lower.contains('phone') ||
        lower.contains('mobile') ||
        lower.contains('smartphone') ||
        lower.contains('screen') ||
        lower.contains('charging port') ||
        lower.contains('கைபேசி') ||
        lower.contains('மொபைல்')) {
      return 'phone_repair';
    }
    return null;
  }

  NearFixFaqItem? _matchNaturalFaq(
      String lower, List<NearFixFaqItem> candidateFaqs) {
    if (candidateFaqs.isEmpty) return null;

    NearFixFaqItem? find(String id) {
      try {
        return candidateFaqs.firstWhere((item) => item.id == id);
      } catch (_) {
        return null;
      }
    }

    if (lower.contains('what is nearfix') ||
        lower.contains('what nearfix is') ||
        lower.contains('what nearfix does') ||
        lower.contains('designed to do') ||
        lower.contains('explain nearfix') ||
        lower.contains('tell me about nearfix') ||
        lower.contains('what does nearfix do') ||
        lower.contains('nearfix என்றால் என்ன') ||
        lower.contains('nearfix பற்றி')) {
      return find('NF-FAQ-001');
    }

    if (lower.contains('who is nearfix for') ||
        lower.contains('who can use nearfix') ||
        lower.contains('யாருக்கானது')) {
      return find('NF-FAQ-002');
    }

    if (lower.contains('what services') ||
        lower.contains('services are available') ||
        lower.contains('list of services') ||
        lower.contains('என்னென்ன சேவைகள்')) {
      return find('NF-FAQ-004');
    }

    if (lower.contains('is nearfix live') ||
        lower.contains('available now') ||
        lower.contains('download nearfix') ||
        lower.contains('முழு செயலி தயாரா') ||
        lower.contains('செயலி இப்போது கிடைக்கிறதா')) {
      return find('NF-FAQ-005');
    }

    if (lower.contains('what can you do') ||
        lower.contains('what can this chatbot do') ||
        lower.contains('prototype limits') ||
        lower.contains('உதவியாளர் என்ன செய்யும்')) {
      return find('NF-FAQ-006');
    }

    if (lower.contains('which languages') ||
        lower.contains('tanglish') ||
        lower.contains('languages supported') ||
        lower.contains('எந்த மொழிகளை')) {
      return find('NF-FAQ-007');
    }

    if (lower.contains('how do i book') ||
        lower.contains('how to book') ||
        lower.contains('booking process') ||
        lower.contains('steps to book') ||
        lower.contains('சேவையை எப்படி முன்பதிவு') ||
        lower.contains('முன்பதிவு செய்வது எப்படி')) {
      return find('NF-FAQ-025');
    }

    if (lower.contains('pay online') ||
        lower.contains('payment through') ||
        lower.contains('பணம் செலுத்த முடியுமா')) {
      return find('NF-FAQ-030');
    }

    if (lower.contains('location') ||
        lower.contains('who can see my location') ||
        lower.contains('privacy') ||
        lower.contains('என் இருப்பிடம்')) {
      return find('NF-FAQ-034');
    }

    return null;
  }

  String _serviceLabelEn(String serviceId) {
    switch (serviceId) {
      case 'mechanic':
        return 'Mechanic / Vehicle Repair';
      case 'plumber':
        return 'Plumbing';
      case 'electrician':
        return 'Electrical Work';
      case 'ac':
        return 'Air Conditioning';
      case 'locksmith':
        return 'Locksmith';
      case 'carpenter':
        return 'Carpentry';
      case 'cleaning':
        return 'Cleaning';
      case 'phone_repair':
        return 'Phone Repair';
      default:
        return serviceId;
    }
  }

  String _serviceLabelTa(String serviceId) {
    switch (serviceId) {
      case 'mechanic':
        return 'வாகனப் பழுதுபார்ப்பு';
      case 'plumber':
        return 'குழாய்ப்பணி';
      case 'electrician':
        return 'மின்சார வேலை';
      case 'ac':
        return 'குளிரூட்டி பழுதுபார்ப்பு';
      case 'locksmith':
        return 'பூட்டு வேலை';
      case 'carpenter':
        return 'தச்சு வேலை';
      case 'cleaning':
        return 'சுத்தம் செய்தல்';
      case 'phone_repair':
        return 'கைபேசி பழுதுபார்ப்பு';
      default:
        return serviceId;
    }
  }
}
