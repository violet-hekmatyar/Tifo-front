import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/network_providers.dart';
import '../design_system/app_design_tokens.dart';

class AppContentImage extends ConsumerStatefulWidget {
  const AppContentImage({this.imageUrl, this.aspectRatio = 4 / 3, super.key});

  final String? imageUrl;
  final double aspectRatio;

  @override
  ConsumerState<AppContentImage> createState() => _AppContentImageState();
}

class _AppContentImageState extends ConsumerState<AppContentImage> {
  static const _fallbackAsset = 'assets/ui/home/neutral-football-cover.png';
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
    const fallback = ColoredBox(
      color: AppColors.surfaceMuted,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image(image: AssetImage(_fallbackAsset), fit: BoxFit.cover),
          ColoredBox(color: Color(0x660F2118)),
          Center(
            child: Icon(
              Icons.sports_soccer_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
        ],
      ),
    );
    return Semantics(
      image: true,
      label: '内容封面',
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: widget.imageUrl == null
            ? fallback
            : FutureBuilder<Map<String, String>>(
                future: _headersFuture,
                initialData: const <String, String>{},
                builder: (context, snapshot) => Stack(
                  fit: StackFit.expand,
                  children: [
                    fallback,
                    Image.network(
                      widget.imageUrl!,
                      headers: snapshot.data ?? const <String, String>{},
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) =>
                          progress == null ? child : const SizedBox.shrink(),
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
