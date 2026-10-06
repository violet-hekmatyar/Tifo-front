import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/network/network_providers.dart';
import '../design_system/app_design_tokens.dart';
import 'app_content_image.dart';

const _entityColors = <Color>[
  Color(0xFFE9E6FF),
  Color(0xFFDDF1FF),
  Color(0xFFFFE7D6),
  Color(0xFFDDF4E8),
  Color(0xFFF3E0F6),
  Color(0xFFFFE1E8),
];

Color stableEntityColor(String identity) {
  var hash = 0x811C9DC5;
  for (final unit in identity.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x7FFFFFFF;
  }
  return _entityColors[hash % _entityColors.length];
}

class AppEntityAvatar extends ConsumerStatefulWidget {
  const AppEntityAvatar({
    required this.identity,
    required this.semanticLabel,
    required this.fallbackIcon,
    this.imageUrl,
    this.fallbackText,
    this.fallbackAsset,
    this.imageAlignment = Alignment.center,
    this.size = 48,
    this.circular = true,
    super.key,
  });

  final String identity;
  final String semanticLabel;
  final IconData fallbackIcon;
  final String? imageUrl;
  final String? fallbackText;
  final String? fallbackAsset;

  /// 图片裁剪时的对齐方式。球员照片用 [Alignment.topCenter]：
  /// 卡片常是「宽大于高」的紧约束，居中裁剪会把头顶切掉，顶部对齐才能把脸完整露出。
  final Alignment imageAlignment;
  final double size;
  final bool circular;

  @override
  ConsumerState<AppEntityAvatar> createState() => _AppEntityAvatarState();
}

class _AppEntityAvatarState extends ConsumerState<AppEntityAvatar> {
  late final Future<Map<String, String>> _headersFuture;

  @override
  void initState() {
    super.initState();
    try {
      final loadHeaders = ref.read(requestHeadersProvider);
      _headersFuture = Future.sync(loadHeaders);
    } on StateError {
      _headersFuture = Future.value(const <String, String>{});
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.imageUrl;
    final identity = widget.identity;
    final semanticLabel = widget.semanticLabel;
    final fallbackIcon = widget.fallbackIcon;
    final fallbackText = widget.fallbackText;
    final fallbackAsset = widget.fallbackAsset;
    final size = widget.size;
    final circular = widget.circular;
    final radius = circular ? size / 2 : AppRadius.sm;
    // 兜底内容（首字母 / 图标 / 占位图）不单独进语义树：外层 Semantics 已经带了实体标签，
    // 否则文本会把标签合并成 "名称 球员头像\n首字母"。
    final fallback = ExcludeSemantics(
      child: fallbackAsset == null
          ? Center(
              child: fallbackText?.isNotEmpty == true
                  ? Text(
                      fallbackText!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.brandDark,
                      ),
                    )
                  : Icon(
                      fallbackIcon,
                      color: AppColors.brandDark,
                      size: size * .48,
                    ),
            )
          : Image.asset(fallbackAsset, fit: BoxFit.cover),
    );
    // 有真实图片时用纯色底 + 图片：透明底的扣像照片会把下面的首字母和彩色底透出来，
    // 看起来像「兜底图和真图叠在一起」。兜底只在加载中/加载失败时短暂出现，有图就不再挂载。
    // 注意：国家队的队徽是 SVG（football-data 只给 .svg，没有 PNG 版本），Image.network 解不了，
    // 必须走 SvgPicture，否则 55 支国家队的队徽会一直显示兜底徽标。
    final backdrop = imageUrl == null ? stableEntityColor(identity) : AppColors.surface;
    final bool useSvg = isSvgMediaUrl(imageUrl);
    final Widget content = imageUrl == null
        ? fallback
        : FutureBuilder<Map<String, String>>(
            future: _headersFuture,
            initialData: const <String, String>{},
            builder: (context, snapshot) => useSvg
                ? SvgPicture.network(
                    imageUrl,
                    headers: snapshot.data ?? const <String, String>{},
                    fit: BoxFit.cover,
                    alignment: widget.imageAlignment,
                    placeholderBuilder: (_) => fallback,
                    errorBuilder: (_, _, _) => fallback,
                  )
                : Image.network(
                    imageUrl,
                    headers: snapshot.data ?? const <String, String>{},
                    fit: BoxFit.cover,
                    alignment: widget.imageAlignment,
                    loadingBuilder: (context, child, progress) =>
                        progress == null ? child : fallback,
                    errorBuilder: (_, _, _) => fallback,
                  ),
          );
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: ColoredBox(
          color: backdrop,
          child: SizedBox.square(dimension: size, child: content),
        ),
      ),
    );
  }
}
