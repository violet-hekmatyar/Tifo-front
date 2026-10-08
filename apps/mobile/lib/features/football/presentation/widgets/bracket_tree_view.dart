import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_entity_avatar.dart';
import '../../domain/bracket_models.dart';
import '../../domain/football_models.dart';

const _cardW = 86.0;
const _cardH = 58.0;
const _hGap = 6.0;
const _rowVGap = 7.0;
const _perRow = 4;
const _linkH = 26.0;
const _blockVGap = 6.0;

class _BlockLayout {
  _BlockLayout({
    required this.ties,
    required this.rows,
    required this.width,
    required this.centerX,
  });

  final List<BracketTie> ties;
  final int rows;
  final double width;

  /// tieKey -> 该卡在整棵树坐标系里的水平中心
  final Map<String, double> centerX;

  double get height => rows * _cardH + (rows - 1) * _rowVGap;
}

class _Half {
  _Half(this.blocks, this.width);
  final List<_BlockLayout> blocks;
  final double width;
}

class BracketTreeView extends ConsumerWidget {
  const BracketTreeView({required this.stages, super.key});

  final List<BracketStage> stages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = _layout();
    if (data == null) {
      return const Center(
        child: Text(
          '暂无淘汰赛数据',
          key: ValueKey('bracket_empty'),
          style: TextStyle(color: AppColors.inkMuted),
        ),
      );
    }
    final (top, bottom, finalTie) = data;
    final finalW = top.width.clamp(150.0, 220.0);
    final treeWidth = [top.width, bottom.width, finalW].reduce(
      (a, b) => a > b ? a : b,
    );
    final config = ref.watch(appConfigProvider);
    final children = <Widget>[
      for (var i = 0; i < top.blocks.length; i++) ...[
        _block(context, top.blocks[i], treeWidth, config),
        _link(
          childBlock: top.blocks[i],
          parentCenters: i + 1 < top.blocks.length
              ? top.blocks[i + 1].centerX
              : {finalTie.tieKey: treeWidth / 2},
          down: true,
        ),
      ],
      _card(
        context,
        finalTie,
        finalW,
        config,
        highlighted: true,
      ),
      for (var i = bottom.blocks.length - 1; i >= 0; i--) ...[
        _link(
          childBlock: bottom.blocks[i],
          parentCenters: i + 1 < bottom.blocks.length
              ? bottom.blocks[i + 1].centerX
              : {finalTie.tieKey: treeWidth / 2},
          down: false,
        ),
        _block(context, bottom.blocks[i], treeWidth, config),
      ],
    ];
    return _ZoomableTree(
      child: SizedBox(
        width: treeWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }

  Widget _block(
    BuildContext context,
    _BlockLayout block,
    double treeWidth,
    dynamic config,
  ) {
    final rows = <Widget>[];
    for (var r = 0; r < block.rows; r++) {
      final start = r * _perRow;
      final end = (start + _perRow).clamp(0, block.ties.length);
      final rowTies = block.ties.sublist(start, end);
      final rowWidth = rowTies.length * _cardW + (rowTies.length - 1) * _hGap;
      rows.add(
        SizedBox(
          height: _cardH,
          width: treeWidth,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < rowTies.length; i++) ...[
                  if (i > 0) const SizedBox(width: _hGap),
                  _card(context, rowTies[i], _cardW, config),
                ],
              ],
            ),
          ),
        ),
      );
      if (r < block.rows - 1) {
        rows.add(const SizedBox(height: _rowVGap));
      }
      assert(rowWidth >= 0);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _blockVGap),
      child: Column(children: rows),
    );
  }

  Widget _card(
    BuildContext context,
    BracketTie tie,
    double width,
    dynamic config, {
    bool highlighted = false,
  }) => SizedBox(
    width: width,
    height: highlighted ? _cardH + 18 : _cardH,
    child: Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        key: ValueKey('bracket_tie_${tie.tieKey}'),
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: tie.legs.isEmpty
            ? null
            : () => context.push('/matches/${tie.legs.last.matchId}'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: highlighted ? AppColors.brand : AppColors.border,
              width: highlighted ? 1.4 : 1,
            ),
          ),
          child: highlighted
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _teamRow(tie.homeTeam, tie.homeAggregate, config, true),
                    const SizedBox(height: 3),
                    Text(
                      _finalCaption(tie),
                      style: const TextStyle(
                        color: AppColors.brand,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    _teamRow(tie.awayTeam, tie.awayAggregate, config, true),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _teamRow(
                      tie.homeTeam,
                      tie.homeAggregate,
                      config,
                      tie.winnerTeamId == tie.homeTeam.id,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        _legText(tie),
                        style: const TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 8,
                        ),
                      ),
                    ),
                    _teamRow(
                      tie.awayTeam,
                      tie.awayAggregate,
                      config,
                      tie.winnerTeamId == tie.awayTeam.id,
                    ),
                  ],
                ),
        ),
      ),
    ),
  );

  Widget _teamRow(
    FootballTeam team,
    int? aggregate,
    dynamic config,
    bool winner,
  ) => Row(
    children: [
      AppEntityAvatar(
        identity: 'team:${team.id}',
        semanticLabel: '${team.name}队徽',
        fallbackIcon: Icons.shield_outlined,
        imageUrl: resolveMediaUrl(config, team.logoUrl),
        size: 13,
      ),
      const SizedBox(width: 3),
      Expanded(
        child: Text(
          team.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: winner ? AppColors.ink : AppColors.inkMuted,
            fontSize: 8.5,
            fontWeight: winner ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
      const SizedBox(width: 2),
      Text(
        aggregate == null ? '-' : '$aggregate',
        style: TextStyle(
          color: winner ? AppColors.brand : AppColors.ink,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );

  Widget _link({
    required _BlockLayout childBlock,
    required Map<String, double> parentCenters,
    required bool down,
  }) => SizedBox(
    height: _linkH,
    child: CustomPaint(
      size: Size.infinite,
      painter: _LinkPainter(
        edges: [
          for (final tie in childBlock.ties)
            if (parentCenters[tie.parentTieKey] case final parentX?)
              (childX: childBlock.centerX[tie.tieKey] ?? 0, parentX: parentX),
        ],
        down: down,
      ),
    ),
  );

  (_Half, _Half, BracketTie)? _layout() {
    final rounds =
        stages.where((s) => s.isKnockout && s.ties.isNotEmpty).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (rounds.length < 2) return null;
    final finalTie = rounds.last.ties.first;
    final innerIndex = rounds.length - 2;
    final roots = rounds[innerIndex].ties
        .where((tie) => tie.parentTieKey == finalTie.tieKey)
        .toList();
    if (roots.length < 2) return null;
    final top = _half(rounds, innerIndex, roots[0]);
    final bottom = _half(rounds, innerIndex, roots[1]);
    final baseWidth = [top.width, bottom.width].reduce((a, b) => a > b ? a : b);
    final clamped = baseWidth.clamp(150.0, 220.0);
    final treeWidth = baseWidth > clamped ? baseWidth : clamped;
    return (_center(top, treeWidth), _center(bottom, treeWidth), finalTie);
  }

  _Half _half(List<BracketStage> rounds, int innerIndex, BracketTie root) {
    final innerFirst = <List<BracketTie>>[
      [root],
    ];
    var parentKeys = <String>[root.tieKey];
    var depth = 0;
    while (innerIndex - depth - 1 >= 0) {
      final stage = rounds[innerIndex - depth - 1];
      final ties = stage.ties
          .where((tie) => parentKeys.contains(tie.parentTieKey))
          .toList();
      if (ties.isEmpty) break;
      ties.sort((a, b) {
        final ai = parentKeys.indexOf(a.parentTieKey ?? '');
        final bi = parentKeys.indexOf(b.parentTieKey ?? '');
        return ai == bi ? a.tieKey.compareTo(b.tieKey) : ai.compareTo(bi);
      });
      innerFirst.add(ties);
      parentKeys = ties.map((tie) => tie.tieKey).toList();
      depth++;
    }
    final outward = innerFirst.reversed.toList();
    var width = 0.0;
    final blocks = <_BlockLayout>[];
    for (final ties in outward) {
      final rowsInBlock = (ties.length / _perRow).ceil();
      var blockWidth = 0.0;
      for (var r = 0; r < rowsInBlock; r++) {
        final count = (ties.length - r * _perRow).clamp(0, _perRow);
        if (count <= 0) continue;
        final w = count * _cardW + (count - 1) * _hGap;
        if (w > blockWidth) blockWidth = w;
      }
      if (blockWidth > width) width = blockWidth;
      final centers = <String, double>{};
      for (var r = 0; r < rowsInBlock; r++) {
        final count = (ties.length - r * _perRow).clamp(0, _perRow);
        if (count <= 0) continue;
        final rowWidth = count * _cardW + (count - 1) * _hGap;
        final offset = (blockWidth - rowWidth) / 2;
        for (var i = 0; i < count; i++) {
          centers[ties[r * _perRow + i].tieKey] =
              offset + i * (_cardW + _hGap) + _cardW / 2;
        }
      }
      blocks.add(
        _BlockLayout(
          ties: ties,
          rows: rowsInBlock,
          width: blockWidth,
          centerX: centers,
        ),
      );
    }
    return _Half(blocks, width);
  }

  // 渲染时每行 Row 是在 treeWidth 里居中的，所以卡片中心必须用同一个基准算，
  // 否则窄块（2 联/1 联排）的连线会横向错位。
  _Half _center(_Half half, double treeWidth) {
    final blocks = <_BlockLayout>[];
    for (final block in half.blocks) {
      final centers = <String, double>{};
      for (var r = 0; r < block.rows; r++) {
        final count = (block.ties.length - r * _perRow).clamp(0, _perRow);
        if (count <= 0) continue;
        final rowWidth = count * _cardW + (count - 1) * _hGap;
        final offset = (treeWidth - rowWidth) / 2;
        for (var i = 0; i < count; i++) {
          centers[block.ties[r * _perRow + i].tieKey] =
              offset + i * (_cardW + _hGap) + _cardW / 2;
        }
      }
      blocks.add(
        _BlockLayout(
          ties: block.ties,
          rows: block.rows,
          width: block.width,
          centerX: centers,
        ),
      );
    }
    return _Half(blocks, half.width);
  }
}

class _ZoomableTree extends StatefulWidget {
  const _ZoomableTree({required this.child});
  final Widget child;

  @override
  State<_ZoomableTree> createState() => _ZoomableTreeState();
}

class _ZoomableTreeState extends State<_ZoomableTree> {
  final _controller = TransformationController();
  bool _transformed = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _controller.dispose();
    super.dispose();
  }

  void _onChange() {
    final matrix = _controller.value;
    final transformed =
        matrix.getMaxScaleOnAxis() != 1.0 ||
        matrix.getTranslation().x != 0 ||
        matrix.getTranslation().y != 0;
    if (transformed != _transformed) {
      setState(() => _transformed = transformed);
    }
  }

  void _reset() => _controller.value = Matrix4.identity();

  @override
  Widget build(BuildContext context) => Stack(
    key: const ValueKey('bracket_tree_scroll'),
    children: [
      Positioned.fill(
        child: InteractiveViewer(
          transformationController: _controller,
          constrained: false,
          alignment: Alignment.topCenter,
          minScale: 0.4,
          maxScale: 2.5,
          boundaryMargin: const EdgeInsets.all(80),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: widget.child,
          ),
        ),
      ),
      Positioned(
        top: 6,
        right: 10,
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          elevation: 2,
          child: InkWell(
            key: const ValueKey('bracket_reset_zoom'),
            borderRadius: BorderRadius.circular(18),
            onTap: _reset,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.center_focus_strong_rounded,
                    size: 15,
                    color: _transformed ? AppColors.brand : AppColors.inkMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '复位',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _transformed
                          ? AppColors.brand
                          : AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _LinkPainter extends CustomPainter {
  const _LinkPainter({required this.edges, required this.down});
  final List<({double childX, double parentX})> edges;
  final bool down;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.inkMuted.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final busY = size.height / 2;
    for (final edge in edges) {
      final startY = down ? 0.0 : size.height;
      final endY = down ? size.height : 0.0;
      canvas.drawLine(Offset(edge.childX, startY), Offset(edge.childX, busY), paint);
      canvas.drawLine(Offset(edge.childX, busY), Offset(edge.parentX, busY), paint);
      canvas.drawLine(Offset(edge.parentX, busY), Offset(edge.parentX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinkPainter oldDelegate) => false;
}

class BracketTieList extends ConsumerWidget {
  const BracketTieList({required this.ties, super.key});

  final List<BracketTie> ties;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ties.isEmpty) {
      return const Center(
        child: Text(
          '暂无数据',
          key: ValueKey('bracket_empty'),
          style: TextStyle(color: AppColors.inkMuted),
        ),
      );
    }
    final config = ref.watch(appConfigProvider);
    return ListView.separated(
      key: const PageStorageKey('bracket_round_list'),
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: ties.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) => _TieRowCard(
        tie: ties[index],
        config: config,
      ),
    );
  }
}

class _TieRowCard extends StatelessWidget {
  const _TieRowCard({required this.tie, required this.config});
  final BracketTie tie;
  final dynamic config;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadius.md),
    child: InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: tie.legs.isEmpty
          ? null
          : () => context.push('/matches/${tie.legs.last.matchId}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            _teamRow(tie.homeTeam, tie.homeAggregate, tie.winnerTeamId == tie.homeTeam.id),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                _legText(tie),
                style: const TextStyle(color: AppColors.inkMuted, fontSize: 11),
              ),
            ),
            _teamRow(tie.awayTeam, tie.awayAggregate, tie.winnerTeamId == tie.awayTeam.id),
          ],
        ),
      ),
    ),
  );

  Widget _teamRow(FootballTeam team, int? aggregate, bool winner) => Row(
    children: [
      AppEntityAvatar(
        identity: 'team:${team.id}',
        semanticLabel: '${team.name}队徽',
        fallbackIcon: Icons.shield_outlined,
        imageUrl: resolveMediaUrl(config, team.logoUrl),
        size: 22,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          team.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: winner ? AppColors.ink : AppColors.inkMuted,
            fontSize: 13,
            fontWeight: winner ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
      Text(
        aggregate == null ? '-' : '$aggregate',
        style: TextStyle(
          color: winner ? AppColors.brand : AppColors.ink,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

String _legText(BracketTie tie) => tie.legs.isEmpty
    ? ''
    : tie.legs
          .map((leg) => '${leg.homeScore ?? '-'} - ${leg.awayScore ?? '-'}')
          .join('   ');

String _finalCaption(BracketTie tie) {
  final legs = tie.legs;
  final time = legs.isEmpty ? null : legs.first.matchTime;
  if (legs.length <= 1 && time != null) {
    return 'VS   ${time.month}/${time.day}';
  }
  return '${tie.homeAggregate ?? 0} : ${tie.awayAggregate ?? 0}';
}
