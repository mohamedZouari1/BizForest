import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';
import '../services/agent_service.dart';
import '../theme.dart';

const _openRouterKey = 'openrouter_api_key';
const _openRouterModelKey = 'openrouter_model';

class AgentScreen extends StatefulWidget {
  const AgentScreen({super.key});

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  final _questionController = TextEditingController();
  final _keyController = TextEditingController();
  final _modelController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <ChatMessage>[
    ChatMessage(
      role: 'assistant',
      text:
          'Hello! I can help you with field validation for the Bizerte Reforestation project.\n\n'
          'You can ask me about:\n'
          '• Priority zone interpretation\n'
          '• Field validation steps\n'
          '• Candidate land assessment\n'
          '• Report writing\n\n'
          'Set an OpenRouter API key in settings for live answers.',
      timestamp: DateTime.now(),
    ),
  ];
  bool _loading = false;
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _keyController.dispose();
    _modelController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _keyController.text = prefs.getString(_openRouterKey) ?? '';
    _modelController.text = prefs.getString(_openRouterModelKey) ??
        'deepseek/deepseek-chat-v3-0324:free';
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_openRouterKey, _keyController.text.trim());
    await prefs.setString(_openRouterModelKey, _modelController.text.trim());
    if (!mounted) return;
    setState(() => _showSettings = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _ask() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;
    _questionController.clear();
    setState(() {
      _messages.add(ChatMessage(
        role: 'user',
        text: question,
        timestamp: DateTime.now(),
      ));
      _loading = true;
    });
    _scrollToBottom();

    final offline = OfflineGuide.answer(question);
    final key = _keyController.text.trim();

    if (key.isEmpty) {
      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant',
          text: offline,
          timestamp: DateTime.now(),
        ));
        _loading = false;
      });
      _scrollToBottom();
      return;
    }

    try {
      final response = await OpenRouterClient(
        apiKey: key,
        model: _modelController.text.trim(),
      ).ask(question);
      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant',
          text: response,
          timestamp: DateTime.now(),
        ));
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant',
          text: '$offline\n\n⚠ Online unavailable — showing offline guide.',
          timestamp: DateTime.now(),
        ));
        _loading = false;
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.chat, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Field Assistant',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    Text(
                      'Ask questions about sites and workflow',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _showSettings ? Icons.close : Icons.settings,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _showSettings = !_showSettings),
              ),
            ],
          ),
        ),

        // ── Settings ──
        if (_showSettings)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _keyController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'OpenRouter API Key',
                    prefixIcon: Icon(Icons.key, size: 18),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _modelController,
                  decoration: const InputDecoration(
                    labelText: 'Model',
                    prefixIcon: Icon(Icons.psychology, size: 18),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saveSettings,
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('Save Settings'),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 4),
        const Divider(height: 1),

        // ── Messages ──
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return _ChatBubble(message: msg);
            },
          ),
        ),

        // ── Loading ──
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(left: 20, bottom: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text(
                  'Thinking…',
                  style: TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
              ],
            ),
          ),

        // ── Input ──
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Ask about this site…',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    onSubmitted: (_) => _ask(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _loading ? null : _ask,
                  icon: const Icon(Icons.send, size: 20),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary.withAlpha(15)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: isUser
                ? const Radius.circular(14)
                : const Radius.circular(4),
            bottomRight: isUser
                ? const Radius.circular(4)
                : const Radius.circular(14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUser ? Icons.person : Icons.chat,
                  color: isUser ? AppColors.primary : AppColors.textSecondary,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  isUser ? 'You' : 'Assistant',
                  style: TextStyle(
                    color: isUser ? AppColors.primary : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message.text,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
