import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import 'nearfix_ai_service.dart';

/// Origin of the last generated bot response for verification and development logs.
enum NearFixResponseSource {
  liveAi,
  mockAi,
  ruleBasedFallback,
}

/// Supported languages for the NearFix standalone customer chatbot.
enum ChatLanguage {
  en,
  ta,
}

/// One fictional provider record from `assets/demo_providers.json`.
class DemoProvider {
  final String name;
  final String service;
  final String area;
  final String specialty;

  const DemoProvider({
    required this.name,
    required this.service,
    required this.area,
    required this.specialty,
  });

  factory DemoProvider.fromJson(Map<String, dynamic> json) {
    return DemoProvider(
      name: json['name'] as String,
      service: json['service'] as String,
      area: json['area'] as String,
      specialty: json['specialty'] as String,
    );
  }
}

/// One bilingual FAQ entry from `assets/nearfix_faq_en_ta.json`.
class NearFixFaqItem {
  final String id;
  final String topic;
  final String status;
  final Map<String, String> question;
  final Map<String, String> answer;

  const NearFixFaqItem({
    required this.id,
    required this.topic,
    required this.status,
    required this.question,
    required this.answer,
  });

  factory NearFixFaqItem.fromJson(Map<String, dynamic> json) {
    final rawQuestion = json['question'] as Map<String, dynamic>;
    final rawAnswer = json['answer'] as Map<String, dynamic>;
    return NearFixFaqItem(
      id: json['id'] as String,
      topic: json['topic'] as String? ?? '',
      status: json['status'] as String? ?? '',
      question: rawQuestion.map((k, v) => MapEntry(k, v.toString())),
      answer: rawAnswer.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  String localizedQuestion(ChatLanguage lang) =>
      question[lang.name] ?? question['en'] ?? '';

  String localizedAnswer(ChatLanguage lang) =>
      answer[lang.name] ?? answer['en'] ?? '';
}

/// One planned service category from `assets/nearfix_service_categories_en_ta.json`.
class NearFixServiceCategory {
  final String id;
  final Map<String, String> name;
  final Map<String, List<String>> phrasesForRuleMatching;

  const NearFixServiceCategory({
    required this.id,
    required this.name,
    required this.phrasesForRuleMatching,
  });

  factory NearFixServiceCategory.fromJson(Map<String, dynamic> json) {
    final rawName = json['name'] as Map<String, dynamic>;
    final rawPhrases =
        json['phrases_for_rule_matching'] as Map<String, dynamic>? ?? {};
    return NearFixServiceCategory(
      id: json['id'] as String,
      name: rawName.map((k, v) => MapEntry(k, v.toString())),
      phrasesForRuleMatching: rawPhrases.map(
        (k, v) => MapEntry(
          k,
          (v as List<dynamic>).map((item) => item.toString()).toList(),
        ),
      ),
    );
  }

  String localizedName(ChatLanguage lang) =>
      name[lang.name] ?? name['en'] ?? id;
}

/// Result of matching a customer query against NearFix FAQs.
class FaqMatchResult {
  final NearFixFaqItem? match;
  final List<NearFixFaqItem> ambiguousOptions;

  bool get isAmbiguous => ambiguousOptions.length >= 2;

  const FaqMatchResult({
    this.match,
    this.ambiguousOptions = const [],
  });
}

class _FaqRule {
  final String faqId;
  final List<String> phrases;
  final List<List<String>> keywordGroups;
  final List<RegExp> patterns;
  final List<String> broadTerms;

  const _FaqRule({
    required this.faqId,
    this.phrases = const [],
    this.keywordGroups = const [],
    this.patterns = const [],
    this.broadTerms = const [],
  });
}

/// Rule-based engine, automatic English/Tamil detector, and conversation memory
/// for the NearFix standalone customer chatbot.
class NearFixChatbotEngine {
  static const String providersAssetPath = 'assets/demo_providers.json';
  static const String faqAssetPath = 'assets/nearfix_faq_en_ta.json';
  static const String servicesAssetPath =
      'assets/nearfix_service_categories_en_ta.json';

  static final RegExp _tamilScriptRegex = RegExp(r'[\u0B80-\u0BFF]');
  static final RegExp _latinScriptRegex = RegExp(r'[A-Za-z]');
  static final RegExp _unsupportedScriptRegex = RegExp(
    r'[\u0400-\u052F\u0600-\u06FF\u0900-\u0B7F\u0C00-\u0DFF\u0E00-\u0E7F\u3040-\u30FF\u4E00-\u9FFF\uAC00-\uD7AF]',
  );

  static const Set<String> _strongTanglishTokens = {
    'aagala',
    'agala',
    'aaguthu',
    'aguthu',
    'aagadhu',
    'agadhu',
    'aachu',
    'irukku',
    'iruku',
    'irukka',
    'irukaa',
    'iruka',
    'illai',
    'illa',
    'ille',
    'illaye',
    'varala',
    'varuthu',
    'varuma',
    'pogala',
    'poiduchu',
    'pochu',
    'mudiyuma',
    'mudiyala',
    'mudiyathu',
    'mudiyadhu',
    'venum',
    'vendum',
    'vendam',
    'thevai',
    'theva',
    'kidaikuma',
    'kidaikkuma',
    'kedaikuma',
    'kedaikkuma',
    'pannu',
    'pannunga',
    'pannanum',
    'pannalam',
    'pannalama',
    'panrathu',
    'seiyya',
    'sollu',
    'sollunga',
    'kaattunga',
    'theriyala',
    'theriyuma',
    'theriyum',
    'eriyala',
    'eriyuthu',
    'odala',
    'nikkuthu',
    'udanjiduchu',
    'odanjiduchu',
    'kettupochu',
    'ketupochu',
    'adachiduchu',
    'ozhuguthu',
    'enna',
    'ennathu',
    'eppadi',
    'epdi',
    'eppothu',
    'enga',
    'engai',
    'enoda',
    'ennoda',
    'enakku',
    'enaku',
    'ungalukku',
    'evlo',
    'evvalavu',
    'vandi',
    'thanni',
    'tanni',
    'kuzhai',
    'veetla',
    'veedu',
    'konjam',
    'romba',
    'aama',
    'nalla',
  };

  static const Set<String> _weakTanglishParticles = {
    'na',
    'la',
    'le',
    'nu',
    'kku',
    'oda',
    'da',
    'di',
    'inga',
    'anga',
    'unga',
    'neenga',
    'naanga',
    'naan',
    'yaar',
    'yaaru',
    'sari',
    'seri',
  };

  static const Set<String> _shortFollowUpWords = {
    'yes',
    'no',
    'ok',
    'okay',
    'not sure',
    'bike',
    'car',
    'phone',
    'providers',
    '1',
    '2',
    '3',
    '4',
    'ஆம்',
    'இல்லை',
    'சரி',
    'தெரியாது',
    'பைக்',
    'கார்',
    'கைபேசி',
  };

  final NearFixAiService? aiService;
  bool useAiIfAvailable;
  NearFixResponseSource lastResponseSource = NearFixResponseSource.ruleBasedFallback;

  NearFixChatbotEngine({
    NearFixAiService? aiService,
    this.useAiIfAvailable = true,
  }) : aiService = aiService ?? NearFixAiService.resolveDefault();

  bool get isUsingLiveAi => aiService != null && aiService!.isLiveBackend;

  String get aiStatusDescription {
    if (aiService == null) {
      return 'Rule-based engine active (no AI service attached)';
    }
    return aiService!.connectionDescription;
  }

  ChatLanguage language = ChatLanguage.en;
  ChatLanguage? _conversationLanguage;

  String? selectedServiceId;
  String? problemDetail;
  String? selectedArea;
  String chatStage = 'service';
  String? _pendingBatteryProblem;
  String? _pendingAmbiguousPlace;
  List<NearFixFaqItem> _pendingFaqCandidates = const [];
  String _stageBeforeFaqClarify = 'service';

  List<DemoProvider> demoProviders = [];
  bool providersLoaded = false;
  String? providerLoadError;

  List<DemoProvider> lastRecommendedProviders = const [];
  String? lastRecommendedServiceName;
  String? lastRecommendationIntro;
  String? lastRecommendationFooter;

  List<NearFixFaqItem> faqItems = [];
  bool faqLoaded = false;
  String? faqLoadError;

  List<NearFixServiceCategory> serviceCategories = [];
  bool servicesLoaded = false;
  String? serviceLoadError;

  /// Loads all local JSON assets using the provided [bundle] (or [rootBundle]).
  Future<void> loadAssets({AssetBundle? bundle}) async {
    final assetBundle = bundle ?? rootBundle;
    await Future.wait([
      _loadDemoProviders(assetBundle),
      _loadFaqs(assetBundle),
      _loadServiceCategories(assetBundle),
    ]);
  }

  /// Loads assets directly from raw JSON strings (useful for unit tests).
  void loadFromJsonStrings({
    String? providersJson,
    String? faqJson,
    String? servicesJson,
  }) {
    if (providersJson != null) {
      parseDemoProviders(providersJson);
    }
    if (faqJson != null) {
      parseFaqs(faqJson);
    }
    if (servicesJson != null) {
      parseServiceCategories(servicesJson);
    }
  }

  Future<void> _loadDemoProviders(AssetBundle bundle) async {
    try {
      final jsonText = await bundle.loadString(providersAssetPath);
      parseDemoProviders(jsonText);
    } catch (_) {
      providersLoaded = false;
      providerLoadError = providersAssetPath;
    }
  }

  void parseDemoProviders(String jsonText) {
    try {
      final decoded = jsonDecode(jsonText) as List<dynamic>;
      demoProviders = decoded
          .map((item) => DemoProvider.fromJson(item as Map<String, dynamic>))
          .toList();
      providersLoaded = true;
      providerLoadError = null;
    } catch (_) {
      providersLoaded = false;
      providerLoadError = providersAssetPath;
    }
  }

  Future<void> _loadFaqs(AssetBundle bundle) async {
    try {
      final jsonText = await bundle.loadString(faqAssetPath);
      parseFaqs(jsonText);
    } catch (_) {
      faqLoaded = false;
      faqLoadError = faqAssetPath;
    }
  }

  void parseFaqs(String jsonText) {
    try {
      final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
      final rawList = decoded['faq'] as List<dynamic>;
      faqItems = rawList
          .map((item) => NearFixFaqItem.fromJson(item as Map<String, dynamic>))
          .toList();
      faqLoaded = true;
      faqLoadError = null;
    } catch (_) {
      faqLoaded = false;
      faqLoadError = faqAssetPath;
    }
  }

  Future<void> _loadServiceCategories(AssetBundle bundle) async {
    try {
      final jsonText = await bundle.loadString(servicesAssetPath);
      parseServiceCategories(jsonText);
    } catch (_) {
      servicesLoaded = false;
      serviceLoadError = servicesAssetPath;
    }
  }

  void parseServiceCategories(String jsonText) {
    try {
      final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
      final rawList = decoded['services'] as List<dynamic>;
      serviceCategories = rawList
          .map(
            (item) =>
                NearFixServiceCategory.fromJson(item as Map<String, dynamic>),
          )
          .toList();
      servicesLoaded = true;
      serviceLoadError = null;
    } catch (_) {
      servicesLoaded = false;
      serviceLoadError = servicesAssetPath;
    }
  }

  List<String> get assetErrors => [
    ?providerLoadError,
    ?faqLoadError,
    ?serviceLoadError,
  ];

  bool get _isTamil => language == ChatLanguage.ta;

  String get appTitle => 'NearFix Assistant';

  String get inputHint =>
      'Describe your problem or ask in English / தமிழ்...';

  String get initialGreeting =>
      'Hello! Welcome to NearFix (Prototype). Ask a NearFix question or describe a repair problem in English.\n\n'
      'வணக்கம்! NearFix மாதிரி உதவியாளருக்கு வரவேற்கிறோம். தமிழில் கேள்வி கேட்கலாம் அல்லது பழுதுபார்ப்பு பிரச்சினையை விவரிக்கலாம்.';

  String get assetErrorBannerText => _conversationLanguage == null
      ? 'Could not load some local JSON files (${assetErrors.join(', ')}). '
            'சில உள்ளூர் JSON கோப்புகளை ஏற்ற முடியவில்லை.'
      : (_isTamil
            ? 'சில உள்ளூர் JSON கோப்புகளை ஏற்ற முடியவில்லை (${assetErrors.join(', ')}). மாதிரி பதில்கள் வரம்பிடப்பட்டிருக்கலாம்.'
            : 'Could not load some local JSON files (${assetErrors.join(', ')}). Some prototype data may be unavailable.');

  void resetRequest() {
    selectedServiceId = null;
    problemDetail = null;
    selectedArea = null;
    _pendingBatteryProblem = null;
    _pendingAmbiguousPlace = null;
    _pendingFaqCandidates = const [];
    _stageBeforeFaqClarify = 'service';
    chatStage = 'service';
    _conversationLanguage = null;
    _clearLastRecommendations();
  }

  void _clearLastRecommendations() {
    lastRecommendedProviders = const [];
    lastRecommendedServiceName = null;
    lastRecommendationIntro = null;
    lastRecommendationFooter = null;
  }

  /// Detects whether [rawMessage] is Tamil or English.
  ///
  /// - Any Tamil Unicode characters (`\u0B80-\u0BFF`) indicate Tamil, including
  ///   mixed messages like `"NearFix என்றால் என்ன?"`.
  /// - Short follow-ups such as `"Jaffna"` or `"ஆம்"` preserve the established
  ///   conversation language when one already exists.
  ChatLanguage detectMessageLanguage(String rawMessage) {
    final trimmed = rawMessage.trim();
    if (trimmed.isEmpty) {
      return _conversationLanguage ?? language;
    }

    final hasTamil = _tamilScriptRegex.hasMatch(trimmed);
    final hasLatin = _latinScriptRegex.hasMatch(trimmed);
    final ChatLanguage? scriptLanguage = hasTamil
        ? ChatLanguage.ta
        : (hasLatin ? ChatLanguage.en : null);

    final established = _conversationLanguage;
    if (established == null) {
      return scriptLanguage ?? ChatLanguage.en;
    }

    if (scriptLanguage == null || scriptLanguage == established) {
      return established;
    }

    // Preserve the established language on short follow-ups (such as "Jaffna"
    // in area stage, or 1-word confirmations like "ஆம்" / "ok") unless the
    // message clearly switches language.
    final lower = trimmed.toLowerCase();
    final words = trimmed
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (_shortFollowUpWords.contains(lower)) {
      return established;
    }

    final faqOutcome = evaluateFaqIntent(trimmed);
    final isFaqOrControl = faqOutcome.match != null ||
        faqOutcome.isAmbiguous ||
        _isEmergencySafetyMessage(lower) ||
        _isRestartCommand(lower);

    if (chatStage == 'area' &&
        !trimmed.contains('?') &&
        words.length <= 3 &&
        !isFaqOrControl) {
      return established;
    }

    if (!hasTamil &&
        words.length == 1 &&
        !isFaqOrControl &&
        detectServiceId(lower) == null) {
      return established;
    }

    return scriptLanguage;
  }

  String serviceDisplayName(String serviceId) {
    for (final category in serviceCategories) {
      if (category.id == serviceId) {
        return category.localizedName(language);
      }
    }
    const fallbackNames = {
      'mechanic': {
        'en': 'Mechanic / Vehicle Repair',
        'ta': 'வாகனப் பழுதுபார்ப்பு',
      },
      'plumber': {'en': 'Plumbing', 'ta': 'குழாய்ப்பணி'},
      'electrician': {'en': 'Electrical Work', 'ta': 'மின்சார வேலை'},
      'ac': {
        'en': 'Air-conditioning Repair',
        'ta': 'குளிரூட்டி பழுதுபார்ப்பு',
      },
      'locksmith': {'en': 'Locksmith', 'ta': 'பூட்டு வேலை'},
      'cleaning': {'en': 'Cleaning', 'ta': 'சுத்தம் செய்தல்'},
      'carpenter': {'en': 'Carpentry', 'ta': 'தச்சு வேலை'},
      'phone_repair': {'en': 'Phone Repair', 'ta': 'கைபேசி பழுதுபார்ப்பு'},
    };
    return fallbackNames[serviceId]?[language.name] ?? serviceId;
  }

  static String? _providerServiceToId(String rawService) {
    switch (rawService.trim().toLowerCase()) {
      case 'mechanic':
        return 'mechanic';
      case 'plumber':
        return 'plumber';
      case 'electrician':
        return 'electrician';
      case 'ac technician':
        return 'ac';
      case 'locksmith':
        return 'locksmith';
      case 'carpenter':
        return 'carpenter';
      case 'cleaning':
        return 'cleaning';
      case 'phone repair':
        return 'phone_repair';
      default:
        return null;
    }
  }

  bool _containsAny(String text, List<String> phrases) {
    return phrases.any((phrase) => text.contains(phrase));
  }

  String _normalizeText(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[?!.,:;"“”‘’()/-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _normalizeFaqQuery(String text) {
    var normalized = _normalizeText(text);
    const replacements = {
      'motorbike': 'motorcycle',
      'cell phone': 'mobile phone',
      'cellphone': 'mobile phone',
      'aircon': 'air conditioning',
      'air con': 'air conditioning',
      'labour': 'labor',
      'sign up': 'register',
      'signup': 'register',
      'log in': 'login',
      'sign in': 'login',
      'log out': 'logout',
      'sign out': 'logout',
      'technician': 'provider',
      'technicians': 'providers',
      'handyman': 'provider',
      'ஆப்': 'செயலி',
      'மதிப்புரை': 'கருத்து',
    };
    replacements.forEach((source, target) {
      if (RegExp(r'^[a-z\s]+$').hasMatch(source)) {
        normalized = normalized.replaceAll(
          RegExp('\\b${RegExp.escape(source)}\\b'),
          target,
        );
      } else {
        normalized = normalized.replaceAll(source, target);
      }
    });
    return normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  bool _containsFaqToken(String normalizedQuery, String token) {
    final t = token.trim().toLowerCase();
    if (t.isEmpty) return false;
    if (RegExp(r'^[a-z0-9\s]+$').hasMatch(t)) {
      return RegExp('\\b${RegExp.escape(t)}\\b').hasMatch(normalizedQuery);
    }
    return normalizedQuery.contains(t);
  }

  bool _isOutOfScopeTopic(String text) {
    return _containsAny(text, [
      'helplink',
      'rescuelink',
      'ngo',
      'donor',
      'donors',
      'donation',
      'volunteer',
      'volunteers',
      'disaster relief',
      'flood relief',
      'charity',
      'sos workflow',
      'commission rate',
      'weather',
      'forecast',
      'cricket',
      'football',
      'movie',
      'recipe',
      'cook rice',
      'flight',
      'hotel',
      'train ticket',
      'capital of',
      'gold price',
      'stock market',
      'homework',
      'write a poem',
      'tell me a joke',
      'நன்கொடை',
      'பேரிடர்',
      'தன்னார்வலர்',
      'வானிலை',
      'கிரிக்கெட்',
      'சினிமா',
      'சமையல்',
      'விமான',
      'ஹோட்டல்',
      'டிக்கெட்',
    ]);
  }

  bool _isEmergencySafetyMessage(String text) {
    return _containsAny(text, [
          'immediate danger',
          'electric shock',
          'fire',
          'serious injury',
          'sparks',
          'உடனடி ஆபத்து',
          'மின்சார ஆபத்து',
          'மின்சார அதிர்ச்சி',
          'கடுமையான காயம்',
        ]) ||
        RegExp(r'\bemergency\b').hasMatch(text) ||
        RegExp(r'(^|\s)தீ(\s|$)').hasMatch(text);
  }

  static final List<_FaqRule> _faqRules = [
    _FaqRule(
      faqId: 'NF-FAQ-043',
      phrases: [
        'immediate danger',
        'what should i do in immediate danger',
        'electric shock',
        'serious injury',
        'உடனடி ஆபத்து',
        'ஆபத்து ஏற்பட்டால்',
      ],
      keywordGroups: [
        ['fire', 'emergency'],
        ['danger', 'help'],
      ],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-042',
      phrases: [
        'need help now',
        'urgent feature',
        'urgent service',
        'priority request',
        'அவசரமாக உதவி',
        'அவசர சேவை',
      ],
      keywordGroups: [
        ['urgent', 'nearfix'],
        ['அவசர', 'வசதி'],
      ],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-028',
      phrases: [
        'confirm my booking',
        'create or confirm',
        'book now',
        'book for me',
        'create a booking',
        'make a booking now',
        'book right now',
        'confirm booking now',
        'இப்போது எனக்காக முன்பதிவு',
        'இப்போது முன்பதிவு செய்ய முடியுமா',
      ],
      keywordGroups: [
        ['book', 'now'],
        ['confirm', 'booking'],
        ['இப்போது', 'முன்பதிவு'],
      ],
      broadTerms: ['booking', 'tell me about booking', 'booking info', 'முன்பதிவு'],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-025',
      phrases: [
        'how do i book',
        'how to book',
        'how will i book',
        'can i book',
        'how do i request a service',
        'how to request a service',
        'how do i request',
        'how to request',
        'steps to book',
        'how booking works',
        'booking process',
        'request a service',
        'எப்படி முன்பதிவு',
        'முன்பதிவு எப்படி',
        'முன்பதிவு செய்வது எப்படி',
        'சேவையை எப்படி முன்பதிவு',
        'சேவை கோருவது எப்படி',
        'எப்படி book',
      ],
      keywordGroups: [
        ['how', 'book'],
        ['how', 'request', 'service'],
        ['சேவை', 'முன்பதிவு', 'எப்படி'],
      ],
      patterns: [
        RegExp(
          r'\b(how|steps)\b.*\b(book|booking|request)\b.*\b(service|repair|nearfix|mechanic|plumber|electrician|ac|locksmith|carpenter|cleaning|phone)\b',
        ),
      ],
      broadTerms: ['booking', 'tell me about booking', 'booking info', 'முன்பதிவு'],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-026',
      phrases: [
        'after i send a service request',
        'after sending a request',
        'what happens after i send',
        'next step after booking',
        'கோரிக்கை அனுப்பிய பிறகு',
      ],
      keywordGroups: [
        ['after', 'send', 'request'],
        ['கோரிக்கை', 'பிறகு'],
      ],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-027',
      phrases: [
        'booking statuses',
        'request statuses',
        'what are the statuses',
        'order status types',
        'கோரிக்கையின் நிலைகள்',
      ],
      keywordGroups: [
        ['booking', 'status'],
        ['request', 'status'],
        ['கோரிக்கை', 'நிலைகள்'],
      ],
      broadTerms: ['booking', 'tell me about booking', 'booking info', 'முன்பதிவு'],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-033',
      phrases: [
        'status of my real job',
        'check the status',
        'check my booking status',
        'track my booking',
        'check my real booking',
        'உண்மையான சேவைக் கோரிக்கையின் நிலை',
      ],
      keywordGroups: [
        ['check', 'real', 'job'],
        ['track', 'my', 'job'],
        ['உண்மையான', 'நிலை'],
      ],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-029',
      phrases: [
        'call or chat',
        'contact the provider',
        'contact a provider',
        'contact provider',
        'provider phone number',
        'call the provider',
        'chat with the provider',
        'message provider',
        'வழங்குநரிடம் அழைக்க',
        'வழங்குநரை தொடர்பு',
        'தொடர்பு கொள்ள முடியுமா',
      ],
      keywordGroups: [
        ['call', 'provider'],
        ['chat', 'provider'],
        ['contact', 'provider'],
        ['வழங்குந', 'தொடர்பு'],
      ],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-030',
      phrases: [
        'cancel my service request',
        'cancel a booking',
        'cancel booking',
        'cancellation policy',
        'cancel request',
        'how to cancel',
        'can i cancel',
        'ரத்து செய்ய முடியுமா',
        'ரத்து செய்யலாமா',
        'ரத்து செய்யும்',
      ],
      keywordGroups: [
        ['cancel', 'request'],
        ['cancel', 'booking'],
        ['ரத்து', 'கோரிக்கை'],
      ],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-031',
      phrases: [
        'previous bookings',
        'booking history',
        'past requests',
        'past bookings',
        'old bookings',
        'முந்தைய சேவைக் கோரிக்கைகள்',
      ],
      keywordGroups: [
        ['previous', 'booking'],
        ['past', 'request'],
        ['முந்தைய', 'கோரிக்கை'],
      ],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-032',
      phrases: [
        'rate or review',
        'leave a review',
        'write a review',
        'give a rating',
        'leave feedback',
        'reviews',
        'மதிப்பீடு அல்லது கருத்து',
        'கருத்து தரலாமா',
      ],
      keywordGroups: [
        ['rate', 'provider'],
        ['review', 'provider'],
        ['leave', 'review'],
        ['மதிப்பீடு', 'கருத்து'],
      ],
      broadTerms: ['provider ratings', 'ratings', 'மதிப்பீடு'],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-017',
      phrases: [
        'ratings and availability',
        'provider availability',
        'check availability',
        'see availability',
        'available right now',
        'anyone available now',
        'மதிப்பீடும் கிடைப்புத் தன்மையும்',
        'கிடைப்புத் தன்மை',
      ],
      keywordGroups: [
        ['provider', 'availability'],
        ['see', 'rating'],
        ['கிடைப்பு', 'தன்மை'],
      ],
      broadTerms: ['provider ratings', 'ratings', 'மதிப்பீடு'],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-018',
      phrases: [
        'suggested providers real',
        'are providers real',
        'are the providers real',
        'real businesses',
        'real providers',
        'fictional providers',
        'real or demo',
        'are they fake',
        'வழங்குநர்கள் உண்மையானவர்களா',
        'கற்பனைப் பதிவுகள்',
      ],
      keywordGroups: [
        ['provider', 'real'],
        ['providers', 'real'],
        ['வழங்குநர்கள்', 'உண்மை'],
      ],
      broadTerms: ['tell me about providers', 'provider info', 'provider details', 'வழங்குநர் விவரம்'],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-019',
      phrases: [
        'no provider is found',
        'no provider found',
        'no provider is available',
        'no providers available',
        'if no providers are found',
        'what if nobody is found',
        'nobody available',
        'no match found',
        'வழங்குநர் யாரும் கிடைக்காவிட்டால்',
      ],
      keywordGroups: [
        ['no', 'provider', 'found'],
        ['nobody', 'available'],
        ['யாரும்', 'கிடைக்காவிட்டால்'],
      ],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-020',
      phrases: [
        'are providers verified',
        'verified providers',
        'background check',
        'trusted providers',
        'சரிபார்க்கப்பட்டவர்களா',
      ],
      keywordGroups: [
        ['provider', 'verified'],
        ['providers', 'verified'],
        ['சரிபார்க்கப்பட்ட'],
      ],
      broadTerms: ['tell me about providers', 'provider info', 'provider details', 'வழங்குநர் விவரம்'],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-016',
      phrases: [
        'find nearby providers',
        'how will nearfix find',
        'how does nearfix match',
        'how do you find providers',
        'how are providers matched',
        'எப்படி கண்டுபிடிக்கும்',
      ],
      keywordGroups: [
        ['how', 'find', 'provider'],
        ['how', 'find', 'providers'],
        ['வழங்குந', 'எப்படி', 'கண்டுபிடிக்கும்'],
      ],
      broadTerms: ['tell me about providers', 'provider info', 'provider details', 'வழங்குநர் விவரம்'],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-023',
      phrases: [
        'track a provider',
        'live tracking',
        'map tracking',
        'track provider live',
        'see provider on map',
        'நேரடியாகக் கண்காணிக்க',
      ],
      keywordGroups: [
        ['track', 'provider'],
        ['tracking', 'provider'],
        ['gps', 'tracking'],
        ['live', 'map'],
        ['நேரடியாக', 'கண்காணிக்க'],
      ],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-024',
      phrases: [
        'arrival time',
        'exact eta',
        'how long will they take',
        'when will the provider arrive',
        'how soon will they arrive',
        'வரும் துல்லியமான நேரம்',
        'வருகை நேரம்',
      ],
      keywordGroups: [
        ['when', 'arrive'],
        ['எப்போது', 'வருவார்'],
      ],
      patterns: [RegExp(r'\beta\b')],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-022',
      phrases: [
        'deny location',
        'location permission',
        'without gps',
        'refuse location',
        'without location access',
        'இருப்பிட அனுமதியை மறுத்தால்',
      ],
      keywordGroups: [
        ['deny', 'location'],
        ['refuse', 'gps'],
        ['அனுமதி', 'மறுத்தால்'],
      ],
      broadTerms: ['location', 'location info', 'tell me about location', 'இருப்பிடம்'],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-044',
      phrases: [
        'who can see my location',
        'contact details',
        'privacy',
        'private data',
        'personal data',
        'is my info safe',
        'இருப்பிடமும் தொடர்பு விவரங்களும் யாருக்குத் தெரியும்',
        'யாருக்குத் தெரியும்',
        'தனிப்பட்ட தகவல்',
      ],
      keywordGroups: [
        ['who', 'see', 'location'],
        ['who', 'see', 'contact'],
        ['இருப்பிட', 'யார்'],
      ],
      broadTerms: ['location', 'location info', 'tell me about location', 'இருப்பிடம்'],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-021',
      phrases: [
        'share my location',
        'how does location work',
        'use gps',
        'enter my location',
        'how do i give my area',
        'இருப்பிடத்தை எப்படி பகிர்வது',
        'இருப்பிடத்தை பகிர்வது எப்படி',
      ],
      keywordGroups: [
        ['share', 'location'],
        ['enter', 'location'],
        ['இருப்பிட', 'பகிர்வ'],
      ],
      broadTerms: ['location', 'location info', 'tell me about location', 'இருப்பிடம்'],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-035',
      phrases: [
        'labor and material',
        'cost breakdown',
        'quotation',
        'வேலைக் கூலியும் பொருட் செலவும்',
      ],
      keywordGroups: [
        ['labor', 'material'],
        ['கூலி', 'பொருட் செலவு'],
      ],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-036',
      phrases: [
        'subscription',
        'charge customers',
        'platform fee',
        'service fee',
        'monthly fee',
        'மாதச் சந்தா',
        'கட்டணம் வசூலிக்குமா',
      ],
      keywordGroups: [
        ['nearfix', 'charge'],
        ['customer', 'fee'],
        ['சந்தா', 'வசூலிக்குமா'],
      ],
      broadTerms: ['fees', 'charges', 'கட்டணம்'],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-039',
      phrases: [
        'pay online',
        'payment gateway',
        'online payment',
        'can i pay',
        'pay by card',
        'இணையத்தில் பணம் செலுத்த',
        'பணம் செலுத்த முடியுமா',
      ],
      keywordGroups: [
        ['pay', 'online'],
        ['பணம்', 'செலுத்'],
      ],
      broadTerms: ['payment', 'payments'],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-040',
      phrases: [
        'receive a receipt',
        'get a receipt',
        'receipt',
        'invoice',
        'get a bill',
        'ரசீது கிடைக்குமா',
        'ரசீது',
      ],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-041',
      phrases: [
        'refund',
        'dispute policy',
        'money back',
        'file a complaint',
        'பணத்தைத் திரும்ப',
        'பணத்திருப்பு',
        'புகார் அளிக்கும் விதி',
      ],
      keywordGroups: [
        ['refund', 'policy'],
        ['பணம்', 'திரும்ப'],
      ],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-034',
      phrases: [
        'how much will a repair cost',
        'how much does a repair cost',
        'how much does it cost',
        'how much will it cost',
        'repair cost',
        'service cost',
        'repair price',
        'nearfix pricing',
        'எவ்வளவு செலவாகும்',
        'பழுதுபார்ப்பு செலவு',
        'கட்டணம் எவ்வளவு',
      ],
      keywordGroups: [
        ['how', 'much', 'cost'],
        ['repair', 'cost'],
        ['service', 'cost'],
        ['பழுதுபார்ப்பு', 'செலவு'],
      ],
      patterns: [
        RegExp(
          r'\b(repair|service|fix|nearfix|mechanic|plumber|electrician|ac|locksmith|carpenter|cleaning|phone)\b.*\b(cost|price|prices|charge|charges)\b',
        ),
        RegExp(
          r'\b(cost|price|prices|charge|charges)\b.*\b(repair|service|fix|nearfix|mechanic|plumber|electrician|ac|locksmith|carpenter|cleaning|phone)\b',
        ),
      ],
      broadTerms: ['fees', 'charges', 'கட்டணம்'],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-012',
      phrases: [
        'what mechanic problems',
        'mechanic problems can i report',
        'vehicle problems can i report',
        'வாகனப் பழுதில் என்ன பிரச்சினை',
      ],
      keywordGroups: [
        ['what', 'mechanic', 'problems'],
        ['what', 'vehicle', 'problems'],
        ['examples', 'mechanic'],
        ['வாகன', 'என்ன', 'பிரச்சினை'],
      ],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-013',
      phrases: [
        'what plumbing problems',
        'plumbing problems can i report',
        'குழாய்ப்பணிக்காக என்ன பிரச்சினை',
      ],
      keywordGroups: [
        ['what', 'plumbing', 'problems'],
        ['examples', 'plumbing'],
        ['குழாய்ப்பணி', 'என்ன', 'பிரச்சினை'],
      ],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-014',
      phrases: [
        'send a photo',
        'upload photo',
        'upload a picture',
        'attach image',
        'புகைப்படத்தை அனுப்ப',
        'புகைப்படம்',
      ],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-015',
      phrases: [
        'diagnose a repair',
        'diagnose accurately',
        'find exact fault',
        'பழுதை உறுதியாகக் கண்டறியுமா',
      ],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-011',
      phrases: [
        'describe my service problem',
        'how do i describe',
        'how to report a problem',
        'how to explain my problem',
        'பிரச்சினையை எப்படி விளக்குவது',
      ],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-009',
      phrases: [
        'register as a customer',
        'how do i register',
        'create an account',
        'create account',
        'how to register',
        'வாடிக்கையாளராக எப்படி பதிவு',
        'எப்படி பதிவு செய்வது',
      ],
      keywordGroups: [
        ['how', 'register'],
        ['எப்படி', 'பதிவு'],
      ],
      broadTerms: ['account', 'account info', 'tell me about account', 'கணக்கு'],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-010',
      phrases: [
        'update my profile',
        'edit my profile',
        'change profile',
        'logout',
        'சுயவிவரத்தை மாற்ற',
        'வெளியேற',
      ],
      broadTerms: ['account', 'account info', 'tell me about account', 'கணக்கு'],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-008',
      phrases: [
        'need an account',
        'do i need account',
        'account required',
        'login required',
        'without an account',
        'கணக்கு உருவாக்க வேண்டுமா',
        'கணக்கு தேவையா',
      ],
      keywordGroups: [
        ['need', 'account'],
        ['without', 'account'],
        ['கணக்கு', 'வேண்டுமா'],
      ],
      broadTerms: ['account', 'account info', 'tell me about account', 'கணக்கு'],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-007',
      phrases: [
        'which languages',
        'what languages',
        'languages does the chatbot support',
        'supported languages',
        'tanglish',
        'tamil support',
        'speak tamil',
        'எந்த மொழிகளை ஆதரிக்கும்',
        'மொழிகள்',
      ],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-006',
      phrases: [
        'what can this chatbot do',
        'what can you do',
        'what can the bot do',
        'how can you help me',
        'prototype limits',
        'limitations',
        'உதவியாளர் என்ன செய்யும்',
        'என்ன செய்ய முடியும்',
      ],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-005',
      phrases: [
        'complete nearfix app available',
        'is nearfix live',
        'is the app live',
        'is the full app available',
        'app available now',
        'can i download nearfix',
        'is nearfix ready',
        'செயலி இப்போது கிடைக்கிறதா',
        'முழு செயலி தயாரா',
        'செயலி வெளியிடப்பட்டதா',
      ],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-004',
      phrases: [
        'what services are planned',
        'what services are available',
        'what services',
        'which services',
        'service categories',
        'services offered',
        'list of services',
        'என்னென்ன சேவைகள்',
        'சேவைகள் உள்ளன',
        'சேவை வகைகள்',
        'கிடைக்கும் சேவைகள்',
      ],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-003',
      phrases: [
        'what problems does nearfix solve',
        'why nearfix',
        'why use nearfix',
        'purpose of nearfix',
        'எந்தப் பிரச்சினையைத் தீர்க்கிறது',
      ],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-002',
      phrases: [
        'who is nearfix for',
        'who uses nearfix',
        'who can use nearfix',
        'nearfix யாருக்கானது',
        'யாருக்கானது',
        'யார் பயன்படுத்தலாம்',
      ],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-001',
      phrases: [
        'what is nearfix',
        'what does nearfix do',
        'tell me about nearfix',
        'about nearfix',
        'explain nearfix',
        'how does nearfix work',
        'what is this app',
        'nearfix என்றால் என்ன',
        'nearfix பற்றி',
        'nearfix எதற்கு',
        'nearfix எப்படி செயல்படும்',
      ],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-045',
      phrases: [
        'internet is unavailable',
        'no internet',
        'offline',
        'network failure',
        'without internet',
        'இணையம் இல்லாவிட்டால்',
        'இணையம் இல்லாமல்',
      ],
    ),
    _FaqRule(
      faqId: 'NF-FAQ-046',
      phrases: [
        'guarantee provider arrival',
        'guarantee arrival',
        'guaranteed',
        'is arrival guaranteed',
        'கண்டிப்பாக வருவார்',
      ],
    ),
  ];

  NearFixFaqItem? _findFaqById(String id) {
    for (final item in faqItems) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Evaluates [rawInput] against NearFix FAQs using normalized text, synonyms,
  /// keyword groups, regex patterns, and ambiguity detection.
  FaqMatchResult evaluateFaqIntent(String rawInput) {
    if (!faqLoaded || faqItems.isEmpty) return const FaqMatchResult();

    final normalized = _normalizeText(rawInput);
    if (normalized.isEmpty || _isOutOfScopeTopic(normalized)) {
      return const FaqMatchResult();
    }

    final faqQuery = _normalizeFaqQuery(rawInput);

    // 1. Exact question match in either supported language.
    for (final item in faqItems) {
      final enQ = _normalizeText(item.question['en'] ?? '');
      final taQ = _normalizeText(item.question['ta'] ?? '');
      if (normalized == enQ || normalized == taQ) {
        return FaqMatchResult(match: item);
      }
    }

    // 2. Score curated intent aliases, keyword groups, patterns, and broad terms.
    final scores = <String, int>{};

    for (final rule in _faqRules) {
      var ruleScore = 0;

      for (final phrase in rule.phrases) {
        final normPhrase = _normalizeFaqQuery(phrase);
        if (normPhrase.isNotEmpty && faqQuery.contains(normPhrase)) {
          final wordCount = normPhrase.split(' ').length;
          final candidate = 100 + (wordCount * 4).clamp(4, 24);
          if (candidate > ruleScore) ruleScore = candidate;
        }
      }

      for (final group in rule.keywordGroups) {
        if (group.isNotEmpty &&
            group.every((token) => _containsFaqToken(faqQuery, token))) {
          final candidate = 92 + group.length * 4;
          if (candidate > ruleScore) ruleScore = candidate;
        }
      }

      for (final regex in rule.patterns) {
        if (regex.hasMatch(faqQuery)) {
          if (95 > ruleScore) ruleScore = 95;
        }
      }

      for (final term in rule.broadTerms) {
        final normTerm = _normalizeFaqQuery(term);
        if (normTerm.isNotEmpty && _containsFaqToken(faqQuery, normTerm)) {
          if (60 > ruleScore) ruleScore = 60;
        }
      }

      if (ruleScore > 0) {
        final existing = scores[rule.faqId] ?? 0;
        if (ruleScore > existing) {
          scores[rule.faqId] = ruleScore;
        }
      }
    }

    if (scores.isNotEmpty) {
      final ranked = scores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topEntry = ranked.first;
      final topScore = topEntry.value;

      if (topScore >= 55) {
        final threshold = topScore < 100 ? 12 : 4;
        final closeCandidates = <NearFixFaqItem>[];
        for (final entry in ranked) {
          if (topScore - entry.value <= threshold) {
            final item = _findFaqById(entry.key);
            if (item != null) closeCandidates.add(item);
          }
          if (closeCandidates.length >= 3) break;
        }

        if (closeCandidates.length >= 2 && topScore < 100) {
          return FaqMatchResult(ambiguousOptions: closeCandidates);
        }

        final winner = _findFaqById(topEntry.key);
        if (winner != null) {
          return FaqMatchResult(match: winner);
        }
      }
    }

    // 3. Question-shaped token overlap fallback against FAQ questions.
    final looksLikeQuestion = rawInput.contains('?') ||
        RegExp(
          r'^(what|how|who|when|where|why|can|do|does|is|are|will)\b',
        ).hasMatch(normalized) ||
        _containsAny(normalized, ['என்ன', 'எப்படி', 'யார்', 'முடியுமா', 'உள்ளதா']);

    if (!looksLikeQuestion) return const FaqMatchResult();

    const stopWords = {
      'a',
      'an',
      'the',
      'is',
      'are',
      'do',
      'does',
      'can',
      'will',
      'i',
      'my',
      'me',
      'to',
      'of',
      'in',
      'for',
      'or',
      'and',
      'with',
      'what',
      'how',
      'who',
      'if',
      'nearfix',
    };
    final inputTokens = faqQuery
        .split(' ')
        .where((token) => token.length > 1 && !stopWords.contains(token))
        .toSet();
    if (inputTokens.isEmpty) return const FaqMatchResult();

    final overlapCandidates = <MapEntry<NearFixFaqItem, double>>[];

    for (final item in faqItems) {
      double bestItemScore = 0;
      for (final lang in ['en', 'ta']) {
        final qNorm = _normalizeFaqQuery(item.question[lang] ?? '');
        final qTokens = qNorm
            .split(' ')
            .where((token) => token.length > 1 && !stopWords.contains(token))
            .toSet();
        if (qTokens.isEmpty) continue;

        final overlap = inputTokens.intersection(qTokens).length;
        final score = overlap / qTokens.length;
        if (overlap >= 2 && score >= 0.65 && score > bestItemScore) {
          bestItemScore = score;
        }
      }
      if (bestItemScore > 0) {
        overlapCandidates.add(MapEntry(item, bestItemScore));
      }
    }

    if (overlapCandidates.isEmpty) return const FaqMatchResult();

    overlapCandidates.sort((a, b) => b.value.compareTo(a.value));
    final bestOverlap = overlapCandidates.first.value;
    final closeOverlap = overlapCandidates
        .where((entry) => bestOverlap - entry.value <= 0.1)
        .take(3)
        .map((entry) => entry.key)
        .toList();

    if (closeOverlap.length >= 2) {
      return FaqMatchResult(ambiguousOptions: closeOverlap);
    }
    return FaqMatchResult(match: overlapCandidates.first.key);
  }

  /// Matches NearFix FAQ intents before service problem classification.
  NearFixFaqItem? matchFaqIntent(String rawInput) {
    return evaluateFaqIntent(rawInput).match;
  }

  bool _looksLikeFaqLoadNeeded(String rawInput) {
    final normalized = _normalizeText(rawInput);
    return rawInput.contains('?') ||
        RegExp(
          r'^(what|how|who|when|where|why|can|do|does|is|are|will)\b',
        ).hasMatch(normalized) ||
        _containsAny(normalized, ['nearfix', 'faq', 'என்ன', 'எப்படி', 'முன்பதிவு']);
  }

  bool _mentionsBattery(String text) {
    return RegExp(r'\bbattery\b').hasMatch(text) || text.contains('பேட்டரி');
  }

  bool _mentionsVehicle(String text) {
    return _containsAny(text, [
          'mechanic',
          'motorcycle',
          'bike',
          'vehicle',
          'engine',
          'tyre',
          'tire',
          'roadside',
          'scooter',
          'மெக்கானிக்',
          'வாகனம்',
          'மோட்டார் சைக்கிள்',
          'பைக்',
          'கார்',
          'டயர்',
          'என்ஜின்',
          'ஸ்கூட்டர்',
        ]) ||
        RegExp(r'\bcar\b').hasMatch(text);
  }

  bool _mentionsPhone(String text) {
    return _containsAny(text, [
      'phone repair',
      'mobile phone',
      'smartphone',
      'phone screen',
      'charging port',
      'phone',
      'mobile',
      'கைபேசி',
      'தொலைபேசி',
      'திரை',
      'மொபைல்',
      'ஸ்மார்ட்போன்',
    ]);
  }

  bool _isAmbiguousBattery(String text) {
    return _mentionsBattery(text) &&
        !_mentionsVehicle(text) &&
        !_mentionsPhone(text);
  }

  /// Detects a service ID using loaded `nearfix_service_categories_en_ta.json`
  /// phrases and safe word-boundary rules.
  String? detectServiceId(String rawText) {
    final text = rawText.trim().toLowerCase();
    if (text.isEmpty) return null;

    if (_isAmbiguousBattery(text)) {
      return null;
    }

    // Check specific multi-word / boundary disambiguations first.
    if (_containsAny(text, [
      'locksmith',
      'locked out',
      'door lock',
      'lost key',
      'lost my key',
      'key stuck',
      'கதவுப் பூட்டு',
      'பூட்டு',
      'சாவி',
    ])) {
      return 'locksmith';
    }

    if (_containsAny(text, [
          'air conditioner',
          'air conditioning',
          'aircon',
          'ac repair',
          'not cooling',
          'குளிரூட்டி',
          'ஏசி',
          'குளிர்விக்கவில்லை',
        ]) ||
        RegExp(r'\bac\b').hasMatch(text)) {
      return 'ac';
    }

    if (_mentionsPhone(text)) {
      return 'phone_repair';
    }

    if (_mentionsVehicle(text)) {
      return 'mechanic';
    }

    // Check phrases loaded from nearfix_service_categories_en_ta.json.
    for (final category in serviceCategories) {
      final enPhrases = category.phrasesForRuleMatching['en'] ?? const [];
      for (final phrase in enPhrases) {
        final normalizedPhrase = phrase.trim().toLowerCase();
        if (normalizedPhrase.isEmpty || normalizedPhrase == 'ac') continue;
        final boundaryRegex = RegExp(
          '\\b${RegExp.escape(normalizedPhrase)}\\b',
        );
        if (boundaryRegex.hasMatch(text)) {
          return category.id;
        }
      }
      final taPhrases = category.phrasesForRuleMatching['ta'] ?? const [];
      for (final phrase in taPhrases) {
        final normalizedPhrase = phrase.trim().toLowerCase();
        if (normalizedPhrase.isEmpty) continue;
        if (text.contains(normalizedPhrase)) {
          return category.id;
        }
      }
    }

    // Built-in fallbacks in case service categories JSON failed to load or
    // additional synonyms are used.
    if (_containsAny(text, [
      'plumber',
      'plumbing',
      'water leak',
      'leaking',
      'pipe',
      'tap',
      'sink',
      'toilet',
      'drain',
      'no water',
      'water tank',
      'குழாய்ப்பணி',
      'குழாய்',
      'நீர் கசிவு',
      'தண்ணீர் கசிவு',
      'தண்ணீர் வரவில்லை',
      'திறப்பான்',
      'கழிப்பறை',
      'நீர்த்தொட்டி',
    ])) {
      return 'plumber';
    }

    if (_containsAny(text, [
      'electrician',
      'electrical',
      'wiring',
      'socket',
      'switch',
      'electricity',
      'power problem',
      'no power',
      'மின்சாரம்',
      'மின்கம்பி',
      'மின் இணைப்பு',
      'சாக்கெட்',
      'சுவிட்ச்',
    ])) {
      return 'electrician';
    }

    if (_containsAny(text, [
      'cleaning',
      'cleaner',
      'clean house',
      'office cleaning',
      'home cleaning',
      'சுத்தம்',
      'துப்புரவு',
    ])) {
      return 'cleaning';
    }

    if (_containsAny(text, [
      'carpenter',
      'carpentry',
      'furniture',
      'wooden door',
      'woodwork',
      'cupboard',
      'தச்சு',
      'தச்சர்',
      'மர வேலை',
      'மரச்சாமான்',
      'மரக் கதவு',
    ])) {
      return 'carpenter';
    }

    return null;
  }

  bool _describesProblem(String text) {
    return _containsAny(text, [
      'not starting',
      "won't start",
      'wont start',
      'not working',
      'not charging',
      'broken',
      'problem with',
      'battery problem',
      'dead',
      'leak',
      'leaking',
      'drip',
      'dripping',
      'keeps dripping',
      'blocked',
      'jammed',
      'stuck',
      'no water',
      'not cooling',
      'no power',
      'sparks',
      'damaged',
      'stopped',
      'lost my key',
      'lost key',
      'locked out',
      'puncture',
      'flat tyre',
      'flat tire',
      'overheating',
      'breakdown',
      'ஆகவில்லை',
      'இல்லை',
      'வரவில்லை',
      'பழுது',
      'கசிவு',
      'கசிகிறது',
      'சொட்டுகிறது',
      'சொட்டு',
      'அடைப்பு',
      'அடைந்தது',
      'உடைந்தது',
      'தொலைந்தது',
      'பிரச்சினை',
      'கோளாறு',
      'குளிர்விக்கவில்லை',
      'சார்ஜ் ஆகவில்லை',
      'வேலை செய்யவில்லை',
      'சேதம்',
      'பழுதடைந்தது',
    ]);
  }

  // Ambiguous place names across multiple districts in Sri Lanka.
  static const Map<String, List<String>> _ambiguousPlaceDistricts = {
    'kochchikade': ['Colombo', 'Gampaha'],
    'கொச்சிக்கடை': ['Colombo', 'Gampaha'],
    'madampe': ['Puttalam', 'Ratnapura'],
    'மாதம்பை': ['Puttalam', 'Ratnapura'],
    'pannala': ['Kurunegala', 'Gampaha'],
    'பன்னலை': ['Kurunegala', 'Gampaha'],
    'aluthgama': ['Kalutara', 'Kandy'],
    'அளுத்கம': ['Kalutara', 'Kandy'],
    'katuwana': ['Hambantota', 'Colombo'],
    'கட்டுவன': ['Hambantota', 'Colombo'],
    'maradana': ['Colombo', 'Kalutara'],
    'மருதானை': ['Colombo', 'Kalutara'],
  };

  static String _districtToTamil(String englishDistrict) {
    const map = {
      'Colombo': 'கொழும்பு',
      'Gampaha': 'கம்பஹா',
      'Kalutara': 'களுத்துறை',
      'Kandy': 'கண்டி',
      'Matale': 'மாத்தளை',
      'Nuwara Eliya': 'நுவரெலியா',
      'Galle': 'காலி',
      'Matara': 'மாத்தறை',
      'Hambantota': 'அம்பாந்தோட்டை',
      'Jaffna': 'யாழ்ப்பாணம்',
      'Kilinochchi': 'கிளிநொச்சி',
      'Mannar': 'மன்னார்',
      'Vavuniya': 'வவுனியா',
      'Mullaitivu': 'முல்லைத்தீவு',
      'Batticaloa': 'மட்டக்களப்பு',
      'Ampara': 'அம்பாறை',
      'Trincomalee': 'திருகோணமலை',
      'Kurunegala': 'குருநாகல்',
      'Puttalam': 'புத்தளம்',
      'Anuradhapura': 'அனுராதபுரம்',
      'Polonnaruwa': 'பொலன்னறுவை',
      'Badulla': 'பதுளை',
      'Monaragala': 'மொணராகலை',
      'Ratnapura': 'இரத்தினபுரி',
      'Kegalle': 'கேகாலை',
    };
    return map[englishDistrict] ?? englishDistrict;
  }

  List<String>? _checkAmbiguousPlace(String lower) {
    for (final entry in _ambiguousPlaceDistricts.entries) {
      final key = entry.key;
      final regex = RegExp('(^|\\s|,)$key(\$|\\s|,)');
      if (regex.hasMatch(lower) || lower == key) {
        final districts = entry.value;
        final alreadyHasDistrict = districts.any((d) {
          final dLower = d.toLowerCase();
          final dTa = _districtToTamil(d).toLowerCase();
          return lower.contains(dLower) || lower.contains(dTa);
        });
        if (!alreadyHasDistrict) {
          return districts;
        }
      }
    }
    return null;
  }

  // Normalizes location names with English & Tamil aliases.
  String _normalizeArea(String area) {
    final text = area.trim().toLowerCase();
    if (text.contains('nallur') || text.contains('நல்லூர்')) {
      return 'nallur';
    }
    if (text.contains('chavakachcheri') || text.contains('சாவகச்சேரி')) {
      return 'chavakachcheri';
    }
    if (text.contains('point pedro') || text.contains('பருத்தித்துறை')) {
      return 'point pedro';
    }
    if (text.contains('jaffna') || text.contains('யாழ்ப்பாணம்')) {
      return 'jaffna';
    }
    if (text.contains('colombo') || text.contains('கொழும்பு')) {
      return 'colombo';
    }
    if (text.contains('kandy') || text.contains('கண்டி')) {
      return 'kandy';
    }
    if (text.contains('galle') || text.contains('காலி')) {
      return 'galle';
    }
    if (text.contains('gampaha') || text.contains('கம்பஹா')) {
      return 'gampaha';
    }
    if (text.contains('kalutara') || text.contains('களுத்துறை')) {
      return 'kalutara';
    }
    if (text.contains('matara') || text.contains('மாத்தறை')) {
      return 'matara';
    }
    if (text.contains('batticaloa') || text.contains('மட்டக்களப்பு')) {
      return 'batticaloa';
    }
    if (text.contains('trincomalee') || text.contains('திருகோணமலை')) {
      return 'trincomalee';
    }
    if (text.contains('vavuniya') || text.contains('வவுனியா')) {
      return 'vavuniya';
    }
    if (text.contains('kilinochchi') || text.contains('கிளிநொச்சி')) {
      return 'kilinochchi';
    }
    if (text.contains('mannar') || text.contains('மன்னார்')) {
      return 'mannar';
    }
    if (text.contains('mullaitivu') || text.contains('முல்லைத்தீவு')) {
      return 'mullaitivu';
    }
    if (text.contains('ampara') || text.contains('அம்பாறை')) {
      return 'ampara';
    }
    if (text.contains('kurunegala') || text.contains('குருநாகல்')) {
      return 'kurunegala';
    }
    if (text.contains('puttalam') || text.contains('புத்தளம்')) {
      return 'puttalam';
    }
    if (text.contains('anuradhapura') || text.contains('அனுராதபுரம்')) {
      return 'anuradhapura';
    }
    if (text.contains('polonnaruwa') || text.contains('பொலன்னறுவை')) {
      return 'polonnaruwa';
    }
    if (text.contains('badulla') || text.contains('பதுளை')) {
      return 'badulla';
    }
    if (text.contains('monaragala') || text.contains('மொணராகலை')) {
      return 'monaragala';
    }
    if (text.contains('ratnapura') ||
        text.contains('இரத்தினபுரி') ||
        text.contains('ரத்தினபுரி')) {
      return 'ratnapura';
    }
    if (text.contains('kegalle') || text.contains('கேகாலை')) {
      return 'kegalle';
    }
    if (text.contains('matale') || text.contains('மாத்தளை')) {
      return 'matale';
    }
    if (text.contains('nuwara eliya') || text.contains('நுவரெலியா')) {
      return 'nuwara eliya';
    }
    if (text.contains('hambantota') || text.contains('அம்பாந்தோட்டை')) {
      return 'hambantota';
    }
    if (text.contains('negombo') || text.contains('நீர்கொழும்பு')) {
      return 'negombo';
    }
    return text;
  }

  bool _isProviderAreaMatching(String providerArea, String requestedArea) {
    String specificArea = requestedArea;
    if (requestedArea.contains(',')) {
      specificArea = requestedArea.split(',').first.trim();
    }
    final provNorm = _normalizeArea(providerArea);
    final reqNorm = _normalizeArea(specificArea);
    return provNorm == reqNorm;
  }

  /// Finds up to 3 fictional demo providers matching [selectedServiceId] and
  /// [selectedArea].
  List<DemoProvider> findMatchingDemoProviders() {
    final serviceId = selectedServiceId;
    final area = selectedArea;
    if (!providersLoaded || serviceId == null || area == null) {
      return const [];
    }

    return demoProviders
        .where((provider) {
          final providerServiceId = _providerServiceToId(provider.service);
          return providerServiceId == serviceId &&
              _isProviderAreaMatching(provider.area, area);
        })
        .take(3)
        .toList();
  }

  String _recommendDemoProviders() {
    if (providerLoadError != null) {
      return _isTamil
          ? 'மாதிரி வழங்குநர் தரவை ஏற்ற முடியவில்லை ($providerLoadError). pubspec.yaml மற்றும் கோப்பைச் சரிபார்க்கவும்.'
          : 'Demo provider data could not be loaded ($providerLoadError). Check pubspec.yaml and assets/demo_providers.json, then restart the app.';
    }
    if (!providersLoaded) {
      return _isTamil
          ? 'மாதிரி வழங்குநர் பட்டியல் ஏற்றப்படுகிறது. மீண்டும் சரிபார்க்க "வழங்குநர்கள்" எனத் தட்டச்சு செய்யவும்.'
          : 'The demo provider list is loading. Type "providers" to check again.';
    }

    final serviceId = selectedServiceId;
    final area = selectedArea;
    if (serviceId == null || area == null) {
      return _isTamil
          ? 'முதலில் உங்கள் பிரச்சினையை விவரித்து பகுதியை உள்ளிடவும்.'
          : 'Please describe your problem and enter your area first.';
    }

    final serviceLabel = serviceDisplayName(serviceId);
    final matching = findMatchingDemoProviders();

    if (matching.isEmpty) {
      _clearLastRecommendations();
      return _isTamil
          ? '$area பகுதிக்கு கற்பனை மாதிரி $serviceLabel வழங்குநர்கள் பட்டியலிடப்படவில்லை. இதனால் உண்மையான வழங்குநர்கள் இல்லை என்று அர்த்தமல்ல.\n\nவேறு ஊரை முயற்சிக்க "பகுதியை மாற்று" அல்லது மீண்டும் தொடங்க "புதிதாக" எனத் தட்டச்சு செய்யவும்.'
          : 'No fictional demo $serviceLabel providers are listed for $area. This does NOT mean real providers are unavailable.\n\nType "change area" to try another town or "restart" to start over.';
    }

    final introLine = _isTamil
        ? 'பொருந்தும் கற்பனை மாதிரி வழங்குநர்கள் (உண்மையான நிறுவனங்கள் அல்ல):'
        : 'Matching fictional demo providers (not real businesses):';
    final footerText = _isTamil
        ? 'இவை சோதனைக்கான கற்பனை உதாரணங்கள் மட்டுமே. எந்த உண்மையான வழங்குநரும் தொடர்பு கொள்ளப்படவில்லை; முன்பதிவும் செய்யப்படவில்லை.\n\nவேறு ஊரைப் பார்க்க "பகுதியை மாற்று", புதிய கோரிக்கைக்கு "புதிதாக" எனத் தட்டச்சு செய்யவும், அல்லது NearFix கேள்வி கேட்கலாம்.'
        : 'These are made-up examples for prototype testing only. No real provider was contacted and no booking was made.\n\nType "change area" to try another town, "restart" for a new request, or ask any NearFix question.';

    lastRecommendedProviders = List.unmodifiable(matching);
    lastRecommendedServiceName = serviceLabel;
    lastRecommendationIntro = introLine;
    lastRecommendationFooter = footerText;

    final result = StringBuffer('$introLine\n');
    for (var i = 0; i < matching.length; i++) {
      final provider = matching[i];
      if (_isTamil) {
        result.write(
          '\n${i + 1}. ${provider.name}\n'
          '   பகுதி: ${provider.area}\n'
          '   சிறப்பு: ${provider.specialty}\n',
        );
      } else {
        result.write(
          '\n${i + 1}. ${provider.name}\n'
          '   Area: ${provider.area}\n'
          '   Specialty: ${provider.specialty}\n',
        );
      }
    }
    result.write('\n$footerText');
    return result.toString();
  }

  String _formatSummaryAndRecommendations() {
    final serviceLabel = serviceDisplayName(selectedServiceId!);
    final summaryBlock = _isTamil
        ? 'மாதிரி சேவைக் கோரிக்கைச் சுருக்கம் (உண்மையான முன்பதிவு அல்ல):\n\n'
              'சேவை: $serviceLabel\n'
              'பிரச்சினை: $problemDetail\n'
              'பகுதி: $selectedArea'
        : 'Demo service request summary (not a real booking):\n\n'
              'Service: $serviceLabel\n'
              'Problem: $problemDetail\n'
              'Area: $selectedArea';
    final recommendationText = _recommendDemoProviders();
    if (lastRecommendedProviders.isNotEmpty &&
        lastRecommendationIntro != null) {
      lastRecommendationIntro = '$summaryBlock\n\n$lastRecommendationIntro';
    }
    return '$summaryBlock\n\n$recommendationText';
  }

  String _faqFallbackUnavailable() {
    return _isTamil
        ? 'NearFix FAQ தரவை ($faqAssetPath) ஏற்ற முடியவில்லை. தயவுசெய்து pubspec.yaml மற்றும் assets கோப்புகளைச் சரிபார்க்கவும்.'
        : 'NearFix FAQ data ($faqAssetPath) could not be loaded. Please check pubspec.yaml and the assets folder.';
  }

  String _unknownFallback() {
    return _isTamil
        ? 'மன்னிக்கவும், அந்தக் கேள்விக்கு என்னிடம் உறுதிப்படுத்தப்பட்ட NearFix தகவல் இல்லை; இந்த மாதிரியில் NearFix வாடிக்கையாளர் கேள்விகளுக்குப் பதிலளிக்கவும் கற்பனை மாதிரி சேவை வழங்குநர்களைக் காட்டவும் மட்டுமே முடியும்.\n\n"NearFix என்றால் என்ன?", "என்னென்ன சேவைகள் உள்ளன?", "சேவையை எப்படி முன்பதிவு செய்வது?" எனக் கேட்கலாம் அல்லது "என் பைக் ஸ்டார்ட் ஆகவில்லை" போன்று பிரச்சினையை விவரிக்கலாம்.'
        : 'Sorry, I do not have documented NearFix facts for that question, and this standalone prototype can only answer NearFix customer questions and match fictional demo providers.\n\nTry asking "What is NearFix?", "What services are available?", "How do I book a service?", or describe a repair problem like "My bike is not starting".';
  }

  bool _isUnsupportedLanguageInput(String rawInput) {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) return false;
    if (_unsupportedScriptRegex.hasMatch(trimmed)) {
      return true;
    }

    // Detect Tanglish / romanized Tamil mixed phrases written in Latin script
    // while allowing Tamil Unicode + English technical words (e.g. "AC வேலை செய்யவில்லை").
    if (_tamilScriptRegex.hasMatch(trimmed) || !_latinScriptRegex.hasMatch(trimmed)) {
      return false;
    }

    final tokens = _normalizeText(trimmed)
        .split(' ')
        .where((token) => token.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return false;

    var weakParticleCount = 0;
    for (final token in tokens) {
      if (_strongTanglishTokens.contains(token)) {
        return true;
      }
      if (_weakTanglishParticles.contains(token)) {
        weakParticleCount++;
      }
    }
    return weakParticleCount >= 2;
  }

  String _unsupportedLanguageFallback() {
    const enNotice =
        'Sorry, I only support English and Tamil (தமிழ்) script, not Tanglish or other languages.\n\n'
        'Please type your NearFix question or repair problem in English or தமிழ் (for example: "My bike is not starting" or "என் பைக் ஸ்டார்ட் ஆகவில்லை").';
    const taNotice =
        'மன்னிக்கவும், இந்த உதவியாளர் ஆங்கிலம் மற்றும் தமிழ் (தமிழ் எழுத்துகள்) மட்டுமே ஆதரிக்கிறது; Tanglish அல்லது பிற மொழிகளைப் புரிந்துகொள்ளாது.\n\n'
        'தயவுசெய்து உங்கள் NearFix கேள்வி அல்லது பிரச்சினையை ஆங்கிலத்தில் அல்லது தமிழ் எழுத்துகளில் (உதாரணம்: "என் பைக் ஸ்டார்ட் ஆகவில்லை" அல்லது "My bike is not starting") தட்டச்சு செய்யவும்.';
    if (_conversationLanguage == ChatLanguage.ta) {
      return taNotice;
    }
    if (_conversationLanguage == ChatLanguage.en) {
      return enNotice;
    }
    return '$enNotice\n\n$taNotice';
  }

  static const Map<String, String> _explicitServiceAliasMap = {
    'mechanic': 'mechanic',
    'mechanics': 'mechanic',
    'vehicle repair': 'mechanic',
    'mechanic vehicle repair': 'mechanic',
    'plumber': 'plumber',
    'plumbing': 'plumber',
    'electrician': 'electrician',
    'electrical': 'electrician',
    'electrical work': 'electrician',
    'ac': 'ac',
    'ac repair': 'ac',
    'air conditioner': 'ac',
    'air conditioning': 'ac',
    'air conditioning repair': 'ac',
    'locksmith': 'locksmith',
    'carpenter': 'carpenter',
    'carpentry': 'carpenter',
    'cleaning': 'cleaning',
    'cleaner': 'cleaning',
    'phone repair': 'phone_repair',
    'mobile repair': 'phone_repair',
    'mobile phone repair': 'phone_repair',
    'மெக்கானிக்': 'mechanic',
    'வாகனப் பழுது': 'mechanic',
    'வாகனப் பழுதுபார்ப்பு': 'mechanic',
    'குழாய்ப்பணி': 'plumber',
    'மின்சார நிபுணர்': 'electrician',
    'மின்சார வேலை': 'electrician',
    'ஏசி பழுது': 'ac',
    'ஏசி பழுதுபார்ப்பு': 'ac',
    'குளிரூட்டி பழுதுபார்ப்பு': 'ac',
    'பூட்டு வேலை': 'locksmith',
    'தச்சு வேலை': 'carpenter',
    'சுத்தம் செய்தல்': 'cleaning',
    'கைபேசி பழுது': 'phone_repair',
    'கைபேசி பழுதுபார்ப்பு': 'phone_repair',
  };

  String? _detectExplicitServiceSelection(
    String rawInput, {
    required bool allowBareCategoryName,
  }) {
    final normalized = _normalizeText(rawInput);
    if (normalized.isEmpty) return null;

    if (allowBareCategoryName) {
      final bareMatch = _explicitServiceAliasMap[normalized];
      if (bareMatch != null) return bareMatch;
    }

    final enMatch = RegExp(
      r'^(?:i\s+(?:want|need)|need|find(?:\s+me)?|looking\s+for|switch\s+to|change\s+to|select|choose|get\s+me)\s+(?:a\s+|an\s+)?([a-z\s]+)$',
    ).firstMatch(normalized);
    if (enMatch != null) {
      final candidate = enMatch.group(1)?.trim() ?? '';
      return _explicitServiceAliasMap[candidate];
    }

    final taMatch = RegExp(
      r'^(?:எனக்கு\s+)?(.+?)\s+(?:தேவை|வேண்டும்|மாற்று)$',
    ).firstMatch(normalized);
    if (taMatch != null) {
      final candidate = taMatch.group(1)?.trim() ?? '';
      return _explicitServiceAliasMap[candidate];
    }

    return null;
  }

  String _applyServiceSelection(String serviceId) {
    selectedServiceId = serviceId;
    problemDetail = null;
    selectedArea = null;
    _pendingBatteryProblem = null;
    _pendingFaqCandidates = const [];
    _stageBeforeFaqClarify = 'service';
    chatStage = 'problem';

    final serviceLabel = serviceDisplayName(serviceId);
    return _isTamil
        ? 'இது $serviceLabel சேவைக்கான கோரிக்கையாகத் தெரிகிறது. குறிப்பிட்ட பிரச்சினையை விவரிக்கவும்.'
        : 'This looks like a $serviceLabel request. Please describe the specific problem.';
  }

  /// Handles an explicit service-shortcut chip selection while preserving
  /// chat history and resetting only the active service-request intake state.
  String selectServiceShortcut(String rawMessage, {required String serviceId}) {
    final trimmed = rawMessage.trim();
    _clearLastRecommendations();

    final detectedLanguage = detectMessageLanguage(trimmed);
    language = detectedLanguage;
    _conversationLanguage = detectedLanguage;

    return _applyServiceSelection(serviceId);
  }

  String _formatFaqClarification(List<NearFixFaqItem> options) {
    final buffer = StringBuffer(
      _isTamil
          ? 'உங்கள் கேள்விக்குப் பொருந்தக்கூடிய சில NearFix தலைப்புகள் உள்ளன. எதைப் பற்றி கேட்கிறீர்கள்?\n'
          : 'I found a few NearFix topics that might match your question. Which one did you mean?\n',
    );
    for (var i = 0; i < options.length; i++) {
      buffer.write('\n${i + 1}. ${options[i].localizedQuestion(language)}');
    }
    buffer.write(
      _isTamil
          ? '\n\nஎண்ணை (1, 2, ...) அனுப்பவும் அல்லது கேள்வியைச் சற்றுத் தெளிவாகக் கேட்கவும்.'
          : '\n\nReply with the number (1, 2, ...) or rephrase your question.',
    );
    return buffer.toString();
  }

  String? _tryAnswerFaq(String trimmed) {
    final outcome = evaluateFaqIntent(trimmed);
    if (outcome.match != null) {
      return outcome.match!.localizedAnswer(language);
    }
    if (outcome.isAmbiguous) {
      if (chatStage != 'clarify_faq') {
        _stageBeforeFaqClarify = chatStage;
      }
      _pendingFaqCandidates = outcome.ambiguousOptions;
      chatStage = 'clarify_faq';
      return _formatFaqClarification(outcome.ambiguousOptions);
    }
    return null;
  }

  bool _isRestartCommand(String input) {
    return input == 'restart' ||
        input == 'reset' ||
        input == 'புதிதாக' ||
        input == 'மீண்டும் தொடங்கு';
  }

  bool _isProvidersCommand(String input) {
    return input == 'providers' ||
        input == 'show providers' ||
        input == 'வழங்குநர்கள்' ||
        input == 'வழங்குநர்களைக் காட்டு';
  }

  bool _isChangeAreaCommand(String input) {
    final lower = input.trim().toLowerCase();
    return lower == 'change area' ||
        lower == 'பகுதியை மாற்று' ||
        lower == 'change location' ||
        lower == 'இடத்தை மாற்று';
  }

  String? _extractChangeAreaTarget(String raw) {
    final lower = raw.trim().toLowerCase();
    const prefixes = [
      'change area to ',
      'change area: ',
      'change location to ',
      'change location: ',
    ];
    for (final prefix in prefixes) {
      if (lower.startsWith(prefix)) {
        final target = raw.trim().substring(prefix.length).trim();
        if (target.isNotEmpty) return target;
      }
    }
    final taMatch =
        RegExp(r'^பகுதியை\s+(.+?)\s+(?:என|ஆக)\s+மாற்று$').firstMatch(raw.trim());
    if (taMatch != null) {
      final target = taMatch.group(1)?.trim();
      if (target != null && target.isNotEmpty) return target;
    }
    return null;
  }

  String _handleAreaInput(String rawInput) {
    final trimmed = rawInput.trim();
    final lower = trimmed.toLowerCase();

    // 1. If currently resolving a pending ambiguous place where district was requested:
    if (_pendingAmbiguousPlace != null) {
      if (['yes', 'no', 'ok', 'not sure', 'sure', 'ஆம்', 'இல்லை', 'சரி', 'தெரியாது']
              .contains(lower) ||
          trimmed.length < 3) {
        return _isTamil
            ? 'தயவுசெய்து $_pendingAmbiguousPlace எந்த மாவட்டத்தில் உள்ளது என்பதைக் குறிப்பிடவும்.'
            : 'Please specify which district $_pendingAmbiguousPlace is located in.';
      }

      final place = _pendingAmbiguousPlace!;
      _pendingAmbiguousPlace = null;
      selectedArea = '$place, $trimmed';
      chatStage = 'done';
      return _formatSummaryAndRecommendations();
    }

    // 2. Reject generic / non-location input:
    if (trimmed.length < 3 ||
        [
          'yes',
          'no',
          'ok',
          'not sure',
          'sure',
          'ஆம்',
          'இல்லை',
          'சரி',
          'தெரியாது',
        ].contains(lower)) {
      return _isTamil
          ? 'இலங்கையிலுள்ள ஓர் ஊர் அல்லது மாவட்டத்தின் பெயரை உள்ளிடவும் (உதாரணம்: யாழ்ப்பாணம், கொழும்பு, கண்டி, அல்லது காலி).'
          : 'Please enter a town or district anywhere in Sri Lanka (for example: Jaffna, Colombo, Kandy, or Galle).';
    }

    // 3. Ambiguity check: Ask for the district only if the place is ambiguous:
    final ambiguousDistricts = _checkAmbiguousPlace(lower);
    if (ambiguousDistricts != null) {
      _pendingAmbiguousPlace = trimmed;
      final districtList = _isTamil
          ? ambiguousDistricts.map(_districtToTamil).join(' அல்லது ')
          : ambiguousDistricts.join(' or ');
      return _isTamil
          ? '$trimmed இலங்கையில் ஒன்றுக்கு மேற்பட்ட மாவட்டங்களில் உள்ளது ($districtList). உங்கள் இருப்பிடம் எந்த மாவட்டத்தில் உள்ளது?'
          : '$trimmed can refer to more than one district in Sri Lanka (such as $districtList). Which district is your location in?';
    }

    // 4. Unambiguous place anywhere in Sri Lanka:
    _pendingAmbiguousPlace = null;
    selectedArea = trimmed;
    chatStage = 'done';
    return _formatSummaryAndRecommendations();
  }

  /// Processes one customer message, automatically detects English or Tamil,
  /// preserves conversation memory, and returns the response in that language.
  String getBotReply(String message) {
    final trimmed = message.trim();
    final input = trimmed.toLowerCase();
    _clearLastRecommendations();

    if (_isRestartCommand(input)) {
      final detectedLanguage = detectMessageLanguage(trimmed);
      final replyInTamil = detectedLanguage == ChatLanguage.ta;
      resetRequest();
      language = replyInTamil ? ChatLanguage.ta : ChatLanguage.en;
      return replyInTamil
          ? 'புதிய மாதிரி கோரிக்கை தொடங்கப்பட்டது. NearFix பற்றி கேள்வி கேட்கலாம் அல்லது உதவி தேவையான பிரச்சினையை விவரிக்கலாம்.'
          : 'Started a new demo request. Ask a NearFix question or describe the problem you need help with.';
    }

    if (_isUnsupportedLanguageInput(trimmed)) {
      if (_conversationLanguage != null) {
        language = _conversationLanguage!;
      }
      return _unsupportedLanguageFallback();
    }

    final detectedLanguage = detectMessageLanguage(trimmed);
    language = detectedLanguage;
    _conversationLanguage = detectedLanguage;

    if (_isOutOfScopeTopic(input)) {
      return _unknownFallback();
    }

    // Immediate danger / safety always takes top priority.
    if (_isEmergencySafetyMessage(input)) {
      final safetyFaq = _findFaqById('NF-FAQ-043');
      if (safetyFaq != null) {
        return safetyFaq.localizedAnswer(language);
      }
      return _isTamil
          ? 'தீ, கடுமையான காயம் அல்லது மின்சார ஆபத்து இருந்தால் பாதுகாப்பான இடத்துக்குச் சென்று அதிகாரப்பூர்வ உள்ளூர் அவசரச் சேவையைத் தொடர்பு கொள்ளுங்கள். இந்த உதவியாளர் அவசர உதவி அனுப்பாது.'
          : 'If there is fire, serious injury, electrical danger, or another immediate threat, move to safety and contact official local emergency services. This chatbot cannot dispatch help.';
    }

    // Handle pending FAQ clarification before other stages.
    if (chatStage == 'clarify_faq') {
      final choice = int.tryParse(trimmed);
      if (choice != null &&
          choice >= 1 &&
          choice <= _pendingFaqCandidates.length) {
        final picked = _pendingFaqCandidates[choice - 1];
        _pendingFaqCandidates = const [];
        chatStage = _stageBeforeFaqClarify;
        return picked.localizedAnswer(language);
      }

      // Allow the customer to rephrase or continue with a new question/request.
      _pendingFaqCandidates = const [];
      chatStage = _stageBeforeFaqClarify;
    }

    if (chatStage != 'service') {
      final explicitServiceId = _detectExplicitServiceSelection(
        trimmed,
        allowBareCategoryName: chatStage != 'clarify_battery',
      );
      if (explicitServiceId != null) {
        return _applyServiceSelection(explicitServiceId);
      }
    }

    // Handle pending battery clarification before general service classification.
    if (chatStage == 'clarify_battery') {
      final faqReply = _tryAnswerFaq(trimmed);
      if (faqReply != null) return faqReply;
      if (_mentionsVehicle(input)) {
        selectedServiceId = 'mechanic';
        problemDetail = _pendingBatteryProblem ?? trimmed;
        _pendingBatteryProblem = null;
        chatStage = 'area';
        final serviceLabel = serviceDisplayName('mechanic');
        return _isTamil
            ? 'புரிந்தது, இது $serviceLabel தொடர்பான பிரச்சினை. எந்த ஊர் அல்லது பகுதியில் உதவி தேவை?'
            : 'Got it, that sounds like a $serviceLabel issue. Which town or area do you need help in?';
      }
      if (_mentionsPhone(input)) {
        selectedServiceId = 'phone_repair';
        problemDetail = _pendingBatteryProblem ?? trimmed;
        _pendingBatteryProblem = null;
        chatStage = 'area';
        final serviceLabel = serviceDisplayName('phone_repair');
        return _isTamil
            ? 'புரிந்தது, இது $serviceLabel தொடர்பான பிரச்சினை. எந்த ஊர் அல்லது பகுதியில் உதவி தேவை?'
            : 'Got it, that sounds like a $serviceLabel issue. Which town or area do you need help in?';
      }
      return _isTamil
          ? 'சரியான சேவை வகையைத் தேர்வுசெய்ய "கார்", "பைக்", அல்லது "கைபேசி" என்று பதிலளிக்கவும்.'
          : 'Please reply with "car", "bike", or "phone" so I can pick the right service category.';
    }

    if (chatStage == 'done') {
      if (_isProvidersCommand(input)) {
        return _recommendDemoProviders();
      }
      if (_isChangeAreaCommand(input)) {
        selectedArea = null;
        _pendingAmbiguousPlace = null;
        _clearLastRecommendations();
        chatStage = 'area';
        return _isTamil
            ? 'வேறு எந்த ஊர் அல்லது பகுதியைச் சரிபார்க்க வேண்டும்?'
            : 'Which other town or area should I check?';
      }
      final changeAreaTarget = _extractChangeAreaTarget(trimmed);
      if (changeAreaTarget != null) {
        selectedArea = null;
        _pendingAmbiguousPlace = null;
        _clearLastRecommendations();
        chatStage = 'area';
        return _handleAreaInput(changeAreaTarget);
      }
      final faqReply = _tryAnswerFaq(trimmed);
      if (faqReply != null) return faqReply;
      if (faqLoadError != null && _looksLikeFaqLoadNeeded(trimmed)) {
        return _faqFallbackUnavailable();
      }

      // Intake after completion: A clear new problem starts a fresh intake,
      // keeps chat history, and asks for the area without reusing the old area.
      final newServiceId = detectServiceId(input);
      if (newServiceId != null && _describesProblem(input)) {
        selectedServiceId = newServiceId;
        problemDetail = trimmed;
        selectedArea = null;
        _pendingBatteryProblem = null;
        _pendingFaqCandidates = const [];
        _clearLastRecommendations();
        chatStage = 'area';
        final serviceLabel = serviceDisplayName(newServiceId);
        return _isTamil
            ? 'இது $serviceLabel தொடர்பான புதிய பிரச்சினையாகத் தெரிகிறது. எந்த ஊர் அல்லது பகுதியில் உதவி தேவை?'
            : 'This sounds like a $serviceLabel issue. Which town or area do you need help in?';
      }

      return _isTamil
          ? 'உங்கள் மாதிரி கோரிக்கை முடிந்துள்ளது. மாதிரி வழங்குநர்களை மீண்டும் பார்க்க "வழங்குநர்கள்", வேறு ஊருக்கு "பகுதியை மாற்று", புதிய கோரிக்கைக்கு "புதிதாக" எனத் தட்டச்சு செய்யவும், அல்லது NearFix கேள்வி கேட்கலாம்.'
          : 'Your demo request is complete. Type "providers" to view demo matches again, "change area" to check another town, "restart" for a new request, or ask a NearFix FAQ.';
    }

    if (chatStage == 'problem') {
      final faqReply = _tryAnswerFaq(trimmed);
      if (faqReply != null) return faqReply;
      if (input.length < 3 ||
          ['yes', 'no', 'ok', 'ஆம்', 'இல்லை', 'சரி'].contains(input)) {
        return _isTamil
            ? 'பிரச்சினையைச் சுருக்கமாக விவரிக்கவும். உதாரணம்: "என் பைக் ஸ்டார்ட் ஆகவில்லை" அல்லது "சமையலறைக் குழாயில் நீர் கசிகிறது".'
            : 'Please describe the problem briefly, for example: "My bike battery is dead" or "The kitchen pipe is leaking".';
      }
      problemDetail = trimmed;
      chatStage = 'area';
      final serviceLabel = serviceDisplayName(selectedServiceId!);
      return _isTamil
          ? 'நன்றி! எந்த ஊர் அல்லது பகுதியில் $serviceLabel உதவி தேவை?'
          : 'Thanks! Which town or area do you need $serviceLabel help in?';
    }

    if (chatStage == 'area') {
      final faqReply = _tryAnswerFaq(trimmed);
      if (faqReply != null) return faqReply;
      return _handleAreaInput(trimmed);
    }

    // Stage == 'service': Prioritize greetings and FAQ intents BEFORE service classification.
    if ([
      'hi',
      'hello',
      'hey',
      'how are you',
      'வணக்கம்',
      'ஹலோ',
    ].contains(input)) {
      return _isTamil
          ? 'வணக்கம்! NearFix பற்றி கேட்கலாம் (உதாரணம்: "NearFix என்றால் என்ன?" அல்லது "சேவையை எப்படி முன்பதிவு செய்வது?") அல்லது "என் பைக் ஸ்டார்ட் ஆகவில்லை" போன்று பிரச்சினையைச் சொல்லலாம்.'
          : 'Hello! You can ask about NearFix (for example, "What is NearFix?" or "How do I book a service?") or describe a problem like "My bike is not starting".';
    }

    final faqReply = _tryAnswerFaq(trimmed);
    if (faqReply != null) return faqReply;

    if (faqLoadError != null && _looksLikeFaqLoadNeeded(trimmed)) {
      return _faqFallbackUnavailable();
    }

    // Ambiguous standalone battery check (vehicle vs phone).
    if (_isAmbiguousBattery(input)) {
      _pendingBatteryProblem = trimmed;
      chatStage = 'clarify_battery';
      return _isTamil
          ? 'பேட்டரி பிரச்சினை என்று குறிப்பிட்டீர்கள். இது வாகனத்திற்கா (கார்/மோட்டார் சைக்கிள்) அல்லது கைபேசிக்கா?'
          : 'You mentioned a battery problem. Is this for a vehicle (car/motorcycle) or a mobile phone?';
    }

    final serviceId = detectServiceId(input);
    if (serviceId == null) {
      return _unknownFallback();
    }

    selectedServiceId = serviceId;
    final serviceLabel = serviceDisplayName(serviceId);
    if (_describesProblem(input)) {
      problemDetail = trimmed;
      chatStage = 'area';
      return _isTamil
          ? 'இது $serviceLabel தொடர்பான பிரச்சினையாகத் தெரிகிறது. எந்த ஊர் அல்லது பகுதியில் உதவி தேவை?'
          : 'This sounds like a $serviceLabel issue. Which town or area do you need help in?';
    }

    chatStage = 'problem';
    return _isTamil
        ? 'இது $serviceLabel சேவைக்கான கோரிக்கையாகத் தெரிகிறது. குறிப்பிட்ட பிரச்சினையை விவரிக்கவும்.'
        : 'This looks like a $serviceLabel request. Please describe the specific problem.';
  }

  /// Processes one customer message asynchronously using the AI service if available,
  /// falling back gracefully to the deterministic rule-based engine on network errors,
  /// low confidence, or when AI is unconfigured.
  Future<String> getBotReplyAsync(String message) async {
    final trimmed = message.trim();
    final input = trimmed.toLowerCase();
    _clearLastRecommendations();

    // 1. Safety first: Emergency danger is ALWAYS handled immediately by Dart code.
    if (_isEmergencySafetyMessage(input)) {
      final detectedLanguage = detectMessageLanguage(trimmed);
      language = detectedLanguage;
      _conversationLanguage = detectedLanguage;
      final safetyFaq = _findFaqById('NF-FAQ-043');
      if (safetyFaq != null) {
        return safetyFaq.localizedAnswer(language);
      }
      return _isTamil
          ? 'தீ, கடுமையான காயம் அல்லது மின்சார ஆபத்து இருந்தால் பாதுகாப்பான இடத்துக்குச் சென்று அதிகாரப்பூர்வ உள்ளூர் அவசரச் சேவையைத் தொடர்பு கொள்ளுங்கள். இந்த உதவியாளர் அவசர உதவி அனுப்பாது.'
          : 'If there is fire, serious injury, electrical danger, or another immediate threat, move to safety and contact official local emergency services. This chatbot cannot dispatch help.';
    }

    // 2. System commands handled in Dart code.
    if (_isRestartCommand(input)) {
      final detectedLanguage = detectMessageLanguage(trimmed);
      final replyInTamil = detectedLanguage == ChatLanguage.ta;
      resetRequest();
      language = replyInTamil ? ChatLanguage.ta : ChatLanguage.en;
      return replyInTamil
          ? 'புதிய மாதிரி கோரிக்கை தொடங்கப்பட்டது. NearFix பற்றி கேள்வி கேட்கலாம் அல்லது உதவி தேவையான பிரச்சினையை விவரிக்கலாம்.'
          : 'Started a new demo request. Ask a NearFix question or describe the problem you need help with.';
    }

    // 3. Tanglish / Unsupported script check in Dart code.
    if (_isUnsupportedLanguageInput(trimmed)) {
      if (_conversationLanguage != null) {
        language = _conversationLanguage!;
      }
      return _unsupportedLanguageFallback();
    }

    final detectedLanguage = detectMessageLanguage(trimmed);
    language = detectedLanguage;
    _conversationLanguage = detectedLanguage;

    // 4. Try AI processing if an AI service is provided and active.
    if (aiService != null && useAiIfAvailable && aiService!.isConfigured) {
      try {
        final aiResult = await aiService!.processMessage(
          userMessage: trimmed,
          currentStage: chatStage,
          currentServiceId: selectedServiceId,
          currentArea: selectedArea,
          currentLanguage: language,
          candidateFaqs: faqItems,
          categories: serviceCategories,
        );

        if (aiResult != null) {
          final reply = _applyAiResult(aiResult, trimmed);
          if (reply != null) {
            lastResponseSource = aiService!.isLiveBackend
                ? NearFixResponseSource.liveAi
                : NearFixResponseSource.mockAi;
            debugPrint(
              '[NearFixAI] Response Source: ${lastResponseSource == NearFixResponseSource.liveAi ? "LIVE AI (backend)" : "MOCK AI"}',
            );
            return reply;
          }
        }
        debugPrint(
          '[NearFixAI] AI response unusable or ungrounded (stage=$chatStage); falling back to rule-based engine.',
        );
      } catch (e) {
        debugPrint(
          '[NearFixAI] AI service encountered error/outage: ${e.runtimeType}. Falling back to rule-based engine.',
        );
      }
    }

    // 5. Fallback to the validated rule-based engine.
    lastResponseSource = NearFixResponseSource.ruleBasedFallback;
    debugPrint('[NearFixAI] Response Source: RULE-BASED FALLBACK');
    return getBotReply(trimmed);
  }

  static final RegExp _unsafePriceClaimRegex = RegExp(
    r'(?:\b(?:rs\.?|lkr|usd)\s*\d+|\$\s*\d+|\d+\s*(?:rupees|lkr)\b)',
    caseSensitive: false,
  );
  static final RegExp _unsafePhoneRegex = RegExp(r'(?:\+94\s*\d{2,}|\b0\d{9}\b)');
  static final RegExp _unsafeBookingClaimRegex = RegExp(
    r'\b(?:your\s+booking\s+(?:is|has\s+been)\s+confirmed|booking\s+confirmed|appointment\s+confirmed|provider\s+(?:is|will\s+be)\s+(?:on\s+the\s+way|arriving)|technician\s+(?:is|has\s+been)\s+dispatched)\b',
    caseSensitive: false,
  );
  static final RegExp _unsafeAvailabilityClaimRegex = RegExp(
    r'\b(?:providers?\s+(?:are|is)\s+available\s+(?:now|right\s+now|24/7)|guaranteed\s+availability)\b',
    caseSensitive: false,
  );

  bool _isSafeGroundedAiReply(String? reply) {
    if (reply == null || reply.trim().isEmpty) return false;
    return !_unsafePriceClaimRegex.hasMatch(reply) &&
        !_unsafePhoneRegex.hasMatch(reply) &&
        !_unsafeBookingClaimRegex.hasMatch(reply) &&
        !_unsafeAvailabilityClaimRegex.hasMatch(reply);
  }

  String? _applyAiResult(NearFixAiResult aiResult, String rawMessage) {
    // Location-stage inputs must always be processed by the local location
    // handler (after checking grounded FAQs), even if Gemini misclassifies them.
    if (chatStage == 'area') {
      if (aiResult.intent == NearFixAiIntent.faq && aiResult.faqId != null) {
        final faq = _findFaqById(aiResult.faqId!);
        if (faq != null) {
          return faq.localizedAnswer(language);
        }
      }
      final localFaq = _tryAnswerFaq(rawMessage);
      if (localFaq != null) {
        return localFaq;
      }
      return _handleAreaInput(rawMessage);
    }

    switch (aiResult.intent) {
      case NearFixAiIntent.unrelated:
        return _isSafeGroundedAiReply(aiResult.replyMessage)
            ? aiResult.replyMessage
            : _unknownFallback();

      case NearFixAiIntent.unconfirmed:
        return _isSafeGroundedAiReply(aiResult.replyMessage)
            ? aiResult.replyMessage
            : (_isTamil
                ? 'NearFix ஆவணங்களில் நிலையான பழுதுபார்ப்பு விலைகளோ மணிநேரக் கட்டணங்களோ உறுதிப்படுத்தப்படவில்லை. இறுதித் தொகை சேவை வழங்குநர், வேலை, பொருட்கள் ஆகியவற்றைப் பொறுத்தே அமையும். நேரடி கட்டண வசதி இன்னும் இந்த மாதிரியில் செயல்படுத்தப்படவில்லை.'
                : 'NearFix does not specify fixed repair prices or hourly rates in this prototype. The final amount depends on the independent provider, work, and materials. Live payment or checkout is not confirmed.');

      case NearFixAiIntent.clarification:
        if (aiResult.clarificationType == 'battery') {
          _pendingBatteryProblem = rawMessage;
          chatStage = 'clarify_battery';
          return _isSafeGroundedAiReply(aiResult.replyMessage)
              ? aiResult.replyMessage
              : (_isTamil
                  ? 'பேட்டரி பிரச்சினை என்று குறிப்பிட்டீர்கள். இது வாகனத்திற்கா (கார்/மோட்டார் சைக்கிள்) அல்லது கைபேசிக்கா?'
                  : 'You mentioned a battery problem. Is this for a vehicle (car/motorcycle) or a mobile phone?');
        }
        return _isSafeGroundedAiReply(aiResult.replyMessage)
            ? aiResult.replyMessage
            : null;

      case NearFixAiIntent.serviceProblem:
        final serviceId = aiResult.serviceId;
        if (serviceId != null) {
          final isKnown = serviceCategories.any((cat) => cat.id == serviceId) ||
              _explicitServiceAliasMap.containsValue(serviceId);
          if (isKnown) {
            // Intake after completion or fresh intake:
            if (chatStage == 'done') {
              selectedArea = null; // Clear old area!
              _clearLastRecommendations();
            }
            selectedServiceId = serviceId;
            problemDetail = rawMessage;
            _pendingBatteryProblem = null;
            _pendingFaqCandidates = const [];
            chatStage = 'area';

            final serviceLabel = serviceDisplayName(serviceId);
            return _isSafeGroundedAiReply(aiResult.replyMessage)
                ? aiResult.replyMessage
                : (_isTamil
                    ? 'இது $serviceLabel தொடர்பான பிரச்சினையாகத் தெரிகிறது. எந்த ஊர் அல்லது பகுதியில் உதவி தேவை?'
                    : 'This sounds like a $serviceLabel issue. Which town or area do you need help in?');
          }
        }
        return null;

      case NearFixAiIntent.faq:
        if (aiResult.faqId != null) {
          final faq = _findFaqById(aiResult.faqId!);
          if (faq != null) {
            return faq.localizedAnswer(language);
          }
        }
        final localFaq = _tryAnswerFaq(rawMessage);
        if (localFaq != null) {
          return localFaq;
        }
        return _isSafeGroundedAiReply(aiResult.replyMessage)
            ? aiResult.replyMessage
            : null;

      case NearFixAiIntent.followUp:
        return null;

      case NearFixAiIntent.fallback:
        return null;
    }
  }
}
