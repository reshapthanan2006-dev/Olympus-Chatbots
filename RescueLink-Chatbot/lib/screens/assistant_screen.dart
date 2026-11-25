import 'package:flutter/material.dart';
import 'package:rescuelink_assistant/services/rescuelink_ai.dart';
import 'package:rescuelink_assistant/services/rescuelink_faq.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key, this.aiService});

  final RescueLinkAiService? aiService;

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  // Brand color palette matching RescueLink LK reference
  static const Color kNavyText = Color(0xFF0A192F);
  static const Color kTeal = Color(0xFF00796B);
  static const Color kLightBg = Color(0xFFF4F9F9);
  static const Color kPaleAqua = Color(0xFFCCFBF1);
  static const Color kPaleAquaContainer = Color(0xFFE6F4F1);

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isSosExpanded = false;
  AppLanguage _currentLanguage = AppLanguage.en;

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text: RescueLinkFaq.getContent(_currentLanguage).welcomeMessage,
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty) return;

    final language = _currentLanguage;
    final message = ChatMessage(text: text, isUser: true);
    setState(() => _messages.add(message));
    _textController.clear();
    _scrollToBottom();

    final reply = await RescueLinkAssistant(aiService: widget.aiService)
        .reply(text, language);
    if (!mounted) return;
    setState(() {
      _messages.insert(
        _messages.indexOf(message) + 1,
        ChatMessage(text: reply, isUser: false),
      );
    });
    _scrollToBottom();
  }

  void _onTopicTap(TopicId topicId) {
    final label = RescueLinkFaq.getLabelForTopic(topicId, language: _currentLanguage);
    final reply = RescueLinkFaq.getReplyForTopic(topicId, language: _currentLanguage);

    setState(() {
      _messages.add(ChatMessage(text: label, isUser: true));
      _messages.add(ChatMessage(text: reply, isUser: false));
    });

    _scrollToBottom();
  }

  String _getSelectLanguageLabel(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.si:
        return 'භාෂාව තෝරන්න';
      case AppLanguage.ta:
        return 'மொழியைத் தேர்ந்தெடுக்கவும்';
      case AppLanguage.en:
        return 'Select language';
    }
  }

  Widget _buildLanguageDropdown() {
    return Semantics(
      label: _getSelectLanguageLabel(_currentLanguage),
      button: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
        decoration: BoxDecoration(
          color: kPaleAquaContainer,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: kTeal, width: 1.2),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<AppLanguage>(
            key: const Key('language_dropdown'),
            value: _currentLanguage,
            isDense: true,
            icon: const Icon(Icons.arrow_drop_down, color: kTeal, size: 20),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            style: const TextStyle(
              color: kNavyText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            onChanged: (AppLanguage? newLang) {
              if (newLang != null && newLang != _currentLanguage) {
                setState(() {
                  _currentLanguage = newLang;
                });
              }
            },
            items: const [
              DropdownMenuItem(
                value: AppLanguage.en,
                child: Text('English'),
              ),
              DropdownMenuItem(
                value: AppLanguage.si,
                child: Text('සිංහල'),
              ),
              DropdownMenuItem(
                value: AppLanguage.ta,
                child: Text('தமிழ்'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopicCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 9.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kPaleAqua, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: kTeal, size: 19),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: kNavyText,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForTopic(TopicId topicId) {
    switch (topicId) {
      case TopicId.requestHelp:
        return Icons.help_outline;
      case TopicId.disasterUpdates:
        return Icons.campaign_outlined;
      case TopicId.findShelters:
        return Icons.night_shelter_outlined;
      case TopicId.safetyGuide:
        return Icons.menu_book_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = RescueLinkFaq.getContent(_currentLanguage);

    return Scaffold(
      backgroundColor: kLightBg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'RescueLink LK Assistant',
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
      body: SafeArea(
        child: Column(
          children: [
            // Small accessible Language Selector bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.translate, size: 18, color: kTeal),
                  const SizedBox(width: 8),
                  Text(
                    'Language:',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const Spacer(),
                  _buildLanguageDropdown(),
                ],
              ),
            ),

            // Top safety warning banner
            Container(
              width: double.infinity,
              color: const Color(0xFFFFF3CD),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF856404), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      content.safetyBanner,
                      style: const TextStyle(
                        color: Color(0xFF856404),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Topics and SOS status container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 8.0),
              decoration: const BoxDecoration(
                color: kPaleAquaContainer,
                border: Border(
                  bottom: BorderSide(color: kPaleAqua, width: 1.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Four Quick Topics (rounded white cards, wrapping on narrow screens)
                  Semantics(
                    header: true,
                    child: Text(
                      content.quickTopicsHeader,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: kNavyText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 6.0,
                    children: RescueLinkFaq.quickTopicIds.map((topicId) {
                      final label = RescueLinkFaq.getLabelForTopic(
                        topicId,
                        language: _currentLanguage,
                      );
                      return _buildTopicCard(
                        title: label,
                        icon: _getIconForTopic(topicId),
                        onTap: () => _onTopicTap(topicId),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 8),

                  // Collapsible SOS status section (collapsed by default)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isSosExpanded = !_isSosExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(6.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            content.sosStatusHeader,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: kNavyText,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _isSosExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 18,
                            color: kNavyText,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isSosExpanded) ...[
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6.0,
                      runSpacing: 5.0,
                      children: RescueLinkFaq.sosQuestionIds.map((topicId) {
                        final label = RescueLinkFaq.getLabelForTopic(
                          topicId,
                          language: _currentLanguage,
                        );
                        return ActionChip(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: kPaleAqua, width: 1.2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 0),
                          label: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 12,
                              color: kNavyText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onPressed: () => _onTopicTap(topicId),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            // Chat messages list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _MessageBubble(message: message);
                },
              ),
            ),

            // Bottom message input area (remains accessible when keyboard opens)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('message_field'),
                      controller: _textController,
                      style: const TextStyle(color: kNavyText),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: kLightBg,
                        hintText: content.inputHint,
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(color: kTeal, width: 1.5),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 11.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  ElevatedButton.icon(
                    key: const Key('send_button'),
                    onPressed: () => _sendMessage(_textController.text),
                    icon: const Icon(Icons.send, size: 18, color: Colors.white),
                    label: Text(
                      content.sendButton,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final alignment = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bgColor = isUser ? const Color(0xFF00796B) : Colors.white;
    final textColor = isUser ? Colors.white : const Color(0xFF0A192F);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
            child: Text(
              isUser ? 'You' : 'Assistant',
              style: TextStyle(
                fontSize: 11,
                color: isUser ? const Color(0xFF00796B) : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.82,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: bgColor,
              border: isUser
                  ? null
                  : Border.all(color: const Color(0xFFCCFBF1), width: 1.0),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: Radius.circular(isUser ? 12 : 2),
                bottomRight: Radius.circular(isUser ? 2 : 12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
