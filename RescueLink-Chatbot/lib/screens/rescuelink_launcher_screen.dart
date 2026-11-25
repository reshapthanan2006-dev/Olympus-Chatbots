import 'package:flutter/material.dart';
import 'package:rescuelink_assistant/screens/assistant_screen.dart';

class RescueLinkLauncherScreen extends StatelessWidget {
  const RescueLinkLauncherScreen({super.key});

  static const Color kNavyText = Color(0xFF0A192F);
  static const Color kTeal = Color(0xFF00796B);
  static const Color kLightBg = Color(0xFFF4F9F9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'RescueLink LK',
          style: TextStyle(
            color: kNavyText,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: const Text(
                  'Prototype',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: const SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shield_outlined,
                size: 64,
                color: kTeal,
              ),
              SizedBox(height: 16),
              Text(
                'RescueLink LK',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: kNavyText,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Emergency coordination & offline assistant prototype',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        key: const Key('assistant_launcher_button'),
        backgroundColor: kTeal,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        tooltip: 'Open RescueLink LK Assistant',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AssistantScreen(),
            ),
          );
        },
        child: Semantics(
          label: 'Open RescueLink LK Assistant',
          child: ClipOval(
            child: Image.asset(
              'assets/rescuelink_assistant_icon.png',
              width: 56.0,
              height: 56.0,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
