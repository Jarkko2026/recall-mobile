// lib/services/llm_service.dart
// LLM 调用封装 —— 客户端直连智谱（混合模式的客户端分支）
// 服务端代理逻辑见 cloudbase/functions/llm-proxy

import 'dart:convert';
import 'package:http/http.dart' as http;

class ClassificationResult {
  final String domain;
  final String topic;
  const ClassificationResult({required this.domain, required this.topic});
}

class LlmService {
  final String apiKey;
  final http.Client _client;
  LlmService({required this.apiKey, http.Client? client}) : _client = client ?? http.Client();

  /// 抽取标签（GLM-4.7-Flash）
  Future<List<String>> extractTags(String title, String? content) async {
    final prompt = '''
你是一名"知识整理助手"。请从以下用户收藏的内容中，提取 3-5 个高信息量标签。
要求：
- 标签以名词短语为主，2-6 字
- 避免宽泛词（"文章" "内容" "学习"）
- 优先抽取具体领域 / 技术名词 / 实体名
- 按重要性降序输出
输出严格 JSON：{ "tags": ["标签1", "标签2", "标签3"] }

---
标题：$title
内容：
${content ?? '(无)'}
''';
    final result = await _chat(prompt);
    final tags = result['tags'];
    if (tags is List) return tags.map((e) => e.toString()).toList();
    return <String>[];
  }

  /// 分类（领域 + 主题）
  Future<ClassificationResult> classify(
    String title,
    List<String> tags,
    String? excerpt,
  ) async {
    final prompt = '''
你是一名"知识整理助手"。请将以下内容归入"领域"和"主题"两个层级。
领域（level 1）候选：技术 / 产品 / 商业 / 设计 / 生活 / 健康 / 其他
主题（level 2）候选：在选定的领域下，给出 1 个最契合的具体主题
输出严格 JSON：{ "domain": "技术", "topic": "AI 编程" }

---
标题：$title
标签：${tags.join(', ')}
内容（前 500 字）：${excerpt ?? ''}
''';
    final result = await _chat(prompt);
    return ClassificationResult(
      domain: (result['domain'] as String?) ?? '其他',
      topic: (result['topic'] as String?) ?? '未分类',
    );
  }

  /// 生成摘要
  Future<String> summarize(String title, String? content) async {
    final prompt = '''
请用 80 字以内，准确概括以下内容的关键信息，便于日后快速回看。
要求：
- 第三人称
- 包含"主题 + 核心结论/方法"
- 不用"本文"开头

---
标题：$title
内容：
${content ?? ''}
''';
    final result = await _chat(prompt);
    return (result['summary'] as String?) ?? '';
  }

  Future<Map<String, dynamic>> _chat(String userPrompt) async {
    final res = await _client.post(
      Uri.parse('https://open.bigmodel.cn/api/paas/v4/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'glm-4.7-flash',
        'messages': [
          {'role': 'system', 'content': '你是一个严格的 JSON 输出助手，所有回答必须是合法 JSON，不要附加任何解释。'},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.3,
      }),
    ).timeout(const Duration(seconds: 12));

    if (res.statusCode != 200) {
      throw LlmException('GLM 调用失败: HTTP ${res.statusCode} - ${res.body}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final content = body['choices'][0]['message']['content'] as String;
    try {
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      final start = content.indexOf('{');
      final end = content.lastIndexOf('}');
      if (start >= 0 && end > start) {
        return jsonDecode(content.substring(start, end + 1)) as Map<String, dynamic>;
      }
      throw LlmException('LLM 返回非 JSON: $content');
    }
  }
}

class LlmException implements Exception {
  final String message;
  LlmException(this.message);
  @override
  String toString() => 'LlmException: $message';
}
