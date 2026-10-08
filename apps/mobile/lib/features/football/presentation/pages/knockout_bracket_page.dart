import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design_system/app_design_tokens.dart';
import '../../data/football_rankings_repository.dart';
import '../../data/knockout_bracket_repository.dart';
import '../../domain/bracket_models.dart';
import '../../domain/football_models.dart';
import '../../domain/football_ranking_models.dart';
import '../widgets/bracket_tree_view.dart';

class KnockoutBracketPage extends ConsumerStatefulWidget {
  const KnockoutBracketPage({
    this.initialLeagueId,
    this.initialSeasonId,
    this.initialStageId,
    super.key,
  });

  final int? initialLeagueId;
  final int? initialSeasonId;
  final int? initialStageId;

  @override
  ConsumerState<KnockoutBracketPage> createState() =>
      _KnockoutBracketPageState();
}

class _KnockoutBracketPageState extends ConsumerState<KnockoutBracketPage> {
  static const _cupKeyword = '欧冠';

  bool _loading = true;
  String? _message;
  List<League> _leagues = const [];
  List<FootballSeason> _seasons = const [];
  int? _leagueId;
  int? _seasonId;
  int? _stageId;

  @override
  void initState() {
    super.initState();
    _leagueId = widget.initialLeagueId;
    _seasonId = widget.initialSeasonId;
    _stageId = widget.initialStageId;
    unawaited(_load());
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _message = null;
      });
    }
    try {
      final repository = ref.read(footballRankingsRepositoryProvider);
      final leagues = await repository.leagues();
      _leagueId ??= leagues.isEmpty
          ? null
          : leagues
                .firstWhere(
                  (league) => league.name.contains(_cupKeyword),
                  orElse: () => leagues.first,
                )
                .id;
      var seasons = const <FootballSeason>[];
      if (_leagueId != null) {
        seasons = await repository.seasons(_leagueId!);
        _seasonId ??= seasons.isEmpty
            ? null
            : seasons
                  .firstWhere(
                    (season) => season.current,
                    orElse: () => seasons.first,
                  )
                  .id;
      }
      if (!mounted) return;
      setState(() {
        _leagues = leagues;
        _seasons = seasons;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _message = '淘汰赛数据加载失败，请稍后重试。';
      });
    }
  }

  Future<void> _selectLeague(int leagueId) async {
    setState(() {
      _leagueId = leagueId;
      _seasonId = null;
      _seasons = const [];
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final leagueId = _leagueId;
    final seasonId = _seasonId;
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(title: const Text('淘汰赛')),
      body: Column(
        children: [
          if (_leagues.isNotEmpty)
            _ChipRow(
              key: const ValueKey('bracket_league_row'),
              labels: [
                for (final league in _leagues) (league.id, league.name),
              ],
              selected: leagueId,
              onSelected: _selectLeague,
            ),
          if (_seasons.length > 1)
            _ChipRow(
              key: const ValueKey('bracket_season_row'),
              labels: [
                for (final season in _seasons) (season.id, season.name),
              ],
              selected: seasonId,
              onSelected: (value) => setState(() => _seasonId = value),
            ),
          Expanded(child: _body(leagueId, seasonId)),
        ],
      ),
    );
  }

  Widget _body(int? leagueId, int? seasonId) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_message case final message?) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            message,
            key: const ValueKey('bracket_message'),
            style: const TextStyle(color: AppColors.inkMuted),
          ),
        ),
      );
    }
    if (leagueId == null || seasonId == null) {
      return const Center(
        child: Text('暂无可展示的淘汰赛', style: TextStyle(color: AppColors.inkMuted)),
      );
    }
    return ref
        .watch(knockoutBracketFutureProvider((leagueId, seasonId)))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(
            child: Text(
              '淘汰赛数据加载失败，请稍后重试。',
              key: ValueKey('bracket_message'),
              style: TextStyle(color: AppColors.inkMuted),
            ),
          ),
          data: (stages) => _stages(stages),
        );
  }

  Widget _stages(List<BracketStage> stages) {
    if (stages.isEmpty) {
      return const Center(
        child: Text(
          '暂无数据',
          key: ValueKey('bracket_empty'),
          style: TextStyle(color: AppColors.inkMuted),
        ),
      );
    }
    final rounds = stages.where((s) => s.isKnockout && s.ties.isNotEmpty).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final selected = _stageId;
    final current = rounds.where((r) => r.stageId == selected).firstOrNull;
    return Column(
      children: [
        SizedBox(
          height: 46,
          child: ListView(
            key: const ValueKey('bracket_stage_bar'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            children: [
              _stageChip('总览', null),
              for (final round in rounds) ...[
                const SizedBox(width: AppSpacing.xs),
                _stageChip(round.stageName, round.stageId),
              ],
            ],
          ),
        ),
        Expanded(
          child: current == null
              ? BracketTreeView(stages: stages)
              : BracketTieList(ties: current.ties),
        ),
      ],
    );
  }

  Widget _stageChip(String label, int? stageId) => ChoiceChip(
    key: ValueKey('bracket_stage_chip_${stageId ?? 'overview'}'),
    label: Text(label),
    selected: _stageId == stageId,
    onSelected: (_) => setState(() => _stageId = stageId),
  );
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.labels,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<(int, String)> labels;
  final int? selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      itemCount: labels.length,
      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
      itemBuilder: (context, index) {
        final (id, label) = labels[index];
        return ChoiceChip(
          key: ValueKey('bracket_chip_$id'),
          label: Text(label),
          selected: id == selected,
          onSelected: (_) => onSelected(id),
        );
      },
    ),
  );
}
