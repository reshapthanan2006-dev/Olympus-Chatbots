import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/Screens/chat_screen.dart';
import 'package:my_first_app/Screens/launcher_screen.dart';
import 'package:my_first_app/main.dart';
import 'package:my_first_app/services/nearfix_chatbot_engine.dart';

Future<NearFixChatbotEngine> _createLoadedEngine() async {
  final engine = NearFixChatbotEngine();
  await engine.loadAssets();
  return engine;
}

Future<void> _pumpChatWithEngine(
  WidgetTester tester,
  NearFixChatbotEngine engine,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ChatScreen(engine: engine),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _sendChatMessage(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
  await tester.tap(find.byIcon(Icons.send));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _createLoadedEngine();
  });

  testWidgets(
    'NearFix chatbot opens with redesigned header, welcome shortcuts, and no language toggle',
    (tester) async {
      await tester.pumpWidget(const NearFixApp(home: ChatScreen()));
      await tester.pumpAndSettle();

      expect(find.text('NearFix Assistant'), findsOneWidget);
      expect(find.text('Customer Support'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // No manual language selector buttons.
      expect(find.text('English'), findsNothing);
      expect(find.text('தமிழ்'), findsNothing);

      // Bilingual welcome text.
      expect(find.textContaining('Welcome to NearFix'), findsOneWidget);
      expect(
        find.textContaining('NearFix மாதிரி உதவியாளருக்கு வரவேற்கிறோம்'),
        findsOneWidget,
      );

      // Functional quick questions.
      expect(find.text('What is NearFix?'), findsOneWidget);
      expect(find.text('What services are available?'), findsOneWidget);
      expect(find.text('How do I book a service?'), findsOneWidget);
      expect(find.text('Find a mechanic'), findsOneWidget);
    },
  );

  testWidgets('Tapping a suggested quick question sends a real message', (
    tester,
  ) async {
    final engine = await tester.runAsync(_createLoadedEngine);
    await _pumpChatWithEngine(tester, engine!);

    await tester.tap(find.text('What is NearFix?'));
    await tester.pumpAndSettle();

    expect(find.textContaining('proposed Sri Lankan app'), findsOneWidget);
  });

  testWidgets('Send button is disabled when input is empty and enabled with text', (
    tester,
  ) async {
    final engine = await tester.runAsync(_createLoadedEngine);
    await _pumpChatWithEngine(tester, engine!);

    final sendButtonFinder = find.widgetWithIcon(IconButton, Icons.send);
    expect(tester.widget<IconButton>(sendButtonFinder).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(tester.widget<IconButton>(sendButtonFinder).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'What is NearFix?');
    await tester.pump();
    expect(tester.widget<IconButton>(sendButtonFinder).onPressed, isNotNull);
  });

  testWidgets('Automatically detects English and Tamil in chat UI', (
    tester,
  ) async {
    final engine = await tester.runAsync(_createLoadedEngine);
    await _pumpChatWithEngine(tester, engine!);

    await _sendChatMessage(tester, 'What is NearFix?');
    expect(
      find.textContaining('proposed Sri Lankan app'),
      findsOneWidget,
    );

    await _sendChatMessage(tester, 'NearFix என்றால் என்ன?');
    expect(
      find.textContaining('திட்டமிடப்பட்ட இலங்கைச் செயலி'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Displays structured Demo Provider cards for mechanic -> Jaffna in English and Tamil',
    (tester) async {
      final engine = await tester.runAsync(_createLoadedEngine);
      await _pumpChatWithEngine(tester, engine!);

      await _sendChatMessage(tester, 'My bike is not starting');
      expect(find.textContaining('Which town or area'), findsOneWidget);

      await _sendChatMessage(tester, 'Jaffna');
      expect(find.text('Demo Mechanic A'), findsOneWidget);
      expect(find.text('Demo Mechanic B'), findsOneWidget);
      expect(find.text('Demo Provider'), findsNWidgets(2));
      expect(
        find.text('Motorcycle battery and engine checks'),
        findsOneWidget,
      );
      expect(find.text('General vehicle repair'), findsOneWidget);
    },
  );

  testWidgets(
    'Preserves conversation memory when short follow-up or language switch occurs',
    (tester) async {
      final engine = await tester.runAsync(_createLoadedEngine);
      await _pumpChatWithEngine(tester, engine!);

      await _sendChatMessage(tester, 'என்னுடைய பைக் ஸ்டார்ட் ஆகவில்லை.');
      expect(
        find.textContaining('எந்த ஊர் அல்லது பகுதியில் உதவி தேவை'),
        findsOneWidget,
      );

      // Short follow-up "Jaffna" inherits established Tamil conversation language.
      await _sendChatMessage(tester, 'Jaffna');
      expect(find.text('Demo Mechanic A'), findsOneWidget);
      expect(find.text('Demo Mechanic B'), findsOneWidget);
      expect(find.text('மாதிரி வழங்குநர்'), findsNWidgets(2));

      // Switching clearly to English keeps conversation memory and answers in English.
      await _sendChatMessage(tester, 'Are the suggested providers real?');
      expect(
        find.textContaining('fictional records for testing'),
        findsOneWidget,
      );
      expect(engine.selectedServiceId, 'mechanic');
      expect(engine.problemDetail, 'என்னுடைய பைக் ஸ்டார்ட் ஆகவில்லை.');
      expect(engine.selectedArea, 'Jaffna');
      expect(engine.chatStage, 'done');

      await _sendChatMessage(tester, 'providers');
      expect(find.text('Demo Mechanic A'), findsAtLeastNWidgets(1));
    },
  );

  testWidgets('Handles ambiguous battery clarification in UI', (tester) async {
    final engine = await tester.runAsync(_createLoadedEngine);
    await _pumpChatWithEngine(tester, engine!);

    await _sendChatMessage(tester, 'My battery is dead');
    expect(
      find.textContaining('vehicle (car/motorcycle) or a mobile phone'),
      findsOneWidget,
    );

    await _sendChatMessage(tester, 'bike');
    expect(find.textContaining('Which town or area'), findsOneWidget);

    await _sendChatMessage(tester, 'Jaffna');
    expect(find.text('Demo Mechanic A'), findsOneWidget);
    expect(find.text('Demo Provider'), findsNWidgets(2));
  });

  testWidgets('Shows banner fallback in ChatScreen if an asset fails to load', (
    tester,
  ) async {
    final engine = NearFixChatbotEngine()
      ..faqLoadError = NearFixChatbotEngine.faqAssetPath;
    await _pumpChatWithEngine(tester, engine);

    expect(
      find.textContaining('assets/nearfix_faq_en_ta.json'),
      findsOneWidget,
    );
  });

  testWidgets('Renders cleanly on narrow mobile and wide desktop screens', (
    tester,
  ) async {
    final engine = await tester.runAsync(_createLoadedEngine);

    // Narrow mobile screen (360x640).
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpChatWithEngine(tester, engine!);
    expect(find.text('NearFix Assistant'), findsOneWidget);

    // Wide desktop screen (1280x800).
    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpAndSettle();
    expect(find.text('NearFix Assistant'), findsOneWidget);
    expect(find.text('Customer Support'), findsOneWidget);
  });

  testWidgets(
    'Renders long English and Tamil FAQ responses and tight mobile keyboard layout without overflow',
    (tester) async {
      final engine = await tester.runAsync(_createLoadedEngine);
      tester.view.physicalSize = const Size(360, 380);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpChatWithEngine(tester, engine!);
      expect(tester.takeException(), isNull);

      // Long English FAQ response (NF-FAQ-025).
      await _sendChatMessage(tester, 'How do I book a service?');
      expect(find.textContaining('choose service, describe problem'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Long Tamil FAQ response (NF-FAQ-004).
      await _sendChatMessage(tester, 'என்னென்ன சேவைகள் உள்ளன?');
      expect(find.textContaining('வாகனப் பழுதுபார்ப்பு'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Tapping a Tamil Service Shortcut updates correctly without overflow.
      await tester.ensureVisible(find.text('குழாய்ப்பணி'));
      await tester.tap(find.text('குழாய்ப்பணி'));
      await tester.pumpAndSettle();
      expect(find.textContaining('குறிப்பிட்ட பிரச்சினையை விவரிக்கவும்'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Switching service shortcut during problem and location stages preserves chat history and asks correct next question',
    (tester) async {
      final engine = await tester.runAsync(_createLoadedEngine);
      await _pumpChatWithEngine(tester, engine!);

      // Start Mechanic in problem stage by tapping Mechanic chip.
      await tester.ensureVisible(find.text('Mechanic'));
      await tester.tap(find.text('Mechanic'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('This looks like a Mechanic / Vehicle Repair request'),
        findsOneWidget,
      );
      expect(engine.chatStage, 'problem');

      // Switch to Plumber during problem stage by tapping Plumber chip.
      await tester.ensureVisible(find.text('Plumber'));
      await tester.tap(find.text('Plumber'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('This looks like a Plumbing request'),
        findsOneWidget,
      );
      // History preserved: earlier Mechanic prompt and user bubble remain visible.
      expect(find.text('I need a mechanic'), findsOneWidget);
      expect(find.text('I need a plumber'), findsOneWidget);
      expect(engine.selectedServiceId, 'plumber');
      expect(engine.problemDetail, isNull);
      expect(engine.chatStage, 'problem');

      // Enter Plumber problem -> now in location (area) stage, then tap Electrician shortcut.
      await _sendChatMessage(tester, 'Kitchen pipe is leaking');
      expect(find.textContaining('Which town or area do you need Plumbing help in?'), findsOneWidget);
      expect(engine.chatStage, 'area');

      await tester.ensureVisible(find.text('Electrician'));
      await tester.tap(find.text('Electrician'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('This looks like a Electrical Work request'),
        findsOneWidget,
      );
      expect(find.text('Kitchen pipe is leaking'), findsOneWidget);
      expect(engine.selectedServiceId, 'electrician');
      expect(engine.problemDetail, isNull);
      expect(engine.selectedArea, isNull);
      expect(engine.chatStage, 'problem');
    },
  );

  testWidgets(
    'Launcher opens first, floating action button opens NearFix Assistant chat screen, and Back returns to launcher',
    (tester) async {
      await tester.pumpWidget(const NearFixApp());
      await tester.pumpAndSettle();

      // Confirms the launcher appears
      expect(find.byType(NearFixLauncherScreen), findsOneWidget);
      expect(find.text('NearFix'), findsOneWidget);
      expect(find.text('Prototype'), findsOneWidget);
      expect(find.byType(ChatScreen), findsNothing);

      // Confirms button properties and taps "Open NearFix Assistant"
      final openAssistantFinder = find.byTooltip('Open NearFix Assistant');
      expect(openAssistantFinder, findsOneWidget);
      expect(find.bySemanticsLabel('Open NearFix Assistant'), findsAtLeastNWidgets(1));
      expect(find.byType(FloatingActionButton), findsOneWidget);

      await tester.tap(openAssistantFinder);
      await tester.pumpAndSettle();

      // Confirms ChatScreen opens
      expect(find.byType(ChatScreen), findsOneWidget);
      expect(find.text('NearFix Assistant'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Verifies Back returns to the launcher
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(NearFixLauncherScreen), findsOneWidget);
      expect(find.byType(ChatScreen), findsNothing);
      expect(find.text('NearFix'), findsOneWidget);
    },
  );
}
