// lib/presentation/widgets/common.dart
// 通用组件库 - Recall 16 个核心组件
// 详见方案 §3.4

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/theme/design_tokens.dart';

// ============== 1. AppButton ==============
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final IconData? icon;
  final bool fullWidth;

  const AppButton({
    Key? key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.icon,
    this.fullWidth = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color bg;
    Color fg;
    if (variant == AppButtonVariant.primary) {
      bg = AppColors.primary500;
      fg = Colors.white;
    } else if (variant == AppButtonVariant.danger) {
      bg = AppColors.danger;
      fg = Colors.white;
    } else {
      bg = theme.colorScheme.surface;
      fg = theme.colorScheme.onSurface;
    }
    final btn = loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, valueColor: AlwaysStoppedAnimation(fg)),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: AppSpacing.s2),
              ],
              Text(label,
                  style: TextStyle(
                      color: fg,
                      fontSize: AppFonts.base,
                      fontWeight: FontWeight.w600)),
            ],
          );
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 48,
      child: variant == AppButtonVariant.text
          ? TextButton(onPressed: loading ? null : onPressed, child: btn)
          : ElevatedButton(
              onPressed: loading ? null : onPressed,
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.disabled)) {
                    return bg.withOpacity(0.5);
                  }
                  return bg;
                }),
                foregroundColor: MaterialStateProperty.all(fg),
                elevation: MaterialStateProperty.all(0),
                shape: MaterialStateProperty.all(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  side: variant == AppButtonVariant.secondary
                      ? BorderSide(color: theme.dividerColor)
                      : BorderSide.none,
                )),
              ),
              child: btn,
            ),
    );
  }
}

enum AppButtonVariant { primary, secondary, text, danger }

// ============== 2. AppInput ==============
class AppInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final String? label;
  final bool multiline;
  final int? maxLines;
  final bool obscure;
  final Widget? prefix;
  final Widget? suffix;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const AppInput({
    Key? key,
    this.controller,
    this.hint,
    this.label,
    this.multiline = false,
    this.maxLines,
    this.obscure = false,
    this.prefix,
    this.suffix,
    this.errorText,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurface)),
          const SizedBox(height: AppSpacing.s2),
        ],
        TextField(
          controller: controller,
          obscureText: obscure,
          maxLines: obscure ? 1 : (multiline ? (maxLines ?? 5) : 1),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefix != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: prefix,
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: suffix,
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}

// ============== 3. AppCard ==============
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  const AppCard({
    Key? key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.s4),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.md,
          ),
          child: child,
        ),
      ),
    );
  }
}

// ============== 4. TagChip ==============
class TagChip extends StatelessWidget {
  final String label;
  final bool closable;
  final VoidCallback? onClose;
  final bool selected;
  final VoidCallback? onTap;
  const TagChip({
    Key? key,
    required this.label,
    this.closable = false,
    this.onClose,
    this.selected = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = selected ? AppColors.primary50 : theme.colorScheme.surface;
    final border = selected ? AppColors.primary500 : theme.dividerColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: border, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('#$label',
                style: TextStyle(
                    fontSize: AppFonts.sm,
                    color: selected
                        ? AppColors.primary700
                        : theme.colorScheme.onSurface,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
            if (closable) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: onClose,
                child: Icon(Icons.close, size: 14, color: theme.colorScheme.onSurface),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============== 5. CategoryPicker (简化：chip 群) ==============
class CategoryChipsRow extends StatelessWidget {
  final List<String> names;
  final String? selected;
  final ValueChanged<String?>? onTap;
  const CategoryChipsRow({Key? key, required this.names, this.selected, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s2,
      runSpacing: AppSpacing.s2,
      children: names.map((n) => TagChip(
        label: n,
        selected: n == selected,
        onTap: () => onTap?.call(n == selected ? null : n),
      )).toList(),
    );
  }
}

// ============== 6. EmptyState ==============
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyState({
    Key? key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary50,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Icon(icon, size: 40, color: AppColors.primary500),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.s2),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpacing.s5),
              AppButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

// ============== 7. LoadingSkeleton ==============
class LoadingSkeleton extends StatelessWidget {
  final int count;
  const LoadingSkeleton({Key? key, this.count = 3}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.s4),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s3),
      itemBuilder: (_, __) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _bar(width: 200),
            const SizedBox(height: AppSpacing.s2),
            _bar(width: double.infinity),
            const SizedBox(height: AppSpacing.s2),
            _bar(width: 180),
          ],
        ),
      ),
    );
  }

  Widget _bar({required double width}) {
    return Container(
      width: width,
      height: 14,
      decoration: BoxDecoration(
        color: AppColors.lightBgTertiary,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );
  }
}

// ============== 8. ErrorState ==============
class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorStateView({Key? key, required this.message, this.onRetry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
          const SizedBox(height: AppSpacing.s3),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.s4),
            AppButton(label: '重试', onPressed: onRetry, variant: AppButtonVariant.secondary),
          ],
        ],
      ),
    );
  }
}

// ============== 9. OfflineBanner ==============
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2, horizontal: AppSpacing.s4),
      color: AppColors.warning.withOpacity(0.15),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, size: 16, color: AppColors.warning),
          const SizedBox(width: AppSpacing.s2),
          Text('离线模式，仅显示缓存内容',
              style: TextStyle(
                  fontSize: AppFonts.sm,
                  color: AppColors.warning,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ============== 10. BottomTabBar (自定义 5 Tab，中间凸起) ==============
class RecallBottomTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const RecallBottomTabBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: AppShadows.md,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Stack(
            children: [
              Row(
                children: [
                  _tab(0, Icons.timeline, '时间线', context),
                  _tab(1, Icons.grid_view, '主题', context),
                  const SizedBox(width: 64), // 给中间加号留位
                  _tab(2, Icons.search, '搜索', context),
                  _tab(3, Icons.person, '我的', context),
                ],
              ),
              Positioned(
                top: -8,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () => onTap(4),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppColors.primary500, AppColors.primary700],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.lg,
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(int idx, IconData icon, String label, BuildContext context) {
    final theme = Theme.of(context);
    final active = currentIndex == idx;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(idx),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: active ? AppColors.primary500 : theme.colorScheme.onSurface.withOpacity(0.5)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: AppFonts.xs,
                    color: active ? AppColors.primary500 : theme.colorScheme.onSurface.withOpacity(0.5),
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}

// ============== 11. ConfirmSheet ==============
class ConfirmSheet extends StatelessWidget {
  final String title;
  final String? message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;
  const ConfirmSheet({
    Key? key,
    required this.title,
    this.message,
    this.confirmLabel = '确定',
    this.cancelLabel = '取消',
    this.destructive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.s4),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.s2),
              Text(message!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: AppSpacing.s5),
            AppButton(
              label: confirmLabel,
              variant: destructive ? AppButtonVariant.danger : AppButtonVariant.primary,
              onPressed: () => Navigator.of(context).pop(true),
              fullWidth: true,
            ),
            const SizedBox(height: AppSpacing.s2),
            AppButton(
              label: cancelLabel,
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.of(context).pop(false),
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}

// ============== 12. Toast (轻量版) ==============
void showRecallToast(BuildContext context, String message, {bool isError = false}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white, size: 18),
          const SizedBox(width: AppSpacing.s2),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: isError ? AppColors.danger : null,
      duration: const Duration(seconds: 2),
    ),
  );
}

// ============== 13. MarkdownView ==============
// Phase 2.5 — 真用 flutter_markdown 渲染，原 SelectableText 丢失格式
class MarkdownView extends StatelessWidget {
  final String data;
  const MarkdownView({Key? key, required this.data}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: MarkdownBody(
        data: data,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(
            fontSize: AppFonts.base,
            height: AppFonts.loose,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

// ============== 14. PdfPreview (占位) ==============
class PdfPreview extends StatelessWidget {
  final String url;
  const PdfPreview({Key? key, required this.url}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.picture_as_pdf, size: 48, color: AppColors.primary500),
          const SizedBox(height: AppSpacing.s2),
          Text('PDF 文档', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(url.split('/').last,
              style: TextStyle(
                  fontSize: AppFonts.xs, color: Theme.of(context).hintColor),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ============== 15. AudioPlayer (占位) ==============
class AudioPlayerWidget extends StatelessWidget {
  final int durationSec;
  const AudioPlayerWidget({Key? key, required this.durationSec}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary500,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: 0.35,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary500,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s1),
                Text('00:${durationSec.toString().padLeft(2, '0')} / 03:24',
                    style: TextStyle(fontSize: AppFonts.xs, color: theme.hintColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============== 16. SearchBar ==============
class RecallSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final String? hint;
  final TextEditingController? controller;
  const RecallSearchBar({Key? key, required this.onChanged, this.hint, this.controller}) : super(key: key);

  @override
  State<RecallSearchBar> createState() => _RecallSearchBarState();
}

class _RecallSearchBarState extends State<RecallSearchBar> {
  late final TextEditingController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = widget.controller ?? TextEditingController();
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.dividerColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
      child: Row(
        children: [
          Icon(Icons.search, size: 18, color: theme.hintColor),
          const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: TextField(
              controller: _ctrl,
              onChanged: widget.onChanged,
              decoration: InputDecoration(
                hintText: widget.hint ?? '搜索收藏',
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                filled: false,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          if (_ctrl.text.isNotEmpty)
            InkWell(
              onTap: () {
                _ctrl.clear();
                widget.onChanged('');
              },
              child: Icon(Icons.close, size: 16, color: theme.hintColor),
            ),
        ],
      ),
    );
  }
}
