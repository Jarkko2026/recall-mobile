// lib/presentation/pages/copilot_page.dart
// AI 助手 Copilot 聊天页（RAG 问答 + Agent）
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/design_tokens.dart';
import '../../services/api_client.dart';
import '../widgets/common.dart';

class CopilotPage extends ConsumerStatefulWidget {
  const CopilotPage({Key? key}) : super(key: key);
  @override
  ConsumerState<CopilotPage> createState() => _CopilotPageState();
}

class _CopilotPageState extends ConsumerState<CopilotPage> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _messages = <_ChatMessage>[];
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;
    setState(() {
      _messages.add(_ChatMessage(role: 'user', content: text));
      _loading = true;
    });
    _ctrl.clear();
    _scrollToBottom();

    try {
      final res = await ref.read(apiClientProvider).call('recall-copilot',
        method: 'POST',
        path: '/chat',
        body: {
          'messages': _messages.map((m) => {'role': m.role, 'content': m.content}).toList(),
          'maxItems': 5,
        },
      );
      if (!mounted) return;
      final reply = res is Map ? (res['reply'] as String? ?? res['answer'] as String? ?? '无回复') : '无回复';
      setState(() {
        _messages.add(_ChatMessage(role: 'assistant', content: reply));
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(role: 'assistant', content: '出错：${e.toString().replaceFirst("ApiException", "").substring(0, 200)}'));
        _loading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recall 助手'),
        actions: [
          IconButton(icon: const Icon(Icons.delete_sweep), onPressed: () => setState(() => _messages.clear())),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.psychology, size: 64, color: theme.hintColor.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text('基于你的知识库回答', style: theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor)),
              const SizedBox(height: 8),
              Text('试试问："总结我收藏的 AI 相关内容"', style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
            ])) : ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(AppSpacing.s3),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == _messages.length) return const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator()));
                final m = _messages[i];
                final isUser = m.role == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.s2),
                    padding: const EdgeInsets.all(AppSpacing.s3),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.primary500 : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.lg).copyWith(
                        topRight: isUser ? Radius.zero : null,
                        topLeft: isUser ? null : Radius.zero,
                      ),
                    ),
                    child: Text(m.content, style: TextStyle(color: isUser ? Colors.white : theme.colorScheme.onSurface, fontSize: AppFonts.sm)),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.s3, AppSpacing.s2, AppSpacing.s3, MediaQuery.of(context).padding.bottom + AppSpacing.s2),
            child: Row(children: [
              Expanded(child: TextField(controller: _ctrl, decoration: const InputDecoration(hintText: '向 Recall 提问...', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)), textInputAction: TextInputAction.send, onSubmitted: (_) => _send())),
              IconButton(icon: const Icon(Icons.send_rounded, color: AppColors.primary500), onPressed: _loading ? null : _send),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String role;
  final String content;
  _ChatMessage({required this.role, required this.content});
}
