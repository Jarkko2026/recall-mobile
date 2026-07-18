// lib/data/models/models.dart
// 业务模型 - items / tags / categories / attachments / user
// 详见方案 §4.3 数据模型

import 'package:uuid/uuid.dart';

const _uuid = Uuid();

String idOf(String prefix) => '${prefix}_${_uuid.v4().substring(0, 12)}';

enum ItemType { text, link, image, file, audio, scan }

extension ItemTypeX on ItemType {
  String get value => name;
  String get label {
    switch (this) {
      case ItemType.text: return '文本';
      case ItemType.link: return '链接';
      case ItemType.image: return '图片';
      case ItemType.file: return '文件';
      case ItemType.audio: return '语音';
      case ItemType.scan: return '扫描';
    }
  }
  static ItemType from(String s) =>
      ItemType.values.firstWhere((e) => e.name == s, orElse: () => ItemType.text);
}

enum ItemStatus { pending, organized, failed }
extension ItemStatusX on ItemStatus {
  String get value => name;
  String get label {
    switch (this) {
      case ItemStatus.pending: return '待整理';
      case ItemStatus.organized: return '已整理';
      case ItemStatus.failed: return '整理失败';
    }
  }
  static ItemStatus from(String? s) =>
      ItemStatus.values.firstWhere((e) => e.name == s, orElse: () => ItemStatus.organized);
}

enum ItemSource { manual, share, scan, asr }
extension ItemSourceX on ItemSource {
  String get value => name;
  String get label {
    switch (this) {
      case ItemSource.manual: return '手动';
      case ItemSource.share: return '分享';
      case ItemSource.scan: return '拍照';
      case ItemSource.asr: return '语音';
    }
  }
  static ItemSource from(String? s) =>
      ItemSource.values.firstWhere((e) => e.name == s, orElse: () => ItemSource.manual);
}

class Item {
  final String id;
  final String userId;
  final ItemType type;
  final String title;
  final String? content;
  final String? url;
  final String? summary;
  final List<String> tagIds;
  final String? domainId;
  final String? topicId;
  final List<String> attachmentIds;
  final ItemStatus status;
  final ItemSource source;
  final int createdAt; // ms
  final int updatedAt;
  final int viewCount;
  final int? lastViewedAt;
  // 仅前端缓存
  final List<String> tagNames;
  final String? domainName;
  final String? topicName;

  Item({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.content,
    this.url,
    this.summary,
    this.tagIds = const [],
    this.domainId,
    this.topicId,
    this.attachmentIds = const [],
    this.status = ItemStatus.organized,
    this.source = ItemSource.manual,
    required this.createdAt,
    required this.updatedAt,
    this.viewCount = 0,
    this.lastViewedAt,
    this.tagNames = const [],
    this.domainName,
    this.topicName,
  });

  factory Item.draft({
    required String userId,
    required ItemType type,
    required String title,
    String? content,
    String? url,
    ItemSource source = ItemSource.manual,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return Item(
      id: idOf('i'),
      userId: userId,
      type: type,
      title: title,
      content: content,
      url: url,
      source: source,
      status: ItemStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
  }

  Item copyWith({
    String? title,
    String? content,
    String? url,
    String? summary,
    List<String>? tagIds,
    String? domainId,
    String? topicId,
    ItemStatus? status,
    List<String>? tagNames,
    String? domainName,
    String? topicName,
    int? updatedAt,
    int? viewCount,
    int? lastViewedAt,
  }) =>
      Item(
        id: id,
        userId: userId,
        type: type,
        title: title ?? this.title,
        content: content ?? this.content,
        url: url ?? this.url,
        summary: summary ?? this.summary,
        tagIds: tagIds ?? this.tagIds,
        domainId: domainId ?? this.domainId,
        topicId: topicId ?? this.topicId,
        attachmentIds: attachmentIds,
        status: status ?? this.status,
        source: source,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now().millisecondsSinceEpoch,
        viewCount: viewCount ?? this.viewCount,
        lastViewedAt: lastViewedAt ?? this.lastViewedAt,
        tagNames: tagNames ?? this.tagNames,
        domainName: domainName ?? this.domainName,
        topicName: topicName ?? this.topicName,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'type': type.value,
        'title': title,
        'content': content,
        'url': url,
        'summary': summary,
        'tag_ids': tagIds,
        'domain_id': domainId,
        'topic_id': topicId,
        'attachment_ids': attachmentIds,
        'status': status.value,
        'source': source.value,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'view_count': viewCount,
        'last_viewed_at': lastViewedAt,
      };

  factory Item.fromJson(Map<String, dynamic> j) => Item(
        id: j['id'] as String,
        userId: j['user_id'] as String? ?? 'demo',
        type: ItemTypeX.from(j['type'] as String? ?? 'text'),
        title: j['title'] as String? ?? '',
        content: j['content'] as String?,
        url: j['url'] as String?,
        summary: j['summary'] as String?,
        tagIds: (j['tag_ids'] as List?)?.cast<String>() ?? const [],
        domainId: j['domain_id'] as String?,
        topicId: j['topic_id'] as String?,
        attachmentIds: (j['attachment_ids'] as List?)?.cast<String>() ?? const [],
        status: ItemStatusX.from(j['status'] as String?),
        source: ItemSourceX.from(j['source'] as String?),
        createdAt: j['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        updatedAt: j['updated_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        viewCount: j['view_count'] as int? ?? 0,
        lastViewedAt: j['last_viewed_at'] as int?,
      );
}

class Tag {
  final String id;
  final String name;
  final int useCount;
  final String? color;

  Tag({required this.id, required this.name, this.useCount = 0, this.color});

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'use_count': useCount, 'color': color};
  factory Tag.fromJson(Map<String, dynamic> j) => Tag(
        id: j['id'] as String,
        name: j['name'] as String,
        useCount: j['use_count'] as int? ?? 0,
        color: j['color'] as String?,
      );
}

class Category {
  final String id;
  final int level; // 1=领域, 2=主题
  final String name;
  final String? parentId;
  final int useCount;

  Category({
    required this.id,
    required this.level,
    required this.name,
    this.parentId,
    this.useCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'level': level,
        'name': name,
        'parent_id': parentId,
        'use_count': useCount,
      };

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as String,
        level: j['level'] as int? ?? 1,
        name: j['name'] as String? ?? '',
        parentId: j['parent_id'] as String?,
        useCount: j['use_count'] as int? ?? 0,
      );
}
