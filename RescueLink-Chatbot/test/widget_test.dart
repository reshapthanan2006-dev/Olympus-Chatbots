import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rescuelink_assistant/main.dart';
import 'package:rescuelink_assistant/screens/assistant_screen.dart';
import 'package:rescuelink_assistant/services/rescuelink_faq.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Launcher Navigation Tests
  // ---------------------------------------------------------------------------
  testWidgets(
      'App starts on launcher, opens AssistantScreen on FAB tap, and returns on Back',
      (WidgetTester tester) async {
    // 1. Starts the app on default home (RescueLinkLauncherScreen)
    await tester.pumpWidget(const MyApp());

    // 2. Confirms the launcher appears first
    expect(find.text('RescueLink LK'), findsAtLeastNWidgets(1));
    expect(find.text('Prototype'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byTooltip('Open RescueLink LK Assistant'), findsOneWidget);
    expect(find.text('RescueLink LK Assistant'), findsNothing);

    // 3. Taps the round FloatingActionButton in bottom-right corner
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // 4. Confirms AssistantScreen opens
    expect(find.text('RescueLink LK Assistant'), findsOneWidget);
    expect(find.text('This chat cannot send an SOS.'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);

    // 5. Verifies Back returns to the launcher
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Confirms we returned to launcher
    expect(find.text('RescueLink LK Assistant'), findsNothing);
    expect(find.text('RescueLink LK'), findsAtLeastNWidgets(1));
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // Also verify Android system back gesture/button returns to launcher
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('RescueLink LK Assistant'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('RescueLink LK Assistant'), findsNothing);
    expect(find.text('RescueLink LK'), findsAtLeastNWidgets(1));
  });

  // ---------------------------------------------------------------------------
  // Existing English Tests
  // ---------------------------------------------------------------------------
  testWidgets(
      'Chat opens with title, exactly one prototype label, notice, topic cards, and collapsed SOS section',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(home: AssistantScreen()));

    // Verify title, single prototype label, and top warning notice
    expect(find.text('RescueLink LK Assistant'), findsOneWidget);
    expect(find.text('Prototype'), findsOneWidget);
    expect(find.text('This chat cannot send an SOS.'), findsOneWidget);

    // Verify language selector dropdown is present with English selected by default
    expect(find.byType(DropdownButton<AppLanguage>), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<AppLanguage>));
    await tester.pumpAndSettle();
    expect(find.text('සිංහල'), findsOneWidget);
    expect(find.text('தமிழ்'), findsOneWidget);
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();

    // Verify the four quick topics
    expect(find.text('Quick Topics'), findsOneWidget);
    expect(find.text('Request Help'), findsOneWidget);
    expect(find.text('Disaster Updates'), findsOneWidget);
    expect(find.text('Find Shelters'), findsOneWidget);
    expect(find.text('Safety Guide'), findsOneWidget);

    // Verify SOS status section header is visible, but questions are collapsed by default
    expect(find.text('SOS status'), findsOneWidget);
    expect(find.text('What does Not sent mean?'), findsNothing);
    expect(find.text('Does server receipt mean help is on the way?'), findsNothing);
    expect(find.text('Can this chat send an SOS?'), findsNothing);

    // Verify message input field and Send button
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
  });

  testWidgets('"Request Help" topic shows planned reporting feature reply and does not submit report',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(home: AssistantScreen()));

    await tester.tap(find.text('Request Help'));
    await tester.pumpAndSettle();

    expect(find.textContaining('planned Request Help feature'), findsOneWidget);
    expect(find.textContaining('This prototype does not submit a report'), findsOneWidget);
  });

  testWidgets('"Disaster Updates" topic shows it does not show live alerts and refers to official updates',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(home: AssistantScreen()));

    await tester.tap(find.text('Disaster Updates'));
    await tester.pumpAndSettle();

    expect(find.textContaining('This prototype does not show live alerts'), findsOneWidget);
    expect(find.textContaining('official updates'), findsOneWidget);
  });

  testWidgets('"Find Shelters" topic explains no verified live shelter list and no location requested',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(home: AssistantScreen()));

    await tester.tap(find.text('Find Shelters'));
    await tester.pumpAndSettle();

    expect(find.textContaining('This prototype has no verified live shelter list'), findsOneWidget);
    expect(find.textContaining('do not ask for your location'), findsOneWidget);
  });

  testWidgets('"Safety Guide" topic explains preparing, responding, and recovering and no situation-specific instructions',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(home: AssistantScreen()));

    await tester.tap(find.text('Safety Guide'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('preparing for, responding to, and recovering from a disaster'),
      findsOneWidget,
    );
    expect(
      find.textContaining('does not generate situation-specific safety instructions'),
      findsOneWidget,
    );
  });

  testWidgets('SOS status section expands and "Not sent" shortcut shows the correct reply',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(home: AssistantScreen()));

    // Expand the collapsed SOS status section
    await tester.tap(find.text('SOS status'));
    await tester.pumpAndSettle();

    // Verify question is now visible
    expect(find.text('What does Not sent mean?'), findsOneWidget);

    // Tap the question
    await tester.tap(find.text('What does Not sent mean?'));
    await tester.pumpAndSettle();

    // Verify that the reply explains offline SOS stays "Not sent" until server acknowledges it
    expect(find.textContaining('Not sent'), findsAtLeastNWidgets(1));
    expect(find.textContaining('until the server acknowledges'), findsOneWidget);
    expect(find.textContaining('**"Not sent"**'), findsNothing);
    expect(find.textContaining('does not mean help was dispatched'), findsOneWidget);
    expect(find.textContaining('This prototype chat does not store or send an SOS'), findsOneWidget);
  });

  testWidgets('SOS status section expands and server receipt reply is short and accurate',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(home: AssistantScreen()));

    // Expand the collapsed SOS status section
    await tester.tap(find.text('SOS status'));
    await tester.pumpAndSettle();

    // Tap "Does server receipt mean help is on the way?"
    await tester.tap(find.text('Does server receipt mean help is on the way?'));
    await tester.pumpAndSettle();

    // Verify the short receipt reply
    expect(
      find.textContaining('Server acknowledgment only confirms receipt'),
      findsOneWidget,
    );
    expect(
      find.textContaining('does not mean anyone has been dispatched or that help is on the way'),
      findsOneWidget,
    );
  });

  testWidgets('SOS status section expands and "Can this chat send an SOS?" does not instruct using non-existent SOS button',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(home: AssistantScreen()));

    // Expand the collapsed SOS status section
    await tester.tap(find.text('SOS status'));
    await tester.pumpAndSettle();

    // Tap "Can this chat send an SOS?"
    await tester.tap(find.text('Can this chat send an SOS?'));
    await tester.pumpAndSettle();

    expect(find.textContaining('This prototype chat cannot send an SOS'), findsOneWidget);
    // Confirm no instructions for a non-existent dedicated SOS button
    expect(find.textContaining('dedicated SOS submission button'), findsNothing);
  });

  testWidgets('Immediate danger message shows fixed warning to contact emergency services',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(home: AssistantScreen()));

    await tester.enterText(
      find.byType(TextField),
      'Help me, I am in immediate danger and trapped in rising flood water!',
    );
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(find.textContaining('do not wait for this chat'), findsOneWidget);
    expect(find.textContaining('official emergency services'), findsOneWidget);
  });

  testWidgets('An unrelated typed question gets the scope reply',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(home: AssistantScreen()));

    // Enter an unrelated typed question
    await tester.enterText(
      find.byType(TextField),
      'What is the recipe for chocolate cake?',
    );
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    // Verify scope reply and that available topics are displayed
    expect(
      find.textContaining('only answer questions about RescueLink LK'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Available topics: Request Help, Disaster Updates'),
      findsOneWidget,
    );
  });

  // ---------------------------------------------------------------------------
  // Localization Tests: Language Switching & Dropdown
  // ---------------------------------------------------------------------------
  Future<void> selectLanguageFromDropdown(
      WidgetTester tester, String language) async {
    await tester.tap(find.byType(DropdownButton<AppLanguage>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(language).last);
    await tester.pumpAndSettle();
  }

  testWidgets(
      'Language selector switches between English, Sinhala, and Tamil updating controls, topics, and banner',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(home: AssistantScreen()));

    // 1. Initial English state: closed dropdown displays English with accessible label
    expect(find.byType(DropdownButton<AppLanguage>), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.bySemanticsLabel('Select language'), findsOneWidget);
    expect(find.text('This chat cannot send an SOS.'), findsOneWidget);
    expect(find.text('Request Help'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);

    // Initial welcome message is in English
    expect(find.textContaining('Welcome to the RescueLink LK Assistant.'), findsOneWidget);

    // 2. Open dropdown and switch to Sinhala
    await tester.tap(find.byType(DropdownButton<AppLanguage>));
    await tester.pumpAndSettle();
    expect(find.text('සිංහල'), findsOneWidget);
    await tester.tap(find.text('සිංහල').last);
    await tester.pumpAndSettle();

    // Verify selected language appears in closed dropdown
    expect(find.text('සිංහල'), findsOneWidget);
    expect(find.text('English'), findsNothing);
    expect(find.bySemanticsLabel('භාෂාව තෝරන්න'), findsOneWidget);

    // Verify earlier messages are preserved without clearing
    expect(find.textContaining('Welcome to the RescueLink LK Assistant.'), findsOneWidget);

    // Verify interface updates to Sinhala
    expect(
      find.textContaining('මෙම චැට් මගින් SOS යැවිය නොහැක. [Draft - pending fluent review]'),
      findsOneWidget,
    );
    expect(find.text('උදව් ඉල්ලන්න'), findsOneWidget);
    expect(find.text('ආපදා යාවත්කාලීන'), findsOneWidget);
    expect(find.text('SOS තත්ත්වය'), findsOneWidget);
    expect(find.text('යවන්න'), findsOneWidget);

    // 3. Open dropdown and switch to Tamil
    await tester.tap(find.byType(DropdownButton<AppLanguage>));
    await tester.pumpAndSettle();
    expect(find.text('தமிழ்'), findsOneWidget);
    await tester.tap(find.text('தமிழ்').last);
    await tester.pumpAndSettle();

    // Verify selected language appears in closed dropdown
    expect(find.text('தமிழ்'), findsOneWidget);
    expect(find.text('සිංහල'), findsNothing);
    expect(find.bySemanticsLabel('மொழியைத் தேர்ந்தெடுக்கவும்'), findsOneWidget);

    // Verify earlier messages still preserved
    expect(find.textContaining('Welcome to the RescueLink LK Assistant.'), findsOneWidget);

    // Verify interface updates to Tamil
    expect(
      find.textContaining('இந்த அரட்டை மூலம் SOS அனுப்ப முடியாது. [Draft - pending fluent review]'),
      findsOneWidget,
    );
    expect(find.text('உதவி கோரவும்'), findsOneWidget);
    expect(find.text('பேரிடர் புதுப்பிப்புகள்'), findsOneWidget);
    expect(find.text('SOS நிலை'), findsOneWidget);
    expect(find.text('அனுப்பு'), findsOneWidget);

    // 4. Open dropdown and switch back to English
    await tester.tap(find.byType(DropdownButton<AppLanguage>));
    await tester.pumpAndSettle();
    expect(find.text('English'), findsWidgets);
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();

    // Verify selected language appears in closed dropdown
    expect(find.text('English'), findsOneWidget);
    expect(find.text('தமிழ்'), findsNothing);
    expect(find.bySemanticsLabel('Select language'), findsOneWidget);

    // Verify interface updates back to English
    expect(find.text('This chat cannot send an SOS.'), findsOneWidget);
    expect(find.text('Request Help'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
  });

  testWidgets('Language dropdown fits on narrow screen without layout overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await tester.pumpWidget(const MyApp(home: AssistantScreen()));
    expect(tester.takeException(), isNull);
    expect(find.byType(DropdownButton<AppLanguage>), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Localization Tests: SOS Replies in Each Language
  // ---------------------------------------------------------------------------
  testWidgets('Opening an SOS reply in Sinhala displays localized reply with draft review note',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(home: AssistantScreen()));

    // Switch to Sinhala via dropdown
    await selectLanguageFromDropdown(tester, 'සිංහල');

    // Expand SOS status in Sinhala
    await tester.tap(find.text('SOS තත්ත්වය'));
    await tester.pumpAndSettle();

    // Tap the Sinhala "Not sent" question
    await tester.tap(find.text('"Not sent" යන්නෙන් අදහස් කරන්නේ කුමක්ද?'));
    await tester.pumpAndSettle();

    // Verify reply contains draft review note and preserved meaning
    expect(find.textContaining('[Draft - pending fluent review]'), findsAtLeastNWidgets(1));
    expect(find.textContaining('Not sent'), findsAtLeastNWidgets(1));
    expect(find.textContaining('**"Not sent"**'), findsNothing);
    expect(find.textContaining('සේවාදායකය'), findsOneWidget);
  });

  testWidgets('Opening an SOS reply in Tamil displays localized reply with draft review note',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(home: AssistantScreen()));

    // Switch to Tamil via dropdown
    await selectLanguageFromDropdown(tester, 'தமிழ்');

    // Expand SOS status in Tamil
    await tester.tap(find.text('SOS நிலை'));
    await tester.pumpAndSettle();

    // Tap the Tamil "Not sent" question
    await tester.tap(find.text('"Not sent" என்பதன் பொருள் என்ன?'));
    await tester.pumpAndSettle();

    // Verify reply contains draft review note and explains that offline SOS remains "Not sent" until server acknowledgment
    expect(
      find.descendant(
        of: find.byType(ListView),
        matching: find.textContaining(
          '[Draft - pending fluent review] சர்வர் உறுதிப்படுத்தும் வரை ஆஃப்லைன் SOS "Not sent"',
        ),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('**"Not sent"**'), findsNothing);
  });

  testWidgets('Opening Server receipt and Can Chat Send SOS in Sinhala preserves safety meaning',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(home: AssistantScreen()));

    await selectLanguageFromDropdown(tester, 'සිංහල');

    await tester.tap(find.text('SOS තත්ත්වය'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('සේවාදායක ලැබීමෙන් උපකාර පැමිණෙන බව අදහස් වේද?'));
    await tester.pumpAndSettle();

    // Verify server receipt does not mean dispatched
    expect(find.textContaining('කිසිවකු පිටත් කර යවා ඇති බවක්'), findsOneWidget);

    await tester.tap(find.text('මෙම චැට් එකෙන් SOS යැවිය හැකිද?'));
    await tester.pumpAndSettle();

    // Verify cannot send SOS
    expect(find.textContaining('මූලාකෘති චැට් මඟින් SOS යැවිය නොහැක'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Localization Tests: Emergency Warning in Selected Language
  // ---------------------------------------------------------------------------
  testWidgets('Emergency warning is displayed in Sinhala when in danger',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(home: AssistantScreen()));

    await selectLanguageFromDropdown(tester, 'සිංහල');

    await tester.enterText(
      find.byType(TextField),
      'උදව් කරන්න, මම අනතුරේ!',
    );
    await tester.tap(find.text('යවන්න'));
    await tester.pumpAndSettle();

    expect(find.textContaining('[Draft - pending fluent review]'), findsAtLeastNWidgets(1));
    expect(find.textContaining('නිල හදිසි සේවාවන් අමතන්න'), findsOneWidget);
  });

  testWidgets('Emergency warning is displayed in Tamil when in danger',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(home: AssistantScreen()));

    await selectLanguageFromDropdown(tester, 'தமிழ்');

    await tester.enterText(
      find.byType(TextField),
      'காப்பாற்றுங்கள், ஆபத்து!',
    );
    await tester.tap(find.text('அனுப்பு'));
    await tester.pumpAndSettle();

    expect(find.textContaining('[Draft - pending fluent review]'), findsAtLeastNWidgets(1));
    expect(find.textContaining('அதிகாரப்பூர்வ அவசர சேவைகளைத் தொடர்பு கொள்ளவும்'), findsOneWidget);
  });

  testWidgets('Unmatched query in Sinhala displays available topics instead of guessing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(home: AssistantScreen()));

    await selectLanguageFromDropdown(tester, 'සිංහල');

    await tester.enterText(
      find.byType(TextField),
      'චොකලට් කේක් හදන්නේ කොහොමද?',
    );
    await tester.tap(find.text('යවන්න'));
    await tester.pumpAndSettle();

    expect(find.textContaining('පවතින මාතෘකා: උදව් ඉල්ලන්න, ආපදා යාවත්කාලීන'), findsOneWidget);
  });
}
