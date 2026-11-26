import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/services/nearfix_chatbot_engine.dart';

class _MissingFaqBundle extends CachingAssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key == NearFixChatbotEngine.faqAssetPath) {
      throw Exception('Simulated missing asset');
    }
    return rootBundle.loadString(key, cache: cache);
  }

  @override
  Future<ByteData> load(String key) => rootBundle.load(key);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NearFixChatbotEngine engine;

  setUp(() async {
    engine = NearFixChatbotEngine();
    await engine.loadAssets();
  });

  test('Loads all three JSON assets cleanly', () {
    expect(engine.providersLoaded, isTrue);
    expect(engine.faqLoaded, isTrue);
    expect(engine.servicesLoaded, isTrue);
    expect(engine.assetErrors, isEmpty);
    expect(engine.faqItems.length, greaterThanOrEqualTo(40));
    expect(engine.serviceCategories.length, 8);
    expect(engine.demoProviders.length, 10);
  });

  test('English questions produce English FAQ responses', () {
    final whatIs = engine.getBotReply('What is NearFix?');
    expect(whatIs, contains('proposed Sri Lankan app'));
    expect(engine.language, ChatLanguage.en);

    final privacy = engine.getBotReply('Who can see my location?');
    expect(privacy, contains('role-based protection'));

    final reviews = engine.getBotReply('Can I leave a review?');
    expect(reviews, contains('rate and review'));

    final realProviders = engine.getBotReply('Are the suggested providers real?');
    expect(realProviders, contains('fictional records'));

    final limits = engine.getBotReply('What are the prototype limits?');
    expect(limits, contains('cannot book a real job'));
  });

  test('Tamil questions and mixed brand-name Tamil questions produce Tamil responses', () {
    final whatIsTa = engine.getBotReply('NearFix என்றால் என்ன?');
    expect(whatIsTa, contains('திட்டமிடப்பட்ட இலங்கைச் செயலி'));
    expect(engine.language, ChatLanguage.ta);

    final bookTa = engine.getBotReply('சேவையை எப்படி முன்பதிவு செய்வது?');
    expect(bookTa, contains('உண்மையான முன்பதிவு இல்லை'));

    final privacyTa = engine.getBotReply('என் இருப்பிடம் யாருக்குத் தெரியும்?');
    expect(privacyTa, contains('அனுமதி அடிப்படையிலான பாதுகாப்பு'));

    // Mixed English technical word + Tamil script.
    final mixedAc = engine.getBotReply('AC வேலை செய்யவில்லை');
    expect(mixedAc, contains('குளிரூட்டி பழுதுபார்ப்பு'));
    expect(mixedAc, contains('எந்த ஊர் அல்லது பகுதியில்'));
    expect(engine.language, ChatLanguage.ta);
  });

  test('Switches languages cleanly within a single conversation while preserving memory', () {
    // Start in English.
    final step1 = engine.getBotReply('My bike is not starting.');
    expect(step1, contains('Mechanic / Vehicle Repair'));
    expect(step1, contains('Which town or area'));
    expect(engine.selectedServiceId, 'mechanic');
    expect(engine.chatStage, 'area');

    // Ask an FAQ in Tamil mid-conversation; state must stay intact.
    final faqTa = engine.getBotReply('NearFix என்றால் என்ன?');
    expect(faqTa, contains('திட்டமிடப்பட்ட இலங்கைச் செயலி'));
    expect(engine.selectedServiceId, 'mechanic');
    expect(engine.chatStage, 'area');

    // Switch back to English with a full reply or town.
    final switchEn = engine.getBotReply('How do I book a mechanic?');
    expect(switchEn, contains('planned process'));
    expect(engine.selectedServiceId, 'mechanic');
    expect(engine.chatStage, 'area');
  });

  test('Tamil problem description followed by Tamil town name gives Tamil recommendations', () {
    final firstReply = engine.getBotReply('என்னுடைய பைக் ஸ்டார்ட் ஆகவில்லை.');
    expect(firstReply, contains('வாகனப் பழுதுபார்ப்பு'));
    expect(firstReply, contains('எந்த ஊர் அல்லது பகுதியில்'));
    expect(engine.chatStage, 'area');

    final secondReply = engine.getBotReply('யாழ்ப்பாணம்');
    expect(secondReply, contains('மாதிரி சேவைக் கோரிக்கைச் சுருக்கம்'));
    expect(secondReply, contains('Demo Mechanic A'));
    expect(secondReply, contains('Demo Mechanic B'));
    expect(secondReply, isNot(contains('Demo Mechanic C')));
    expect(secondReply, contains('கற்பனை உதாரணங்கள் மட்டுமே'));
    expect(engine.chatStage, 'done');
  });

  test('Short follow-up messages inherit established conversation language', () {
    // 1. Tamil conversation + English town name "Jaffna" -> Tamil summary & matches.
    final taProblem = engine.getBotReply('என்னுடைய பைக் ஸ்டார்ட் ஆகவில்லை.');
    expect(taProblem, contains('எந்த ஊர் அல்லது பகுதியில்'));
    expect(engine.language, ChatLanguage.ta);

    final afterJaffna = engine.getBotReply('Jaffna');
    expect(engine.language, ChatLanguage.ta);
    expect(afterJaffna, contains('பொருந்தும் கற்பனை மாதிரி வழங்குநர்கள்'));
    expect(afterJaffna, contains('Demo Mechanic A'));

    // 2. English conversation + short Tamil confirmation "ஆம்" -> English prompt preserved.
    engine.resetRequest();
    final enService = engine.getBotReply('I need a plumber');
    expect(enService, contains('Please describe the specific problem'));
    expect(engine.language, ChatLanguage.en);

    final shortYesTa = engine.getBotReply('ஆம்');
    expect(engine.language, ChatLanguage.en);
    expect(shortYesTa, contains('Please describe the problem briefly'));
  });

  test('Prioritizes FAQ intent over service classification', () {
    final bookingReply = engine.getBotReply('How do I book a mechanic?');
    expect(bookingReply, contains('planned process'));
    expect(bookingReply, contains('cannot submit a real booking'));
    expect(engine.chatStage, 'service');
    expect(engine.selectedServiceId, isNull);

    final costReply = engine.getBotReply('How much does a plumber cost?');
    expect(costReply, contains('does not specify fixed repair prices'));
    expect(engine.chatStage, 'service');
  });

  test('Service matching and demo provider recommendation for English Jaffna bike', () {
    final firstReply = engine.getBotReply('My bike is not starting.');
    expect(firstReply, contains('Mechanic / Vehicle Repair'));
    expect(firstReply, contains('Which town or area'));
    expect(engine.chatStage, 'area');

    final secondReply = engine.getBotReply('Jaffna');
    expect(secondReply, contains('Demo Mechanic A'));
    expect(secondReply, contains('Demo Mechanic B'));
    expect(secondReply, isNot(contains('Demo Mechanic C')));
    expect(secondReply, contains('fictional'));
    expect(engine.chatStage, 'done');
  });

  test('Ambiguous battery asks vehicle vs phone before assigning category', () {
    final ask = engine.getBotReply('My battery is dead');
    expect(ask, contains('vehicle (car/motorcycle) or a mobile phone'));
    expect(engine.chatStage, 'clarify_battery');
    expect(engine.selectedServiceId, isNull);

    final afterPhone = engine.getBotReply('phone');
    expect(afterPhone, contains('Phone Repair'));
    expect(engine.selectedServiceId, 'phone_repair');
    expect(engine.chatStage, 'area');

    engine.resetRequest();
    final askTa = engine.getBotReply('பேட்டரி வேலை செய்யவில்லை');
    expect(askTa, contains('வாகனத்திற்கா'));
    expect(engine.chatStage, 'clarify_battery');

    final afterCarTa = engine.getBotReply('கார்');
    expect(afterCarTa, contains('வாகனப் பழுதுபார்ப்பு'));
    expect(engine.selectedServiceId, 'mechanic');
  });

  test('Does not match "ac" inside unrelated words like back or contact', () {
    expect(engine.detectServiceId('I need to go back'), isNull);
    expect(engine.detectServiceId('contact details'), isNull);
    expect(engine.detectServiceId('My AC is not cooling'), 'ac');
  });

  test('Handles missing providers politely without inventing matches', () {
    engine.getBotReply('My phone screen is broken');
    expect(engine.selectedServiceId, 'phone_repair');

    final reply = engine.getBotReply('Jaffna');
    expect(reply, contains('No fictional demo Phone Repair providers'));
    expect(reply, contains('does NOT mean real providers are unavailable'));

    engine.resetRequest();
    engine.getBotReply('கைபேசித் திரை உடைந்தது');
    final taReply = engine.getBotReply('யாழ்ப்பாணம்');
    expect(taReply, contains('பட்டியலிடப்படவில்லை'));
    expect(taReply, contains('உண்மையான வழங்குநர்கள் இல்லை என்று அர்த்தமல்ல'));
  });

  test('Handles unknown and out-of-scope questions politely in detected language', () {
    final unknownEn = engine.getBotReply('What is the weather in Colombo?');
    expect(unknownEn, contains('only answer NearFix customer questions'));

    final outOfScope = engine.getBotReply('How do NGO donors send disaster relief?');
    expect(outOfScope, contains('only answer NearFix customer questions'));

    final unknownTa = engine.getBotReply('இன்று வானிலை எப்படி உள்ளது?');
    expect(unknownTa, contains('NearFix வாடிக்கையாளர் கேள்விகளுக்குப் பதிலளிக்க'));
  });

  test('Handles missing FAQ asset gracefully with helpful fallback', () async {
    final brokenEngine = NearFixChatbotEngine();
    await brokenEngine.loadAssets(bundle: _MissingFaqBundle());

    expect(brokenEngine.faqLoaded, isFalse);
    expect(brokenEngine.faqLoadError, NearFixChatbotEngine.faqAssetPath);
    expect(brokenEngine.providersLoaded, isTrue);

    final fallback = brokenEngine.getBotReply('What is NearFix?');
    expect(fallback, contains(NearFixChatbotEngine.faqAssetPath));
  });

  test('Matches alternate English and Tamil FAQ phrasings and synonyms', () {
    // Synonym: "sign up" -> "register" (NF-FAQ-009)
    final signup = engine.getBotReply('How to sign up as a customer?');
    expect(signup, contains('customer registration and login screens'));

    // Synonym: "technician" -> "provider", "real or demo" (NF-FAQ-018)
    final techReal = engine.getBotReply('Are the technicians real or demo?');
    expect(techReal, contains('fictional records'));

    // Alternate wording for NearFix explanation (NF-FAQ-001)
    final howWorks = engine.getBotReply('How does NearFix work?');
    expect(howWorks, contains('proposed Sri Lankan app'));

    // Alternate wording for arrival ETA (NF-FAQ-024)
    final eta = engine.getBotReply('When will the technician arrive?');
    expect(eta, contains('must not promise an ETA'));

    // Tamil alternate phrasing for booking (NF-FAQ-025) & providers real (NF-FAQ-018)
    final bookAltTa = engine.getBotReply('முன்பதிவு செய்வது எப்படி?');
    expect(bookAltTa, contains('திட்டமிடப்பட்ட நடைமுறை'));

    final realAltTa = engine.getBotReply('வழங்குநர்கள் உண்மையா?');
    expect(realAltTa, contains('கற்பனைப் பதிவுகள்'));
  });

  test('Asks clarifying question for ambiguous FAQ intents and resolves by number', () {
    // English broad query: "Tell me about booking"
    final clarifyEn = engine.getBotReply('Tell me about booking');
    expect(clarifyEn, contains('Which one did you mean?'));
    expect(clarifyEn, contains('1.'));
    expect(clarifyEn, contains('2.'));
    expect(engine.chatStage, 'clarify_faq');

    final picked = engine.getBotReply('1');
    expect(picked, isNot(contains('Which one did you mean?')));
    expect(engine.chatStage, 'service');

    // Tamil broad query: "இருப்பிடம்" while mid-conversation preserves stage & Tamil.
    engine.resetRequest();
    engine.getBotReply('என்னுடைய பைக் ஸ்டார்ட் ஆகவில்லை.');
    expect(engine.chatStage, 'area');

    final clarifyTa = engine.getBotReply('இருப்பிடம்');
    expect(clarifyTa, contains('எதைப் பற்றி கேட்கிறீர்கள்?'));
    expect(engine.chatStage, 'clarify_faq');

    final pickedTa = engine.getBotReply('1');
    expect(pickedTa, isNot(contains('எதைப் பற்றி கேட்கிறீர்கள்?')));
    expect(engine.language, ChatLanguage.ta);
    expect(engine.chatStage, 'area');
    expect(engine.selectedServiceId, 'mechanic');
  });

  test('Prevents unrelated questions from matching NearFix FAQs', () {
    final unrelatedQueries = [
      'What is the capital of France?',
      'Can you book a flight for me?',
      'What is the price of rice?',
      'Who won the cricket match?',
      'விமான டிக்கெட் முன்பதிவு செய்வது எப்படி?',
      'கிரிக்கெட் போட்டி யார் வென்றது?',
    ];

    for (final query in unrelatedQueries) {
      final reply = engine.getBotReply(query);
      expect(
        reply,
        anyOf(
          contains('do not have documented NearFix facts'),
          contains('உறுதிப்படுத்தப்பட்ட NearFix தகவல் இல்லை'),
        ),
        reason: 'Unrelated query "$query" should trigger NearFix-only fallback',
      );
    }
  });

  test('All 44 FAQ entries match in English and Tamil with NearFix-only answers', () {
    expect(engine.faqItems.length, 44);
    const forbiddenTerms = [
      'helplink',
      'rescuelink',
      'ngo',
      'disaster relief',
    ];

    for (final item in engine.faqItems) {
      final enQuestion = item.question['en'] ?? '';
      final taQuestion = item.question['ta'] ?? '';
      final enAnswer = item.answer['en'] ?? '';
      final taAnswer = item.answer['ta'] ?? '';

      expect(enQuestion, isNotEmpty, reason: 'Missing EN question for ${item.id}');
      expect(taQuestion, isNotEmpty, reason: 'Missing TA question for ${item.id}');
      expect(enAnswer, isNotEmpty, reason: 'Missing EN answer for ${item.id}');
      expect(taAnswer, isNotEmpty, reason: 'Missing TA answer for ${item.id}');

      for (final forbidden in forbiddenTerms) {
        expect(enAnswer.toLowerCase(), isNot(contains(forbidden)));
        expect(taAnswer.toLowerCase(), isNot(contains(forbidden)));
      }

      engine.resetRequest();
      final enEval = engine.evaluateFaqIntent(enQuestion);
      expect(
        enEval.match?.id,
        item.id,
        reason: 'EN main question for ${item.id} failed to match directly',
      );
      expect(engine.getBotReply(enQuestion), enAnswer);
      expect(engine.language, ChatLanguage.en);

      engine.resetRequest();
      final taEval = engine.evaluateFaqIntent(taQuestion);
      expect(
        taEval.match?.id,
        item.id,
        reason: 'TA main question for ${item.id} failed to match directly',
      );
      expect(engine.getBotReply(taQuestion), taAnswer);
      expect(engine.language, ChatLanguage.ta);
    }

    // NF-FAQ-007 must describe automatic detection rather than manual selector.
    final langReply = engine.getBotReply('Which languages does the chatbot support?');
    expect(langReply, contains('automatically detects'));
    expect(langReply, isNot(contains('Language selection affects')));
  });

  test('Alternate phrasings across all FAQ topics retrieve matching answers', () {
    final checks = <String, String>{
      'Tell me about NearFix': 'NF-FAQ-001',
      'Who can use NearFix?': 'NF-FAQ-002',
      'Why use NearFix?': 'NF-FAQ-003',
      'Services offered': 'NF-FAQ-004',
      'Is NearFix live?': 'NF-FAQ-005',
      'What are the chatbot limitations?': 'NF-FAQ-006',
      'Supported languages': 'NF-FAQ-007',
      'Login required?': 'NF-FAQ-008',
      'Create an account': 'NF-FAQ-009',
      'Edit my profile': 'NF-FAQ-010',
      'How to report a problem?': 'NF-FAQ-011',
      'Examples of mechanic problems': 'NF-FAQ-012',
      'Examples of plumbing problems': 'NF-FAQ-013',
      'Can I upload photo?': 'NF-FAQ-014',
      'Can you find exact fault?': 'NF-FAQ-015',
      'How do you find providers?': 'NF-FAQ-016',
      'Anyone available right now?': 'NF-FAQ-017',
      'Are providers real businesses?': 'NF-FAQ-018',
      'What if nobody is found?': 'NF-FAQ-019',
      'Are providers background checked?': 'NF-FAQ-020',
      'How do I give my area?': 'NF-FAQ-021',
      'What if I work without GPS?': 'NF-FAQ-022',
      'GPS tracking for provider?': 'NF-FAQ-023',
      'How soon will they arrive?': 'NF-FAQ-024',
      'Can I book a service?': 'NF-FAQ-025',
      'Next step after booking?': 'NF-FAQ-026',
      'What are the request statuses?': 'NF-FAQ-027',
      'Can you confirm booking now?': 'NF-FAQ-028',
      'Can I contact provider?': 'NF-FAQ-029',
      'Can I cancel?': 'NF-FAQ-030',
      'Show my booking history': 'NF-FAQ-031',
      'Can I write a review?': 'NF-FAQ-032',
      'Track my real job status': 'NF-FAQ-033',
      'How much will a plumber cost?': 'NF-FAQ-034',
      'Separate labor and material cost breakdown?': 'NF-FAQ-035',
      'Is there a monthly fee?': 'NF-FAQ-036',
      'Can I pay by card online?': 'NF-FAQ-039',
      'Do I get a receipt?': 'NF-FAQ-040',
      'What is the money back policy?': 'NF-FAQ-041',
      'What is the Need Help Now feature?': 'NF-FAQ-042',
      'Electric shock danger!': 'NF-FAQ-043',
      'Privacy policy for my info': 'NF-FAQ-044',
      'Does it work offline without internet?': 'NF-FAQ-045',
      'Is arrival guaranteed?': 'NF-FAQ-046',
      // Tamil variations including inflected forms:
      'NearFix யார் பயன்படுத்தலாம்?': 'NF-FAQ-002',
      'முழு செயலி தயாரா?': 'NF-FAQ-005',
      'இருப்பிடத்தை பகிர்வது எப்படி?': 'NF-FAQ-021',
      'வழங்குநரை தொடர்பு கொள்ள முடியுமா?': 'NF-FAQ-029',
      'ரத்து செய்யலாமா?': 'NF-FAQ-030',
      'பணத்திருப்பு விதி என்ன?': 'NF-FAQ-041',
    };

    for (final entry in checks.entries) {
      final result = engine.evaluateFaqIntent(entry.key);
      expect(
        result.match?.id,
        entry.value,
        reason: 'Alternate query "${entry.key}" expected ${entry.value}, got ${result.match?.id ?? (result.isAmbiguous ? "ambiguous" : "none")}',
      );
    }
  });

  test('Conversation flows work across plumber, electrician, AC, locksmith, carpenter, and restart', () {
    // 1. Plumber -> Nallur (Demo Plumber A)
    expect(engine.getBotReply('Kitchen pipe is leaking'), contains('Which town or area'));
    final plumberDone = engine.getBotReply('Nallur');
    expect(plumberDone, contains('Demo Plumber A'));
    expect(plumberDone, isNot(contains('Demo Plumber B')));

    // Restart clears memory
    final restarted = engine.getBotReply('restart');
    expect(restarted, contains('Started a new demo request'));
    expect(engine.selectedServiceId, isNull);
    expect(engine.problemDetail, isNull);
    expect(engine.selectedArea, isNull);
    expect(engine.chatStage, 'service');

    // 2. Electrician -> Chavakachcheri (Demo Electrician B) interrupted by FAQ
    expect(engine.getBotReply('I need an electrician'), contains('describe the specific problem'));
    expect(engine.getBotReply('No power in bedroom socket'), contains('Which town or area'));
    final midFaq = engine.getBotReply('Are the suggested providers real?');
    expect(midFaq, contains('fictional records'));
    expect(engine.chatStage, 'area');
    final elecDone = engine.getBotReply('Chavakachcheri');
    expect(elecDone, contains('Demo Electrician B'));

    // 3. AC -> Point Pedro (Demo AC Technician A)
    engine.resetRequest();
    expect(engine.getBotReply('AC is not cooling'), contains('Which town or area'));
    expect(engine.getBotReply('Point Pedro'), contains('Demo AC Technician A'));

    // 4. Locksmith -> Nallur (Demo Locksmith A)
    engine.resetRequest();
    expect(engine.getBotReply('Door lock jammed'), contains('Which town or area'));
    expect(engine.getBotReply('Nallur'), contains('Demo Locksmith A'));

    // 5. Carpenter -> Jaffna (Demo Carpenter A)
    engine.resetRequest();
    expect(engine.getBotReply('Furniture broken'), contains('Which town or area'));
    expect(engine.getBotReply('Jaffna'), contains('Demo Carpenter A'));
  });

  test('Rejects HelpLink LK and RescueLink LK cleanly', () {
    for (final query in [
      'What is HelpLink LK?',
      'How does RescueLink LK work?',
    ]) {
      final reply = engine.getBotReply(query);
      expect(
        reply,
        contains('do not have documented NearFix facts'),
        reason: 'Query "$query" must fall back politely without matching',
      );
      expect(reply.toLowerCase(), isNot(contains('helplink')));
      expect(reply.toLowerCase(), isNot(contains('rescuelink')));
    }
  });

  test('Handles unsupported Tanglish and non-EN/TA scripts without false interpretation while keeping legitimate English', () {
    for (final query in [
      'Bike start aagala',
      'Pipe leak aaguthu',
      'NearFix na enna',
      'Vandi start aagala',
      'Enna service irukku',
      'මගේ බයික් එක ස්ටාර්ට් වෙන්නේ නෑ',
    ]) {
      engine.resetRequest();
      final reply = engine.getBotReply(query);
      expect(reply, contains('only support English and Tamil'));
      expect(reply, contains('ஆங்கிலம் மற்றும் தமிழ்'));
      expect(engine.selectedServiceId, isNull);
      expect(engine.chatStage, 'service');
    }

    // Legitimate English sentences with unfamiliar brand/technical words still work.
    engine.resetRequest();
    final unfamiliarBrand = engine.getBotReply(
      'My Honda Dio scooter is not starting even with a new sparkplug',
    );
    expect(unfamiliarBrand, contains('Mechanic / Vehicle Repair'));
    expect(unfamiliarBrand, contains('Which town or area'));
    expect(engine.selectedServiceId, 'mechanic');
    expect(engine.chatStage, 'area');

    engine.resetRequest();
    final unfamiliarPart = engine.getBotReply(
      'The backyard borewell sump pipe is leaking',
    );
    expect(unfamiliarPart, contains('Plumbing'));
    expect(unfamiliarPart, contains('Which town or area'));
    expect(engine.selectedServiceId, 'plumber');
    expect(engine.chatStage, 'area');
  });

  test('Switches cleanly from Mechanic to Plumber during problem stage and location stage', () {
    // 1. Switch during problem stage (English).
    final step1 = engine.selectServiceShortcut(
      'I need a mechanic',
      serviceId: 'mechanic',
    );
    expect(step1, contains('Mechanic / Vehicle Repair'));
    expect(engine.selectedServiceId, 'mechanic');
    expect(engine.chatStage, 'problem');

    final switchedInProblem = engine.selectServiceShortcut(
      'I need a plumber',
      serviceId: 'plumber',
    );
    expect(switchedInProblem, contains('Plumbing'));
    expect(switchedInProblem, contains('Please describe the specific problem'));
    expect(engine.selectedServiceId, 'plumber');
    expect(engine.problemDetail, isNull);
    expect(engine.selectedArea, isNull);
    expect(engine.chatStage, 'problem');

    // Complete Plumbing request after switch.
    expect(engine.getBotReply('Kitchen tap is leaking'), contains('Which town or area'));
    final afterArea = engine.getBotReply('Jaffna');
    expect(afterArea, contains('Demo Plumber B'));
    expect(afterArea, isNot(contains('Demo Mechanic')));

    // 2. Switch from Mechanic to Plumber during location (area) stage via message text.
    engine.resetRequest();
    expect(engine.getBotReply('My bike is not starting'), contains('Which town or area'));
    expect(engine.selectedServiceId, 'mechanic');
    expect(engine.problemDetail, 'My bike is not starting');
    expect(engine.chatStage, 'area');

    final switchedInArea = engine.getBotReply('I need a plumber');
    expect(switchedInArea, contains('Plumbing'));
    expect(switchedInArea, contains('Please describe the specific problem'));
    expect(engine.selectedServiceId, 'plumber');
    expect(engine.problemDetail, isNull);
    expect(engine.selectedArea, isNull);
    expect(engine.chatStage, 'problem');

    expect(engine.getBotReply('Bathroom pipe leak'), contains('Which town or area'));
    final nallurPlumber = engine.getBotReply('Nallur');
    expect(nallurPlumber, contains('Demo Plumber A'));
    expect(nallurPlumber, isNot(contains('My bike is not starting')));

    // 3. Tamil shortcut switch during area stage preserves Tamil and resets service state.
    engine.resetRequest();
    expect(
      engine.getBotReply('என்னுடைய பைக் ஸ்டார்ட் ஆகவில்லை.'),
      contains('எந்த ஊர் அல்லது பகுதியில்'),
    );
    expect(engine.chatStage, 'area');

    final switchedTa = engine.selectServiceShortcut(
      'எனக்கு குழாய்ப்பணி தேவை',
      serviceId: 'plumber',
    );
    expect(switchedTa, contains('குழாய்ப்பணி'));
    expect(switchedTa, contains('குறிப்பிட்ட பிரச்சினையை விவரிக்கவும்'));
    expect(engine.language, ChatLanguage.ta);
    expect(engine.selectedServiceId, 'plumber');
    expect(engine.problemDetail, isNull);
    expect(engine.selectedArea, isNull);
    expect(engine.chatStage, 'problem');
  });

  test('Matching demo town returns demo provider cards with exact category and covered area', () {
    // English flow: Mechanic -> Jaffna
    engine.resetRequest();
    final step1 = engine.getBotReply('My bike is not starting');
    expect(step1, contains('Which town or area'));
    expect(engine.chatStage, 'area');

    final step2 = engine.getBotReply('Jaffna');
    expect(engine.chatStage, 'done');
    expect(engine.selectedArea, 'Jaffna');
    expect(engine.lastRecommendedProviders.length, 2);
    expect(engine.lastRecommendedProviders.every((p) => p.area == 'Jaffna'), isTrue);
    expect(engine.lastRecommendedProviders.every((p) => p.service == 'Mechanic'), isTrue);
    expect(step2, contains('Demo Mechanic A'));
    expect(step2, contains('Demo Mechanic B'));
    expect(step2, isNot(contains('Demo Mechanic C'))); // Demo Mechanic C is in Nallur

    // Tamil flow: Mechanic -> நல்லூர் (Nallur)
    engine.resetRequest();
    final ta1 = engine.getBotReply('என்னுடைய பைக் ஸ்டார்ட் ஆகவில்லை.');
    expect(ta1, contains('எந்த ஊர் அல்லது பகுதியில்'));
    expect(engine.chatStage, 'area');

    final ta2 = engine.getBotReply('நல்லூர்');
    expect(engine.chatStage, 'done');
    expect(engine.selectedArea, 'நல்லூர்');
    expect(engine.lastRecommendedProviders.length, 1);
    expect(engine.lastRecommendedProviders.first.name, 'Demo Mechanic C');
    expect(engine.lastRecommendedProviders.first.area, 'Nallur');
    expect(ta2, contains('Demo Mechanic C'));
    expect(ta2, isNot(contains('Demo Mechanic A'))); // Demo Mechanic A is in Jaffna
  });

  test('Sri Lankan location outside demo data is accepted, stored, and shows polite no-demo-results message without inventing providers', () {
    // English: Mechanic -> Colombo
    engine.resetRequest();
    engine.getBotReply('My bike engine is broken');
    expect(engine.chatStage, 'area');

    final colomboReply = engine.getBotReply('Colombo');
    expect(engine.chatStage, 'done');
    expect(engine.selectedArea, 'Colombo');
    expect(engine.lastRecommendedProviders, isEmpty);
    expect(colomboReply, contains('Area: Colombo'));
    expect(colomboReply, contains('No fictional demo Mechanic / Vehicle Repair providers are listed for Colombo'));
    expect(colomboReply, contains('This does NOT mean real providers are unavailable'));
    expect(colomboReply, isNot(contains('Demo Mechanic A')));

    // Tamil: Plumber -> கண்டி (Kandy)
    engine.resetRequest();
    engine.getBotReply('குழாய் பழுது');
    expect(engine.chatStage, 'area');

    final kandyReply = engine.getBotReply('கண்டி');
    expect(engine.chatStage, 'done');
    expect(engine.selectedArea, 'கண்டி');
    expect(engine.lastRecommendedProviders, isEmpty);
    expect(kandyReply, contains('பகுதி: கண்டி'));
    expect(kandyReply, contains('பட்டியலிடப்படவில்லை'));
    expect(kandyReply, contains('உண்மையான வழங்குநர்கள் இல்லை என்று அர்த்தமல்ல'));
    expect(kandyReply, isNot(contains('Demo Plumber')));
  });

  test('Changing requested location does not reuse old location', () {
    engine.resetRequest();
    engine.getBotReply('My bike is not starting');
    final firstResult = engine.getBotReply('Jaffna');
    expect(firstResult, contains('Demo Mechanic A'));
    expect(engine.selectedArea, 'Jaffna');
    expect(engine.chatStage, 'done');

    // Customer requests to change area via command
    final changePrompt = engine.getBotReply('change area');
    expect(changePrompt, contains('Which other town or area should I check?'));
    expect(engine.chatStage, 'area');
    expect(engine.selectedArea, isNull, reason: 'Old area "Jaffna" must be cleared');
    expect(engine.lastRecommendedProviders, isEmpty);

    // Customer enters outside demo location Colombo
    final colomboResult = engine.getBotReply('Colombo');
    expect(engine.selectedArea, 'Colombo');
    expect(engine.chatStage, 'done');
    expect(engine.lastRecommendedProviders, isEmpty);
    expect(colomboResult, contains('Area: Colombo'));
    expect(colomboResult, isNot(contains('Area: Jaffna')));
    expect(colomboResult, contains('No fictional demo Mechanic / Vehicle Repair providers are listed for Colombo'));
    expect(colomboResult, isNot(contains('Demo Mechanic A')));

    // Customer changes area again to another demo town Nallur
    engine.getBotReply('change area');
    final nallurResult = engine.getBotReply('Nallur');
    expect(engine.selectedArea, 'Nallur');
    expect(engine.chatStage, 'done');
    expect(nallurResult, contains('Area: Nallur'));
    expect(nallurResult, isNot(contains('Area: Colombo')));
    expect(nallurResult, isNot(contains('Area: Jaffna')));
    expect(engine.lastRecommendedProviders.length, 1);
    expect(engine.lastRecommendedProviders.first.name, 'Demo Mechanic C');
    expect(nallurResult, contains('Demo Mechanic C'));
    expect(nallurResult, isNot(contains('Demo Mechanic A')));
  });

  test('Ambiguous place name in Sri Lanka asks for district clarification and preserves resolved area', () {
    engine.resetRequest();
    engine.getBotReply('My bike is not starting');
    expect(engine.chatStage, 'area');

    // Ambiguous place name: Kochchikade (in Colombo and Gampaha)
    final ambiguousAsk = engine.getBotReply('Kochchikade');
    expect(engine.chatStage, 'area');
    expect(ambiguousAsk, contains('Kochchikade can refer to more than one district in Sri Lanka'));
    expect(ambiguousAsk, contains('Colombo or Gampaha'));
    expect(ambiguousAsk, contains('Which district is your location in?'));
    expect(engine.selectedArea, isNull);

    // Customer clarifies district: Gampaha
    final resolvedReply = engine.getBotReply('Gampaha');
    expect(engine.chatStage, 'done');
    expect(engine.selectedArea, 'Kochchikade, Gampaha');
    expect(resolvedReply, contains('Area: Kochchikade, Gampaha'));
    expect(resolvedReply, contains('No fictional demo Mechanic / Vehicle Repair providers are listed for Kochchikade, Gampaha'));
    expect(engine.lastRecommendedProviders, isEmpty);

    // Entering ambiguous place with district upfront is resolved immediately
    engine.resetRequest();
    engine.getBotReply('My bike is not starting');
    final upfrontReply = engine.getBotReply('Kochchikade, Colombo');
    expect(engine.chatStage, 'done');
    expect(engine.selectedArea, 'Kochchikade, Colombo');
    expect(upfrontReply, contains('Area: Kochchikade, Colombo'));
  });

  test('Data-driven test: All 25 Sri Lankan districts are accepted and stored without substitution in English and Tamil', () {
    const sriLankanDistricts = <Map<String, String>>[
      {'en': 'Ampara', 'ta': 'அம்பாறை'},
      {'en': 'Anuradhapura', 'ta': 'அனுராதபுரம்'},
      {'en': 'Badulla', 'ta': 'பதுளை'},
      {'en': 'Batticaloa', 'ta': 'மட்டக்களப்பு'},
      {'en': 'Colombo', 'ta': 'கொழும்பு'},
      {'en': 'Galle', 'ta': 'காலி'},
      {'en': 'Gampaha', 'ta': 'கம்பஹா'},
      {'en': 'Hambantota', 'ta': 'அம்பாந்தோட்டை'},
      {'en': 'Jaffna', 'ta': 'யாழ்ப்பாணம்'},
      {'en': 'Kalutara', 'ta': 'களுத்துறை'},
      {'en': 'Kandy', 'ta': 'கண்டி'},
      {'en': 'Kegalle', 'ta': 'கேகாலை'},
      {'en': 'Kilinochchi', 'ta': 'கிளிநொச்சி'},
      {'en': 'Kurunegala', 'ta': 'குருநாகல்'},
      {'en': 'Mannar', 'ta': 'மன்னார்'},
      {'en': 'Matale', 'ta': 'மாத்தளை'},
      {'en': 'Matara', 'ta': 'மாத்தறை'},
      {'en': 'Monaragala', 'ta': 'மொணராகலை'},
      {'en': 'Mullaitivu', 'ta': 'முல்லைத்தீவு'},
      {'en': 'Nuwara Eliya', 'ta': 'நுவரெலியா'},
      {'en': 'Polonnaruwa', 'ta': 'பொலன்னறுவை'},
      {'en': 'Puttalam', 'ta': 'புத்தளம்'},
      {'en': 'Ratnapura', 'ta': 'இரத்தினபுரி'},
      {'en': 'Trincomalee', 'ta': 'திருகோணமலை'},
      {'en': 'Vavuniya', 'ta': 'வவுனியா'},
    ];

    expect(sriLankanDistricts.length, 25, reason: 'Verified list must contain all 25 districts');

    for (final districtEntry in sriLankanDistricts) {
      final districtEn = districtEntry['en']!;
      final districtTa = districtEntry['ta']!;

      // 1. English intake
      engine.resetRequest();
      final enPrompt = engine.getBotReply('My bike is not starting');
      expect(
        enPrompt,
        contains('Which town or area'),
        reason: 'District $districtEn: fresh request must prompt for location',
      );
      expect(
        engine.chatStage,
        'area',
        reason: 'District $districtEn: chatStage must be area',
      );

      final enReply = engine.getBotReply(districtEn);
      expect(
        engine.chatStage,
        'done',
        reason: 'District $districtEn: assistant must accept district and transition to done',
      );
      expect(
        engine.selectedArea,
        districtEn,
        reason: 'District $districtEn: assistant must store the exact district without substituting another area',
      );
      expect(
        enReply,
        contains('Area: $districtEn'),
        reason: 'District $districtEn: summary must display the requested district',
      );

      // Provider matching verification for English:
      if (districtEn == 'Jaffna') {
        expect(
          engine.lastRecommendedProviders.isNotEmpty,
          isTrue,
          reason: 'District Jaffna must return matching demo mechanics',
        );
        expect(
          engine.lastRecommendedProviders.every((p) => p.service == 'Mechanic' && p.area == 'Jaffna'),
          isTrue,
          reason: 'District Jaffna: only providers covering Jaffna and matching Mechanic must be returned',
        );
        expect(
          enReply,
          contains('Matching fictional demo providers'),
          reason: 'District Jaffna: must introduce matching providers',
        );
        expect(
          enReply,
          contains('Demo Mechanic A'),
          reason: 'District Jaffna: must include Demo Mechanic A',
        );
      } else {
        expect(
          engine.lastRecommendedProviders,
          isEmpty,
          reason: 'District $districtEn: no demo provider cards should be returned when there are no matching records',
        );
        expect(
          enReply,
          contains('No fictional demo Mechanic / Vehicle Repair providers are listed for $districtEn'),
          reason: 'District $districtEn: reply must say there are no matching demo providers',
        );
        expect(
          enReply,
          contains('does NOT mean real providers are unavailable'),
          reason: 'District $districtEn: reply must explain demo limitation',
        );
        expect(
          enReply,
          isNot(contains('Demo Mechanic A')),
          reason: 'District $districtEn: must not invent or present foreign providers as nearby',
        );
      }

      // 2. Tamil intake (tested with the app\'s supported Tamil alias)
      engine.resetRequest();
      final taPrompt = engine.getBotReply('என்னுடைய பைக் ஸ்டார்ட் ஆகவில்லை.');
      expect(
        taPrompt,
        contains('எந்த ஊர் அல்லது பகுதியில்'),
        reason: 'Tamil district $districtTa ($districtEn): fresh request must prompt for location',
      );
      expect(
        engine.chatStage,
        'area',
        reason: 'Tamil district $districtTa ($districtEn): chatStage must be area',
      );

      final taReply = engine.getBotReply(districtTa);
      expect(
        engine.chatStage,
        'done',
        reason: 'Tamil district $districtTa ($districtEn): assistant must accept district and transition to done',
      );
      expect(
        engine.selectedArea,
        districtTa,
        reason: 'Tamil district $districtTa ($districtEn): assistant must store the exact district without substituting another area',
      );
      expect(
        taReply,
        contains('பகுதி: $districtTa'),
        reason: 'Tamil district $districtTa ($districtEn): summary must display the requested district',
      );

      // Provider matching verification for Tamil:
      if (districtEn == 'Jaffna') {
        expect(
          engine.lastRecommendedProviders.isNotEmpty,
          isTrue,
          reason: 'Tamil district $districtTa must return matching demo mechanics',
        );
        expect(
          engine.lastRecommendedProviders.every((p) => p.service == 'Mechanic' && p.area == 'Jaffna'),
          isTrue,
          reason: 'Tamil district $districtTa: only providers covering Jaffna and matching Mechanic must be returned',
        );
        expect(
          taReply,
          contains('பொருந்தும் கற்பனை மாதிரி வழங்குநர்கள்'),
          reason: 'Tamil district $districtTa: must introduce matching demo providers',
        );
        expect(
          taReply,
          contains('Demo Mechanic A'),
          reason: 'Tamil district $districtTa: must include Demo Mechanic A',
        );
      } else {
        expect(
          engine.lastRecommendedProviders,
          isEmpty,
          reason: 'Tamil district $districtTa ($districtEn): no demo provider cards should be returned when there are no matching records',
        );
        expect(
          taReply,
          contains('$districtTa பகுதிக்கு கற்பனை மாதிரி'),
          reason: 'Tamil district $districtTa ($districtEn): reply must say there are no matching demo providers',
        );
        expect(
          taReply,
          contains('பட்டியலிடப்படவில்லை'),
          reason: 'Tamil district $districtTa ($districtEn): reply must indicate no demo providers listed',
        );
        expect(
          taReply,
          contains('உண்மையான வழங்குநர்கள் இல்லை என்று அர்த்தமல்ல'),
          reason: 'Tamil district $districtTa ($districtEn): reply must explain demo limitation',
        );
        expect(
          taReply,
          isNot(contains('Demo Mechanic A')),
          reason: 'Tamil district $districtTa ($districtEn): must not invent or present foreign providers as nearby',
        );
      }
    }
  });
}
