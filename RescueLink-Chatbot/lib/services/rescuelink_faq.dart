enum AppLanguage {
  en,
  si,
  ta,
}

enum TopicId {
  requestHelp,
  disasterUpdates,
  findShelters,
  safetyGuide,
  sosNotSent,
  sosServerReceipt,
  sosCanChatSend,
}

class LocalizedContent {
  final String safetyBanner;
  final String quickTopicsHeader;
  final String sosStatusHeader;
  final String inputHint;
  final String sendButton;
  final String welcomeMessage;
  final Map<TopicId, String> topicLabels;
  final Map<TopicId, String> topicReplies;
  final String immediateDangerReply;
  final String noMatchReply;

  const LocalizedContent({
    required this.safetyBanner,
    required this.quickTopicsHeader,
    required this.sosStatusHeader,
    required this.inputHint,
    required this.sendButton,
    required this.welcomeMessage,
    required this.topicLabels,
    required this.topicReplies,
    required this.immediateDangerReply,
    required this.noMatchReply,
  });
}

class RescueLinkFaq {
  static const List<TopicId> quickTopicIds = [
    TopicId.requestHelp,
    TopicId.disasterUpdates,
    TopicId.findShelters,
    TopicId.safetyGuide,
  ];

  static const List<TopicId> sosQuestionIds = [
    TopicId.sosNotSent,
    TopicId.sosServerReceipt,
    TopicId.sosCanChatSend,
  ];

  // Backward-compatible string lists for English
  static const List<String> quickTopics = [
    'Request Help',
    'Disaster Updates',
    'Find Shelters',
    'Safety Guide',
  ];

  static const List<String> sosQuestions = [
    'What does Not sent mean?',
    'Does server receipt mean help is on the way?',
    'Can this chat send an SOS?',
  ];

  static const List<String> quickQuestions = sosQuestions;

  static const LocalizedContent englishContent = LocalizedContent(
    safetyBanner: 'This chat cannot send an SOS.',
    quickTopicsHeader: 'Quick Topics',
    sosStatusHeader: 'SOS status',
    inputHint: 'Ask a question about RescueLink LK...',
    sendButton: 'Send',
    welcomeMessage:
        'Welcome to the RescueLink LK Assistant.\n\n'
        'I provide offline guidance on RescueLink LK and offline SOS statuses. '
        'Select a topic or SOS question below, or type your question.',
    topicLabels: {
      TopicId.requestHelp: 'Request Help',
      TopicId.disasterUpdates: 'Disaster Updates',
      TopicId.findShelters: 'Find Shelters',
      TopicId.safetyGuide: 'Safety Guide',
      TopicId.sosNotSent: 'What does Not sent mean?',
      TopicId.sosServerReceipt: 'Does server receipt mean help is on the way?',
      TopicId.sosCanChatSend: 'Can this chat send an SOS?',
    },
    topicReplies: {
      TopicId.requestHelp:
          'The planned Request Help feature will allow users to log and submit structured emergency '
          'assistance requests during a disaster. This prototype does not submit a report. '
          'If you need emergency assistance, please contact official emergency services.',
      TopicId.disasterUpdates:
          'This prototype does not show live alerts. For current information and active emergency '
          'announcements, please refer to official updates and government disaster management channels.',
      TopicId.findShelters:
          'This prototype has no verified live shelter list. We do not guess which shelters are open '
          'and do not ask for your location. Please check official disaster relief channels for verified shelter locations.',
      TopicId.safetyGuide:
          'The planned Safety Guide will cover preparing for, responding to, and recovering from a disaster. '
          'This prototype does not generate situation-specific safety instructions. Please follow guidance '
          'issued by official emergency personnel.',
      TopicId.sosNotSent:
          'An offline SOS stays "Not sent" until the server acknowledges it. '
          'Server acknowledgment only confirms receipt; it does not mean help was dispatched. '
          'This prototype chat does not store or send an SOS.',
      TopicId.sosServerReceipt:
          'Server acknowledgment only confirms receipt; it does not mean anyone has been dispatched '
          'or that help is on the way.',
      TopicId.sosCanChatSend:
          'No. This prototype chat cannot send an SOS. '
          'This assistant is strictly an informational FAQ tool. If you need emergency assistance, '
          'please contact official emergency services directly.',
    },
    immediateDangerReply:
        'If you are in immediate danger, do not wait for this chat. '
        'Please contact official emergency services immediately if you can.',
    noMatchReply:
        'I could not find a match for that question. I only answer questions about RescueLink LK. '
        'Available topics: Request Help, Disaster Updates, Find Shelters, Safety Guide, and SOS status ("Not sent", server receipt, can chat send SOS).',
  );

  static const LocalizedContent sinhalaContent = LocalizedContent(
    safetyBanner: 'මෙම චැට් මගින් SOS යැවිය නොහැක. [Draft - pending fluent review]',
    quickTopicsHeader: 'ක්ෂණික මාතෘකා',
    sosStatusHeader: 'SOS තත්ත්වය',
    inputHint: 'RescueLink LK පිළිබඳ ප්‍රශ්නයක් අසන්න...',
    sendButton: 'යවන්න',
    welcomeMessage:
        'RescueLink LK සහකාර වෙත සාදරයෙන් පිළිගනිමු.\n\n'
        'මම RescueLink LK සහ නොබැඳි SOS තත්ත්වයන් පිළිබඳ නොබැඳි මගපෙන්වීම් සපයන්නෙමි. '
        'පහතින් මාතෘකාවක් හෝ SOS ප්‍රශ්නයක් තෝරන්න, නැතහොත් ඔබේ ප්‍රශ්නය ටයිප් කරන්න.',
    topicLabels: {
      TopicId.requestHelp: 'උදව් ඉල්ලන්න',
      TopicId.disasterUpdates: 'ආපදා යාවත්කාලීන',
      TopicId.findShelters: 'ආරක්ෂිත ස්ථාන සොයන්න',
      TopicId.safetyGuide: 'ආරක්ෂක මාර්ගෝපදේශය',
      TopicId.sosNotSent: '"Not sent" යන්නෙන් අදහස් කරන්නේ කුමක්ද?',
      TopicId.sosServerReceipt: 'සේවාදායක ලැබීමෙන් උපකාර පැමිණෙන බව අදහස් වේද?',
      TopicId.sosCanChatSend: 'මෙම චැට් එකෙන් SOS යැවිය හැකිද?',
    },
    topicReplies: {
      TopicId.requestHelp:
          'සැලසුම් කර ඇති උදව් ඉල්ලීමේ (Request Help) විශේෂාංගය මඟින් ආපදා අවස්ථාවකදී ව්‍යුහගත හදිසි ආධාර ඉල්ලීම් වාර්තා කිරීමට පරිශීලකයින්ට ඉඩ සැලසේ. '
          'මෙම මූලාකෘතිය මඟින් වාර්තාවක් ඉදිරිපත් නොකෙරේ. ඔබට හදිසි උපකාර අවශ්‍ය නම්, කරුණාකර නිල හදිසි සේවාවන් අමතන්න.',
      TopicId.disasterUpdates:
          'මෙම මූලාකෘතිය සජීවී ඇඟවීම් නොපෙන්වයි. වත්මන් තොරතුරු සහ ආපදා නිවේදන සඳහා, කරුණාකර නිල යාවත්කාලීන කිරීම් සහ රජයේ ආපදා කළමනාකරණ අංශ වෙත යොමු වන්න.',
      TopicId.findShelters:
          'මෙම මූලාකෘතිය සතුව සත්‍යාපිත සජීවී ආරක්ෂිත ස්ථාන (shelters) ලැයිස්තුවක් නොමැත. '
          'විවෘතව පවතින ආරක්ෂිත ස්ථාන මොනවාදැයි අපි අනුමාන නොකරන අතර ඔබගේ ස්ථානය (location) විමසන්නේ නැත. කරුණාකර නිල ආපදා සහන මාර්ග පරීක්ෂා කරන්න.',
      TopicId.safetyGuide:
          'සැලසුම් කර ඇති ආරක්ෂක මාර්ගෝපදේශය (Safety Guide) මඟින් ආපදාවකට සූදානම් වීම, මුහුණ දීම සහ යථා තත්ත්වයට පත්වීම ආවරණය කරයි. '
          'මෙම මූලාකෘතිය තත්ත්වයට විශේෂිත වූ ආරක්ෂක උපදෙස් ජනනය නොකරයි. කරුණාකර නිල හදිසි සේවා නිලධාරීන්ගේ උපදෙස් පිළිපදින්න.',
      TopicId.sosNotSent:
          '[Draft - pending fluent review] නොබැඳි SOS පණිවිඩයක් සේවාදායකය (server) විසින් තහවුරු කරන තුරු "Not sent" ලෙස පවතී. '
          'සේවාදායකයේ ලැබීමෙන් කිසිවකු පිටත් කර යවා ඇති බවක් අදහස් නොවේ. '
          'මෙම මූලාකෘති චැට් මඟින් SOS ගබඩා කිරීම හෝ යැවීම සිදු නොවේ.',
      TopicId.sosServerReceipt:
          '[Draft - pending fluent review] සේවාදායකයේ තහවුරු කිරීම ලැබීම පමණක් තහවුරු කරයි; කිසිවකු පිටත් කර යවා ඇති බවක් හෝ උපකාර ලැබෙමින් පවතින බවක් එයින් අදහස් නොවේ.',
      TopicId.sosCanChatSend:
          '[Draft - pending fluent review] නැත. මෙම මූලාකෘති චැට් මඟින් SOS යැවිය නොහැක. මෙය තොරතුරු දැනගැනීමේ උපකරණයක් පමණි. '
          'ඔබට හදිසි උපකාර අවශ්‍ය නම්, කරුණාකර නිල හදිසි සේවාවන් කෙලින්ම අමතන්න.',
    },
    immediateDangerReply:
        '[Draft - pending fluent review] ඔබ ක්ෂණික අනතුරක සිටී නම්, මෙම චැට් එක පිළිතුරු දෙන තෙක් බලා නොසිටින්න. '
        'ඔබට හැකි නම් වහාම නිල හදිසි සේවාවන් අමතන්න.',
    noMatchReply:
        'එම ප්‍රශ්නය සඳහා ගැළපීමක් සොයාගත නොහැකි විය. මම RescueLink LK පිළිබඳ ප්‍රශ්නවලට පමණක් පිළිතුරු දෙමි. '
        'පවතින මාතෘකා: උදව් ඉල්ලන්න, ආපදා යාවත්කාලීන, ආරක්ෂිත ස්ථාන සොයන්න, ආරක්ෂක මාර්ගෝපදේශය, සහ SOS තත්ත්වය ("Not sent", සේවාදායක ලැබීම, SOS යැවීම).',
  );

  static const LocalizedContent tamilContent = LocalizedContent(
    safetyBanner: 'இந்த அரட்டை மூலம் SOS அனுப்ப முடியாது. [Draft - pending fluent review]',
    quickTopicsHeader: 'விரைவுத் தலைப்புகள்',
    sosStatusHeader: 'SOS நிலை',
    inputHint: 'RescueLink LK பற்றி ஒரு கேள்வி கேட்கவும்...',
    sendButton: 'அனுப்பு',
    welcomeMessage:
        'RescueLink LK உதவியாளருக்கு வரவேற்கிறோம்.\n\n'
        'RescueLink LK மற்றும் ஆஃப்லைன் SOS நிலைகள் பற்றிய ஆஃப்லைன் வழிகாட்டுதலை நான் வழங்குகிறேன். '
        'கீழே உள்ள தலைப்பு அல்லது SOS கேள்வியைத் தேர்ந்தெடுக்கவும், அல்லது உங்கள் கேள்வியைத் தட்டச்சு செய்யவும்.',
    topicLabels: {
      TopicId.requestHelp: 'உதவி கோரவும்',
      TopicId.disasterUpdates: 'பேரிடர் புதுப்பிப்புகள்',
      TopicId.findShelters: 'தங்குமிடங்களைக் கண்டறியவும்',
      TopicId.safetyGuide: 'பாதுகாப்பு வழிகாட்டி',
      TopicId.sosNotSent: '"Not sent" என்பதன் பொருள் என்ன?',
      TopicId.sosServerReceipt: 'சர்வர் ஏற்பு உதவி வருகிறது என்று அர்த்தமா?',
      TopicId.sosCanChatSend: 'இந்த அரட்டை மூலம் SOS அனுப்ப முடியுமா?',
    },
    topicReplies: {
      TopicId.requestHelp:
          'திட்டமிடப்பட்ட உதவி கோரும் (Request Help) அம்சம் பேரிடரின் போது கட்டமைக்கப்பட்ட அவசர உதவி கோரிக்கைகளைப் பதிவு செய்ய பயனர்களுக்கு உதவும். '
          'இந்த முன்மாதிரி அறிக்கையைச் சமர்ப்பிக்காது. உங்களுக்கு அவசர உதவி தேவைப்பட்டால், அதிகாரப்பூர்வ அவசர சேவைகளைத் தொடர்பு கொள்ளவும்.',
      TopicId.disasterUpdates:
          'இந்த முன்மாதிரி நேரடி எச்சரிக்கைகளைக் காட்டாது. தற்போதைய தகவல்களுக்கு, தயவுசெய்து அதிகாரப்பூர்வ அறிவிப்புகள் மற்றும் அரசு பேரிடர் மேலாண்மைத் துறையைப் பார்க்கவும்.',
      TopicId.findShelters:
          'இந்த முன்மாதிரியிடம் சரிபார்க்கப்பட்ட நேரடி தங்குமிடப் பட்டியல் இல்லை. எந்த தங்குமிடங்கள் திறக்கப்பட்டுள்ளன என்பதை நாங்கள் கணிக்க மாட்டோம், '
          'உங்கள் இருப்பிடத்தையும் கேட்க மாட்டோம். அதிகாரப்பூர்வ நிவாரண வழிகளைப் பார்க்கவும்.',
      TopicId.safetyGuide:
          'திட்டமிடப்பட்ட பாதுகாப்பு வழிகாட்டி (Safety Guide) பேரிடருக்குத் தயாராகுதல், எதிர்கொள்ளுதல் மற்றும் மீண்டு வருதல் ஆகியவற்றை உள்ளடக்கும். '
          'இந்த முன்மாதிரி சூழ்நிலைக்குரிய பாதுகாப்பு வழிமுறைகளை உருவாக்காது. அதிகாரப்பூர்வ வழிகாட்டுதலைப் பின்பற்றவும்.',
      TopicId.sosNotSent:
          '[Draft - pending fluent review] சர்வர் உறுதிப்படுத்தும் வரை ஆஃப்லைன் SOS "Not sent" நிலையிலேயே இருக்கும். '
          'சர்வர் ஏற்பு உதவி அனுப்பப்பட்டுவிட்டது என்று அர்த்தமல்ல. '
          'இந்த முன்மாதிரி அரட்டை SOS ஐ சேமிக்கவோ அனுப்பவோ செய்யாது.',
      TopicId.sosServerReceipt:
          '[Draft - pending fluent review] சர்வர் ஏற்பு ரசீதை மட்டுமே உறுதிப்படுத்துகிறது; மீட்புக் குழு அனுப்பப்பட்டுவிட்டது என்றோ உதவி வழியில் உள்ளது என்றோ இதற்குப் பொருள் இல்லை.',
      TopicId.sosCanChatSend:
          '[Draft - pending fluent review] இல்லை. இந்த முன்மாதிரி அரட்டை மூலம் SOS அனுப்ப முடியாது. இது தகவலுக்கான கருவி மட்டுமே. '
          'உங்களுக்கு அவசர உதவி தேவைப்பட்டால், அதிகாரப்பூர்வ அவசர சேவைகளை நேரடியாகத் தொடர்பு கொள்ளவும்.',
    },
    immediateDangerReply:
        '[Draft - pending fluent review] நீங்கள் உடனடி ஆபத்தில் இருந்தால், இந்த அரட்டைக்காகக் காத்திருக்க வேண்டாம். '
        'முடிந்தால் உடனடியாக அதிகாரப்பூர்வ அவசர சேவைகளைத் தொடர்பு கொள்ளவும்.',
    noMatchReply:
        'அந்தக் கேள்விக்கு பொருத்தமான பதில் கிடைக்கவில்லை. நான் RescueLink LK பற்றிய கேள்விகளுக்கு மட்டுமே பதிலளிப்பேன். '
        'கிடைக்கக்கூடிய தலைப்புகள்: உதவி கோரவும், பேரிடர் புதுப்பிப்புகள், தங்குமிடங்களைக் கண்டறியவும், பாதுகாப்பு வழிகாட்டி, மற்றும் SOS நிலை ("Not sent", சர்வர் ஏற்பு, SOS அனுப்புதல்).',
  );

  static LocalizedContent getContent(AppLanguage language) {
    switch (language) {
      case AppLanguage.en:
        return englishContent;
      case AppLanguage.si:
        return sinhalaContent;
      case AppLanguage.ta:
        return tamilContent;
    }
  }

  static String getLabelForTopic(TopicId topicId, {AppLanguage language = AppLanguage.en}) {
    return getContent(language).topicLabels[topicId] ?? '';
  }

  static String getReplyForTopic(TopicId topicId, {AppLanguage language = AppLanguage.en}) {
    return getContent(language).topicReplies[topicId] ?? '';
  }

  // Backward-compatible static string getters
  static String get requestHelpReply => englishContent.topicReplies[TopicId.requestHelp]!;
  static String get disasterUpdatesReply => englishContent.topicReplies[TopicId.disasterUpdates]!;
  static String get findSheltersReply => englishContent.topicReplies[TopicId.findShelters]!;
  static String get safetyGuideReply => englishContent.topicReplies[TopicId.safetyGuide]!;
  static String get notSentReply => englishContent.topicReplies[TopicId.sosNotSent]!;
  static String get serverReceiptReply => englishContent.topicReplies[TopicId.sosServerReceipt]!;
  static String get canChatSendSosReply => englishContent.topicReplies[TopicId.sosCanChatSend]!;
  static String get immediateDangerReply => englishContent.immediateDangerReply;
  static String get scopeReply => englishContent.noMatchReply;

  /// Evaluates a user query and returns a fixed offline response for the given language.
  static String getReply(String rawInput, {AppLanguage language = AppLanguage.en}) {
    final input = rawInput.trim();
    if (input.isEmpty) {
      switch (language) {
        case AppLanguage.en:
          return 'Please enter a question about RescueLink LK.';
        case AppLanguage.si:
          return 'කරුණාකර RescueLink LK පිළිබඳ ප්‍රශ්නයක් ඇතුළත් කරන්න.';
        case AppLanguage.ta:
          return 'தயவுசெய்து RescueLink LK பற்றி ஒரு கேள்வியை உள்ளிடவும்.';
      }
    }

    final lower = input.toLowerCase();
    final normalized = lower.replaceAll(RegExp(r'[?!.,\u0964]+$'), '').trim();
    final content = getContent(language);

    for (final supportedLanguage in AppLanguage.values) {
      for (final label in getContent(supportedLanguage).topicLabels.entries) {
        final normalizedLabel =
            label.value.toLowerCase().replaceAll(RegExp(r'[?!.,\u0964]+$'), '').trim();
        if (normalized == normalizedLabel) {
          return content.topicReplies[label.key]!;
        }
      }
    }

    const urgentPhrases = [
      'immediate danger', 'in danger', 'help me', 'save me', 'rescue me',
      'drowning', 'trapped', 'dying', 'bleeding', 'heart attack', 'stroke',
      'urgent help', 'need rescue', 'උදව් කරන්න', 'අනතුරේ', 'බේරගන්න',
      'காப்பாற்றுங்கள்', 'உடனடி ஆபத்து',
    ];
    if (urgentPhrases.any(lower.contains)) {
      return content.immediateDangerReply;
    }

    // 1. Topic: Request Help
    if (lower == 'request help' ||
        lower.contains('request help') ||
        lower.contains('how to request help') ||
        lower.contains('how do i request help') ||
        lower.contains('how can i request help') ||
        lower.contains('how to ask for help') ||
        lower.contains('how do i ask for help') ||
        lower.contains('how to ask for assistance') ||
        lower.contains('how do i ask for assistance') ||
        lower.contains('how can i get help') ||
        lower.contains('planned reporting') ||
        lower.contains('reporting feature') ||
        lower.contains('submit a report') ||
        lower.contains('උදව් ඉල්ලන්න') ||
        lower.contains('උදව් ඉල්ලන ආකාරය') ||
        lower.contains('ආධාර ඉල්ලන්නේ කොහොමද') ||
        lower.contains('උදව් ඉල්ලීම') ||
        lower.contains('உதவி கோரவும்') ||
        lower.contains('உதவி கோருவது எப்படி') ||
        lower.contains('உதவி கேட்பது எப்படி') ||
        lower.contains('உதவி பெறுவது எப்படி') ||
        normalized == 'உதவி கோர') {
      return content.topicReplies[TopicId.requestHelp]!;
    }

    // 2. Topic: Disaster Updates
    if (lower == 'disaster updates' ||
        lower.contains('disaster update') ||
        lower.contains('disaster updates') ||
        lower.contains('disaster alert') ||
        lower.contains('emergency updates') ||
        lower.contains('latest updates') ||
        lower.contains('live alert') ||
        lower.contains('live alerts') ||
        lower.contains('ආපදා යාවත්කාලීන') ||
        lower.contains('ආපදා තොරතුරු') ||
        lower.contains('ආපදා ඇඟවීම්') ||
        lower.contains('සජීවී ඇඟවීම්') ||
        lower.contains('பேரிடர் புதுப்பிப்புகள்') ||
        lower.contains('பேரிடர் தகவல்கள்') ||
        lower.contains('பேரிடர் எச்சரிக்கைகள்') ||
        lower.contains('நேரடி எச்சரிக்கைகள்')) {
      return content.topicReplies[TopicId.disasterUpdates]!;
    }

    // 3. Topic: Find Shelters
    if (lower == 'find shelters' ||
        lower.contains('find shelter') ||
        lower.contains('find shelters') ||
        RegExp(r'\bshelters?\b').hasMatch(lower) ||
        lower.contains('ආරක්ෂිත ස්ථාන') ||
        lower.contains('නවාතැන්') ||
        lower.contains('தங்குமிடங்கள்') ||
        lower.contains('தங்குமிடம்') ||
        lower.contains('பாதுகாப்பான இடங்கள்')) {
      return content.topicReplies[TopicId.findShelters]!;
    }

    // 4. Topic: Safety Guide
    if (lower == 'safety guide' ||
        lower.contains('safety guide') ||
        lower.contains('safety instructions') ||
        lower.contains('safety tips') ||
        lower.contains('disaster safety') ||
        lower.contains('ආරක්ෂක මාර්ගෝපදේශ') ||
        lower.contains('ආරක්ෂක උපදෙස්') ||
        lower.contains('பாதுகாப்பு வழிகாட்டி') ||
        lower.contains('பாதுகாப்பு வழிமுறைகள்') ||
        lower.contains('பாதுகாப்பு குறிப்புகள்')) {
      return content.topicReplies[TopicId.safetyGuide]!;
    }

    // 5. SOS Question: Not sent
    if (lower == 'what does not sent mean?' ||
        lower.contains('not sent') ||
        lower.contains('not sent යන්නෙන්') ||
        lower.contains('not sent අදහස') ||
        lower.contains('not sent பொருள்') ||
        lower.contains('not sent என்பதன் பொருள்') ||
        lower.contains('not sent என்றால் என்ன')) {
      return content.topicReplies[TopicId.sosNotSent]!;
    }

    // 6. SOS Question: Server receipt
    if (lower == 'does server receipt mean help is on the way?' ||
        lower.contains('server receipt') ||
        lower.contains('server acknowledgment') ||
        lower.contains('server acknowledgement') ||
        (lower.contains('server') && lower.contains('dispatch')) ||
        lower.contains('help is on the way') ||
        lower.contains('rescue team') ||
        lower.contains('සේවාදායක ලැබීම') ||
        lower.contains('සේවාදායක තහවුරු කිරීම') ||
        lower.contains('සේවාදායකයේ තහවුරු කිරීම') ||
        lower.contains('சர்வர் ஏற்பு') ||
        lower.contains('சர்வர் உறுதிப்படுத்தல்')) {
      return content.topicReplies[TopicId.sosServerReceipt]!;
    }

    // 7. SOS Question: Can chat send SOS
    if (lower == 'can this chat send an sos?' ||
        lower == 'can this chat send an sos' ||
        (lower.contains('chat') && lower.contains('sos')) ||
        (lower.contains('chat') && lower.contains('send') && lower.contains('sos')) ||
        lower.contains('can i send an sos here') ||
        lower.contains('sos යැවිය හැකිද') ||
        lower.contains('චැට් මගින් sos') ||
        lower.contains('sos அனுப்ப முடியுமா') ||
        lower.contains('அரட்டை மூலம் sos')) {
      return content.topicReplies[TopicId.sosCanChatSend]!;
    }

    // 8. Immediate danger keywords across all 3 languages
    final dangerKeywords = [
      'immediate danger', 'in danger', 'help me', 'save me', 'rescue me',
      'drowning', 'trapped', 'flood', 'fire', 'dying', 'bleeding',
      'heart attack', 'stroke', 'urgent help', 'need rescue', 'emergency',
      // Sinhala
      'උදව් කරන්න', 'අනතුරේ', 'අනතුරක්', 'හදිසි', 'ගංවතුර', 'ගින්න', 'බේරගන්න',
      // Tamil
      'காப்பாற்றுங்கள்', 'ஆபத்து', 'அவசரம்', 'வெள்ளம்', 'தீ', 'உடனடி ஆபத்து',
    ];

    final isExactSosOrHelp = lower == 'sos' ||
        lower == 'help' ||
        lower == 'help!' ||
        lower == 'උදව්' ||
        lower == 'උදව්!' ||
        lower == 'உதவி' ||
        lower == 'உதவி!';
    final hasDanger = dangerKeywords.any((kw) => lower.contains(kw));

    if (isExactSosOrHelp || hasDanger) {
      return content.immediateDangerReply;
    }

    if (RegExp(r'\bsos\b').hasMatch(lower)) {
      return content.topicReplies[TopicId.sosNotSent]!;
    }

    // 9. When no match, return the scope reply listing available topics instead of guessing
    return content.noMatchReply;
  }
}
