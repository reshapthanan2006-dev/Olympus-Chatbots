import 'package:flutter/material.dart';

import '../services/nearfix_chatbot_engine.dart';

/// NearFix brand colour palette.
abstract final class NearFixColors {
  static const Color primaryOrange = Color(0xFFEA900B);
  static const Color goldenYellow = Color(0xFFF8B51E);
  static const Color deepOrange = Color(0xFFD9780A);
  static const Color darkNavy = Color(0xFF161B35);
  static const Color offWhite = Color(0xFFF9F8F5);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color softCream = Color(0xFFFBF2E9);
  static const Color mutedGrey = Color(0xFF777B86);
}

class _ChatMessage {
  final bool isUser;
  final String text;
  final List<DemoProvider> providers;
  final String? serviceCategory;
  final String? introText;
  final String? footerText;
  final bool isTamil;

  const _ChatMessage({
    required this.isUser,
    required this.text,
    this.providers = const [],
    this.serviceCategory,
    this.introText,
    this.footerText,
    this.isTamil = false,
  });
}

class _ShortcutItem {
  final String labelEn;
  final String labelTa;
  final String queryEn;
  final String queryTa;
  final IconData icon;
  final String? serviceId;

  const _ShortcutItem({
    required this.labelEn,
    required this.labelTa,
    required this.queryEn,
    required this.queryTa,
    required this.icon,
    this.serviceId,
  });
}

class ChatScreen extends StatefulWidget {
  final NearFixChatbotEngine? engine;

  const ChatScreen({super.key, this.engine});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final NearFixChatbotEngine _engine;
  final List<_ChatMessage> _messages = [];
  bool _canSend = false;

  static const List<_ShortcutItem> _quickQuestions = [
    _ShortcutItem(
      labelEn: 'What is NearFix?',
      labelTa: 'NearFix என்றால் என்ன?',
      queryEn: 'What is NearFix?',
      queryTa: 'NearFix என்றால் என்ன?',
      icon: Icons.info_outline_rounded,
    ),
    _ShortcutItem(
      labelEn: 'What services are available?',
      labelTa: 'என்னென்ன சேவைகள் உள்ளன?',
      queryEn: 'What services are available?',
      queryTa: 'என்னென்ன சேவைகள் உள்ளன?',
      icon: Icons.category_outlined,
    ),
    _ShortcutItem(
      labelEn: 'How do I book a service?',
      labelTa: 'சேவையை எப்படி முன்பதிவு செய்வது?',
      queryEn: 'How do I book a service?',
      queryTa: 'சேவையை எப்படி முன்பதிவு செய்வது?',
      icon: Icons.event_note_outlined,
    ),
    _ShortcutItem(
      labelEn: 'Find a mechanic',
      labelTa: 'மெக்கானிக் தேவை',
      queryEn: 'Find a mechanic',
      queryTa: 'எனக்கு மெக்கானிக் தேவை',
      icon: Icons.build_circle_outlined,
      serviceId: 'mechanic',
    ),
  ];

  static const List<_ShortcutItem> _serviceShortcuts = [
    _ShortcutItem(
      labelEn: 'Mechanic',
      labelTa: 'வாகனப் பழுது',
      queryEn: 'I need a mechanic',
      queryTa: 'எனக்கு மெக்கானிக் தேவை',
      icon: Icons.two_wheeler_rounded,
      serviceId: 'mechanic',
    ),
    _ShortcutItem(
      labelEn: 'Plumber',
      labelTa: 'குழாய்ப்பணி',
      queryEn: 'I need a plumber',
      queryTa: 'எனக்கு குழாய்ப்பணி தேவை',
      icon: Icons.plumbing_rounded,
      serviceId: 'plumber',
    ),
    _ShortcutItem(
      labelEn: 'Electrician',
      labelTa: 'மின்சார வேலை',
      queryEn: 'I need an electrician',
      queryTa: 'எனக்கு மின்சார நிபுணர் தேவை',
      icon: Icons.electrical_services_rounded,
      serviceId: 'electrician',
    ),
    _ShortcutItem(
      labelEn: 'AC Repair',
      labelTa: 'ஏசி பழுது',
      queryEn: 'I need AC repair',
      queryTa: 'ஏசி பழுதுபார்ப்பு தேவை',
      icon: Icons.ac_unit_rounded,
      serviceId: 'ac',
    ),
    _ShortcutItem(
      labelEn: 'Locksmith',
      labelTa: 'பூட்டு வேலை',
      queryEn: 'I need a locksmith',
      queryTa: 'பூட்டு வேலை தேவை',
      icon: Icons.key_rounded,
      serviceId: 'locksmith',
    ),
    _ShortcutItem(
      labelEn: 'Carpenter',
      labelTa: 'தச்சு வேலை',
      queryEn: 'I need a carpenter',
      queryTa: 'தச்சு வேலை தேவை',
      icon: Icons.handyman_rounded,
      serviceId: 'carpenter',
    ),
    _ShortcutItem(
      labelEn: 'Cleaning',
      labelTa: 'சுத்தம் செய்தல்',
      queryEn: 'I need cleaning',
      queryTa: 'சுத்தம் செய்தல் தேவை',
      icon: Icons.cleaning_services_rounded,
      serviceId: 'cleaning',
    ),
    _ShortcutItem(
      labelEn: 'Phone Repair',
      labelTa: 'கைபேசி பழுது',
      queryEn: 'I need phone repair',
      queryTa: 'கைபேசி பழுதுபார்ப்பு தேவை',
      icon: Icons.smartphone_rounded,
      serviceId: 'phone_repair',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _engine = widget.engine ?? NearFixChatbotEngine();
    _controller.addListener(_onInputChanged);
    if (widget.engine == null) {
      _loadAssets();
    }
  }

  void _onInputChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _canSend) {
      setState(() {
        _canSend = hasText;
      });
    }
  }

  Future<void> _loadAssets() async {
    await _engine.loadAssets();
    if (!mounted) return;
    setState(() {});
  }

  void _sendMessage([String? presetText, String? serviceShortcutId]) async {
    final message = (presetText ?? _controller.text).trim();
    if (message.isEmpty) return;

    if (presetText == null) {
      _controller.clear();
    }

    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: message));
    });
    _scrollToLatest();

    String reply;
    if (serviceShortcutId != null) {
      reply = _engine.selectServiceShortcut(message, serviceId: serviceShortcutId);
    } else {
      reply = await _engine.getBotReplyAsync(message);
    }

    final providers = _engine.lastRecommendedProviders;
    final intro = _engine.lastRecommendationIntro;
    final footer = _engine.lastRecommendationFooter;
    final serviceCategory = _engine.lastRecommendedServiceName;
    final isTamilReply = _engine.language == ChatLanguage.ta;

    if (!mounted) return;
    setState(() {
      _messages.add(
        _ChatMessage(
          isUser: false,
          text: reply,
          providers: providers,
          serviceCategory: serviceCategory,
          introText: intro,
          footerText: footer,
          isTamil: isTamilReply,
        ),
      );
    });

    _scrollToLatest();
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onInputChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildHeader(bool isDesktopLayout) {
    final isTamil = _engine.language == ChatLanguage.ta;
    return Container(
      decoration: BoxDecoration(
        color: NearFixColors.darkNavy,
        borderRadius: isDesktopLayout
            ? const BorderRadius.vertical(top: Radius.circular(24))
            : const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: const Border(
          bottom: BorderSide(
            color: NearFixColors.primaryOrange,
            width: 3,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  NearFixColors.goldenYellow,
                  NearFixColors.primaryOrange,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: NearFixColors.primaryOrange.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: NearFixColors.darkNavy,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _engine.appTitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: NearFixColors.pureWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: NearFixColors.goldenYellow,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Customer Support',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: NearFixColors.softCream.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: NearFixColors.primaryOrange.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: NearFixColors.goldenYellow.withValues(alpha: 0.65),
              ),
            ),
            child: Text(
              isTamil ? 'மாதிரி' : 'Prototype',
              style: const TextStyle(
                color: NearFixColors.goldenYellow,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final isTamil = _engine.language == ChatLanguage.ta;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NearFixColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: NearFixColors.primaryOrange.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: NearFixColors.darkNavy.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: NearFixColors.softCream,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.handyman_rounded,
                  color: NearFixColors.deepOrange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTamil
                          ? 'NearFix வாடிக்கையாளர் உதவி'
                          : 'NearFix Customer Assistant',
                      style: const TextStyle(
                        color: NearFixColors.darkNavy,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      isTamil
                          ? 'தமிழ் & English • தானியங்கி மொழி கண்டறிதல்'
                          : 'Ask in English or தமிழ் — detected automatically',
                      style: const TextStyle(
                        color: NearFixColors.mutedGrey,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: NearFixColors.softCream,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _engine.initialGreeting,
              style: const TextStyle(
                color: NearFixColors.darkNavy,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isTamil ? 'விரைவு கேள்விகள்' : 'Quick Questions',
            style: const TextStyle(
              color: NearFixColors.darkNavy,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickQuestions.map((item) {
              final label = isTamil ? item.labelTa : item.labelEn;
              final query = isTamil ? item.queryTa : item.queryEn;
              return ActionChip(
                avatar: Icon(
                  item.icon,
                  size: 16,
                  color: NearFixColors.darkNavy,
                ),
                label: Text(
                  label,
                  style: const TextStyle(
                    color: NearFixColors.darkNavy,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: NearFixColors.goldenYellow.withValues(alpha: 0.24),
                side: BorderSide(
                  color: NearFixColors.primaryOrange.withValues(alpha: 0.55),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onPressed: () => _sendMessage(query, item.serviceId),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text(
            isTamil ? 'சேவை வகைகள்' : 'Service Shortcuts',
            style: const TextStyle(
              color: NearFixColors.darkNavy,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _serviceShortcuts.map((item) {
              final label = isTamil ? item.labelTa : item.labelEn;
              final query = isTamil ? item.queryTa : item.queryEn;
              return ActionChip(
                avatar: Icon(
                  item.icon,
                  size: 16,
                  color: NearFixColors.deepOrange,
                ),
                label: Text(
                  label,
                  style: const TextStyle(
                    color: NearFixColors.darkNavy,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: NearFixColors.offWhite,
                side: BorderSide(
                  color: NearFixColors.mutedGrey.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                onPressed: () => _sendMessage(query, item.serviceId),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoProviderCard(
    DemoProvider provider,
    String serviceCategory,
    bool isTamil,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NearFixColors.softCream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: NearFixColors.primaryOrange.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  provider.name,
                  style: const TextStyle(
                    color: NearFixColors.darkNavy,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: NearFixColors.goldenYellow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isTamil ? 'மாதிரி வழங்குநர்' : 'Demo Provider',
                  style: const TextStyle(
                    color: NearFixColors.darkNavy,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildProviderMetaRow(
            icon: Icons.home_repair_service_outlined,
            text: serviceCategory,
          ),
          const SizedBox(height: 4),
          _buildProviderMetaRow(
            icon: Icons.location_on_outlined,
            text: provider.area,
          ),
          const SizedBox(height: 4),
          _buildProviderMetaRow(
            icon: Icons.build_outlined,
            text: provider.specialty,
          ),
        ],
      ),
    );
  }

  Widget _buildProviderMetaRow({
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 15,
          color: NearFixColors.deepOrange,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: NearFixColors.darkNavy,
              fontSize: 13.5,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(_ChatMessage message, double maxBubbleWidth) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
          decoration: BoxDecoration(
            color: NearFixColors.primaryOrange,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: NearFixColors.primaryOrange.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            message.text,
            style: const TextStyle(
              color: NearFixColors.darkNavy,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      );
    }

    final hasStructuredProviders = message.providers.isNotEmpty;
    final serviceLabel = message.serviceCategory ?? '';

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(top: 2, right: 8),
              decoration: const BoxDecoration(
                color: NearFixColors.darkNavy,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: NearFixColors.goldenYellow,
                size: 18,
              ),
            ),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                decoration: BoxDecoration(
                  color: NearFixColors.pureWhite,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                    bottomLeft: Radius.circular(4),
                  ),
                  border: Border.all(
                    color: NearFixColors.mutedGrey.withValues(alpha: 0.18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: NearFixColors.darkNavy.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: hasStructuredProviders
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.introText ?? message.text,
                            style: const TextStyle(
                              color: NearFixColors.darkNavy,
                              fontSize: 15,
                              height: 1.45,
                            ),
                          ),
                          ...message.providers.map(
                            (provider) => _buildDemoProviderCard(
                              provider,
                              serviceLabel,
                              message.isTamil,
                            ),
                          ),
                          if (message.footerText != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              message.footerText!,
                              style: const TextStyle(
                                color: NearFixColors.mutedGrey,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      )
                    : Text(
                        message.text,
                        style: const TextStyle(
                          color: NearFixColors.darkNavy,
                          fontSize: 15,
                          height: 1.45,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(bool isDesktopLayout) {
    return Container(
      decoration: BoxDecoration(
        color: NearFixColors.pureWhite,
        borderRadius: isDesktopLayout
            ? const BorderRadius.vertical(bottom: Radius.circular(24))
            : BorderRadius.zero,
        border: Border(
          top: BorderSide(
            color: NearFixColors.mutedGrey.withValues(alpha: 0.18),
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              minLines: 1,
              maxLines: 4,
              style: const TextStyle(
                color: NearFixColors.darkNavy,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: _engine.inputHint,
                hintStyle: const TextStyle(
                  color: NearFixColors.mutedGrey,
                  fontSize: 14.5,
                ),
                filled: true,
                fillColor: NearFixColors.offWhite,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide(
                    color: NearFixColors.mutedGrey.withValues(alpha: 0.25),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide(
                    color: NearFixColors.mutedGrey.withValues(alpha: 0.25),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: const BorderSide(
                    color: NearFixColors.primaryOrange,
                    width: 1.6,
                  ),
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: _engine.language == ChatLanguage.ta ? 'அனுப்பு' : 'Send',
            child: Material(
              color: _canSend
                  ? NearFixColors.primaryOrange
                  : NearFixColors.mutedGrey.withValues(alpha: 0.2),
              shape: const CircleBorder(),
              child: IconButton(
                onPressed: _canSend ? () => _sendMessage() : null,
                icon: Icon(
                  Icons.send,
                  color: _canSend
                      ? NearFixColors.darkNavy
                      : NearFixColors.mutedGrey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatPanel(double panelWidth, bool isDesktopLayout) {
    final maxBubbleWidth = (panelWidth * 0.78).clamp(220.0, 540.0);

    return Container(
      decoration: BoxDecoration(
        color: NearFixColors.offWhite,
        borderRadius:
            isDesktopLayout ? BorderRadius.circular(24) : BorderRadius.zero,
        border: isDesktopLayout
            ? Border.all(
                color: NearFixColors.primaryOrange.withValues(alpha: 0.22),
              )
            : null,
        boxShadow: isDesktopLayout
            ? [
                BoxShadow(
                  color: NearFixColors.darkNavy.withValues(alpha: 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          _buildHeader(isDesktopLayout),
          if (_engine.assetErrors.isNotEmpty)
            Container(
              width: double.infinity,
              color: NearFixColors.softCream,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: NearFixColors.deepOrange,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _engine.assetErrorBannerText,
                      style: const TextStyle(
                        color: NearFixColors.darkNavy,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildWelcomeSection(),
                  ..._messages.map(
                    (message) => _buildMessageBubble(message, maxBubbleWidth),
                  ),
                ],
              ),
            ),
          ),
          _buildInputBar(isDesktopLayout),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NearFixColors.softCream,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktopLayout = constraints.maxWidth >= 720;
            final panelWidth =
                isDesktopLayout ? 760.0 : constraints.maxWidth;

            if (!isDesktopLayout) {
              return _buildChatPanel(panelWidth, false);
            }

            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: SizedBox(
                  width: panelWidth,
                  child: _buildChatPanel(panelWidth, true),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
