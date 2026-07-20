// lib/presentation/pages/copilot_page.dart
// AI 助手 Copilot 聊天页（RAG 问答 + 推荐问题，对齐 web 端 recall-copilot）
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/design_tokens.dart';
import '../../services/api_client.dart';

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
  List<String> _suggestions = [];
  bool _suggestionLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // 拉取推荐问题（recall-copilot /suggest），对齐 web 端
  Future<void> _loadSuggestions() async {
    try {
      final res = await ref.read(apiClientProvider).call('recall-copilot',
          method: 'POST', path: '/suggest', body: {});
      final list = (res['suggestions'] as List?) ?? (res['items'] as List?) ?? [];
      if (mounted) {
        setState(() {
          _suggestions = list.map((e) => e.toString()).where((s) => s.isNotEmpty).take(6).toList();
          _suggestionLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _suggestionLoading = false);
    }
  }

  Future<void> _send({String? preset}) async {
    final text = (preset ?? _ctrl.text).trim();
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
      final reply = (res['reply'] as String?) ?? (res['answer'] as String?) ?? '无回复';
      setState(() {
        _messages.add(_ChatMessage(role: 'assistant', content: reply));
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(role: 'assistant',
            content: '出错：${e.toString().replaceFirst("ApiException", "").substring(0, 200)}'));
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
            child: _messages.isEmpty
                ? _buildEmpty(theme)
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(AppSpacing.s3),
                    itemCount: _messages.length + (_loading ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == _messages.length) {
                        return const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator()));
                      }
                      final m = _messages[i];
                      final isUser = m.role == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.s2),
                          padding: const EdgeInsets.all(AppSpacing.s3),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                          decoration: BoxDecoration(
                            color: isUser ? AppColors.primary500 : theme.cardColor,
                            border: isUser ? null : Border.all(color: theme.dividerColor, width: 0.5),
                            borderRadius: BorderRadius.circular(AppRadius.lg).copyWith(
                              topRight: isUser ? Radius.zero : null,
                              topLeft: isUser ? null : Radius.zero,
                            ),
                          ),
                          child: isUser
                              ? Text(m.content, style: const TextStyle(color: Colors.white, fontSize: AppFonts.sm, height: 1.5))
                              : MarkdownBody(
                                  data: m.content,
                                  styleSheet: MarkdownStyleSheet(
                                    p: TextStyle(color: theme.colorScheme.onSurface, fontSize: AppFonts.sm, height: 1.5),
                                    code: TextStyle(backgroundColor: theme.colorScheme.surface, fontSize: AppFonts.sm),
                                  ),
                                ),
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

  // 空状态：hero + 推荐问题（点即问）
  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary500, AppColors.primary700], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppShadows.md,
              ),
              child: const Icon(Icons.auto_awesome, size: 36, color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text('基于你的知识库回答', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.s1),
            Text('问问 Recall，它会翻你的收藏作答', style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
            const SizedBox(height: AppSpacing.s5),
            if (_suggestionLoading)
              const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator())
            else if (_suggestions.isNotEmpty) ...[
              Text('试试这些问题', style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
              const SizedBox(height: AppSpacing.s2),
              Wrap(
                spacing: AppSpacing.s2, runSpacing: AppSpacing.s2,
                children: _suggestions.map((s) => ActionChip(
                  label: Text(s),
                  onPressed: () => _send(preset: s),
                )).toList(),
              ),
            ] else
              Text('试试问："总结我收藏的 AI 相关内容"', style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String role;
  final String content;
  _ChatMessage({required this.role, required this.content});
}
