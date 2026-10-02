import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/network_providers.dart';
import '../design_system/app_design_tokens.dart';

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
    final fallback = fallbackAsset == null
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
        : Image.asset(fallbackAsset, fit: BoxFit.cover);
    Widget content = imageUrl == null
        ? fallback
        : FutureBuilder<Map<String, String>>(
            future: _headersFuture,
            initialData: const <String, String>{},
            builder: (context, snapshot) => Stack(
              fit: StackFit.expand,
              children: [
                fallback,
                Image.network(
                  imageUrl,
                  headers: snapshot.data ?? const <String, String>{},
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) =>
                      progress == null ? child : const SizedBox.shrink(),
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          );
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: ColoredBox(
          color: stableEntityColor(identity),
          child: SizedBox.square(dimension: size, child: content),
        ),
      ),
    );
  }
}
