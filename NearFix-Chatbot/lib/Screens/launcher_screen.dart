import 'package:flutter/material.dart';

import 'chat_screen.dart';

/// Minimal launcher screen for the NearFix prototype.
///
/// Serves as the app's first screen with off-white background and dark navy text,
/// displaying the NearFix brand name and a Prototype indicator, alongside an
/// orange round FloatingActionButton that opens the NearFix customer support assistant.
class NearFixLauncherScreen extends StatelessWidget {
  const NearFixLauncherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NearFixColors.offWhite,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // NearFix Brand Title
              const Text(
                'NearFix',
                style: TextStyle(
                  color: NearFixColors.darkNavy,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              // Prototype Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: NearFixColors.softCream,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: NearFixColors.primaryOrange.withValues(alpha: 0.5),
                  ),
                ),
                child: const Text(
                  'Prototype',
                  style: TextStyle(
                    color: NearFixColors.deepOrange,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Nearby Everyday Commercial Services',
                style: TextStyle(
                  color: NearFixColors.darkNavy.withValues(alpha: 0.65),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Semantics(
        label: 'Open NearFix Assistant',
        button: true,
        child: FloatingActionButton(
          tooltip: 'Open NearFix Assistant',
          shape: const CircleBorder(),
          backgroundColor: NearFixColors.primaryOrange,
          elevation: 4,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ChatScreen(),
              ),
            );
          },
          child: ClipOval(
            child: SizedBox.expand(
              child: Image.asset(
                'assets/nearfix_assistant_icon.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

