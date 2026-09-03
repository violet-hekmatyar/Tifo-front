import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/backend_v1_contract.dart';
import '../../../recommendation/domain/recommendation_behavior.dart';
import '../../../recommendation/presentation/recommendation_behavior_dispatcher.dart';

class RecommendationExposure extends ConsumerStatefulWidget {
  const RecommendationExposure({
    required this.source,
    required this.child,
    super.key,
  });

  final RecommendationSourceContext? source;
  final Widget child;

  @override
  ConsumerState<RecommendationExposure> createState() =>
      _RecommendationExposureState();
}

class _RecommendationExposureState
    extends ConsumerState<RecommendationExposure> {
  ScrollableState? _scrollable;
  ScrollPosition? _position;
  bool _reported = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scrollable = Scrollable.maybeOf(context);
    final next = scrollable?.position;
    if (next != _position) {
      _position?.removeListener(_scheduleCheck);
      _scrollable = scrollable;
      _position = next?..addListener(_scheduleCheck);
    }
    _scheduleCheck();
  }

  @override
  void didUpdateWidget(covariant RecommendationExposure oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameRecommendation(oldWidget.source, widget.source)) {
      _reported = false;
    }
    _scheduleCheck();
  }

  void _scheduleCheck() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());

  void _checkVisibility() {
    if (!mounted || _reported || widget.source == null) return;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize ||
        renderObject.size.isEmpty) {
      return;
    }
    final topLeft = renderObject.localToGlobal(Offset.zero);
    final bounds = topLeft & renderObject.size;
    final screen = Offset.zero & MediaQuery.sizeOf(context);
    final scrollRenderObject = _scrollable?.context.findRenderObject();
    final viewport =
        scrollRenderObject is RenderBox &&
            scrollRenderObject.attached &&
            scrollRenderObject.hasSize
        ? scrollRenderObject.localToGlobal(Offset.zero) &
              scrollRenderObject.size
        : screen;
    final visible = bounds.intersect(screen).intersect(viewport);
    if (visible.isEmpty || visible.width <= 0 || visible.height <= 0) return;
    _reported = true;
    ref
        .read(recommendationBehaviorDispatcherProvider)
        .record(RecommendationBehaviorType.expose, widget.source);
  }

  @override
  void dispose() {
    _position?.removeListener(_scheduleCheck);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

bool _sameRecommendation(
  RecommendationSourceContext? left,
  RecommendationSourceContext? right,
) {
  if (identical(left, right)) return true;
  if (left == null || right == null) return false;
  final a = left.attribution;
  final b = right.attribution;
  return left.targetType == right.targetType &&
      left.targetId == right.targetId &&
      left.scene == right.scene &&
      a.algorithmVersion == b.algorithmVersion &&
      a.modelVersion == b.modelVersion &&
      a.experimentId == b.experimentId &&
      a.experimentBucket == b.experimentBucket &&
      a.requestId == b.requestId &&
      a.impressionId == b.impressionId &&
      a.position == b.position &&
      a.reasonCode == b.reasonCode &&
      a.reason == b.reason;
}
