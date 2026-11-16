import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../data/prediction_repository.dart';
import '../../domain/prediction_models.dart';
import 'prediction_sheet.dart';

class PredictionTab extends ConsumerWidget {
  const PredictionTab({required this.matchId, super.key});
  final int matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(predictionDetailProvider(matchId));
    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (error, _) => _PredictionError(
        message: error is AppNetworkException
            ? error.message
            : '预测数据加载失败，请稍后重试。',
        onRetry: () => ref.invalidate(predictionDetailProvider(matchId)),
      ),
      data: (data) => _PredictionBody(data: data),
    );
  }
}

class _PredictionError extends StatelessWidget {
  const _PredictionError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.insights_outlined,
            size: 40,
            color: AppColors.inkDisabled,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(onPressed: onRetry, child: const Text('重新加载')),
        ],
      ),
    ),
  );
}

class _PredictionBody extends ConsumerStatefulWidget {
  const _PredictionBody({required this.data});
  final MatchPrediction data;

  @override
  ConsumerState<_PredictionBody> createState() => _PredictionBodyState();
}

class _PredictionBodyState extends ConsumerState<_PredictionBody> {
  Future<void> _openSheet({int? initialStake}) async {
    final data = widget.data;
    final result = await showPredictionSheet(
      context,
      data: data,
      initialStake: initialStake,
      onSubmit: (home, draw, away, stake) async {
        await ref
            .read(predictionRepositoryProvider)
            .submit(
              data.matchId,
              homeProbability: home,
              drawProbability: draw,
              awayProbability: away,
              stake: stake,
            );
      },
    );
    if (!mounted || result != true) return;
    ref.invalidate(predictionDetailProvider(data.matchId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('判断已提交，感谢参与。')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    if (data.isPostMatch) {
      return _PostMatchView(data: data);
    }
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            key: const ValueKey('prediction_pre_match'),
            padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ConsensusCard(data: data),
                const SizedBox(height: 10),
                _MyPredictionCard(
                  data: data,
                  onTap: data.canSubmit ? () => _openSheet() : null,
                ),
                const SizedBox(height: 10),
                _ChallengeCard(
                  data: data,
                  onTap: data.canSubmit ? _openSheet : null,
                ),
                const SizedBox(height: 18),
                _MorePredictions(data: data),
              ],
            ),
          ),
        ),
        _PreMatchBottomBar(data: data, onTap: () => _openSheet()),
      ],
    );
  }
}

class _PreMatchBottomBar extends StatelessWidget {
  const _PreMatchBottomBar({required this.data, required this.onTap});
  final MatchPrediction data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final canTap = data.canSubmit && data.myPrediction == null;
    final label = data.myPrediction != null
        ? '已提交判断'
        : data.canSubmit
        ? '写下我的判断'
        : (data.lockReason ?? '预测已锁定');
    return Container(
      color: AppColors.page,
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              data.disclaimer,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: AppColors.inkMuted),
            ),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                key: const ValueKey('prediction_cta'),
                onPressed: canTap ? onTap : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  disabledBackgroundColor: AppColors.inkDisabled,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsensusCard extends StatelessWidget {
  const _ConsensusCard({required this.data});
  final MatchPrediction data;

  @override
  Widget build(BuildContext context) {
    final c = data.consensus;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '球迷共识',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: AppRadius.pill(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_formatCount(c.participantCount)}人',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.predictionGreenText,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.people_alt_outlined,
                      size: 12,
                      color: AppColors.predictionGreenText,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            '你认为这场比赛最可能是什么结果？',
            style: TextStyle(fontSize: 11, color: AppColors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _OutcomeTile(
                  label: data.homeLabel,
                  percent: c.homePercent,
                  background: AppColors.predictionGreenSoft,
                  foreground: AppColors.predictionDeepGreen,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _OutcomeTile(
                  label: data.drawLabel,
                  percent: c.drawPercent,
                  background: AppColors.page,
                  foreground: AppColors.inkTertiary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _OutcomeTile(
                  label: data.awayLabel,
                  percent: c.awayPercent,
                  background: AppColors.predictionOrangeSoft,
                  foreground: AppColors.predictionOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OutcomeTile extends StatelessWidget {
  const _OutcomeTile({
    required this.label,
    required this.percent,
    required this.background,
    required this.foreground,
  });

  final String label;
  final int percent;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    height: 64,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(fontSize: 12, color: foreground),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$percent%',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ),
      ],
    ),
  );
}

class _MyPredictionCard extends StatelessWidget {
  const _MyPredictionCard({required this.data, this.onTap});
  final MatchPrediction data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mine = data.myPrediction;
    final canTap = data.canSubmit && onTap != null;
    final buttonLabel = mine != null
        ? '已提交'
        : data.canSubmit
        ? '去判断'
        : '已锁定';
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '我的预测',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            '免费写下概率，加入球迷共识',
            style: TextStyle(fontSize: 11, color: AppColors.inkMuted),
          ),
          if (mine != null) ...[
            const SizedBox(height: 6),
            Text(
              '${mine.homeProbability}% / ${mine.drawProbability}% / ${mine.awayProbability}% · ${mine.insightScore != null ? '${mine.insightScore}分' : '待结算'}',
              style: const TextStyle(fontSize: 11, color: AppColors.inkTertiary),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.page,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    mine != null ? '已提交判断' : '还未提交判断',
                    style: const TextStyle(fontSize: 12, color: AppColors.ink),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              SizedBox(
                height: 36,
                width: 76,
                child: FilledButton(
                  key: const ValueKey('prediction_go'),
                  onPressed: canTap ? onTap : null,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: AppColors.brand,
                    disabledBackgroundColor: AppColors.inkDisabled,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  child: Text(
                    buttonLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.data, this.onTap});
  final MatchPrediction data;
  final void Function({int? initialStake})? onTap;

  @override
  Widget build(BuildContext context) {
    final challenge = data.challenge;
    final mine = data.myPrediction;
    final balance = challenge.balance;
    final selectedStake = mine?.stake ?? 0;
    final canTap = data.canSubmit && onTap != null;
    final label = mine != null
        ? selectedStake > 0
              ? '已参与$selectedStake豆'
              : '已提交'
        : data.canSubmit
        ? '先完成预测'
        : '已锁定';
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '看台挑战',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              if (balance != null)
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: _formatCount(balance),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.predictionOrange,
                        ),
                      ),
                      const TextSpan(
                        text: ' 积分豆',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.predictionOrange,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            '完成概率判断后，可自愿参加',
            style: TextStyle(fontSize: 11, color: AppColors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.predictionOrangeSoft,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: const Text(
              '每场挑战一次，开场锁定，不涉及现金',
              style: TextStyle(fontSize: 10, color: AppColors.predictionOrange),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              for (final stake in challenge.stakes) ...[
                Expanded(
                  child: _StakePill(
                    label: '$stake豆',
                    selected: selectedStake == stake,
                    enabled: canTap,
                    onTap: canTap
                        ? () => onTap!(initialStake: stake)
                        : null,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              SizedBox(
                width: 112,
                height: 32,
                child: FilledButton(
                  onPressed: canTap && mine == null
                      ? () => onTap!()
                      : null,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: AppColors.brand,
                    disabledBackgroundColor: AppColors.inkDisabled,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StakePill extends StatelessWidget {
  const _StakePill({
    required this.label,
    required this.selected,
    required this.enabled,
    this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppRadius.sm),
    child: Container(
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.predictionOrangeSoft : AppColors.surface,
        border: Border.all(
          color: selected ? AppColors.predictionOrange : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: selected
              ? AppColors.predictionOrange
              : enabled
              ? AppColors.ink
              : AppColors.inkMuted,
        ),
      ),
    ),
  );
}

class _MorePredictions extends StatelessWidget {
  const _MorePredictions({required this.data});
  final MatchPrediction data;

  @override
  Widget build(BuildContext context) {
    if (data.morePredictions.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '更多预测',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final market in data.morePredictions) ...[
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    market.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.ink),
                  ),
                ),
                Text(
                  '${market.participantCount}人',
                  style: const TextStyle(fontSize: 11, color: AppColors.inkMuted),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${market.percent}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.brand,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.inkDisabled,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _PostMatchView extends StatelessWidget {
  const _PostMatchView({required this.data});
  final MatchPrediction data;

  @override
  Widget build(BuildContext context) {
    final post = data.postMatch;
    return SingleChildScrollView(
      key: const ValueKey('prediction_post_match'),
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostHeaderCard(data: data),
          if (post != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _ScoreCard(data: data, post: post)),
                const SizedBox(width: 9),
                Expanded(child: _ChallengeResultCard(data: data, post: post)),
              ],
            ),
            if (post.highlights.isNotEmpty) ...[
              const SizedBox(height: 10),
              _HighlightsCard(highlights: post.highlights),
            ],
            if (data.trajectory.isNotEmpty) ...[
              const SizedBox(height: 10),
              _TrajectoryCard(data: data),
            ],
          ] else ...[
            const SizedBox(height: 10),
            _ConsensusCard(data: data),
          ],
          const SizedBox(height: 14),
          Text(
            data.disclaimer,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _PostHeaderCard extends StatelessWidget {
  const _PostHeaderCard({required this.data});
  final MatchPrediction data;

  @override
  Widget build(BuildContext context) {
    final post = data.postMatch;
    final hit = post?.hit == true;
    final mine = data.myPrediction;
    final c = data.consensus;
    final home = mine?.homeProbability ?? c.homePercent;
    final draw = mine?.drawProbability ?? c.drawPercent;
    final away = mine?.awayProbability ?? c.awayPercent;
    final headline = post?.headline ?? '本场预测已结算';
    final tag = post == null
        ? '已结束'
        : hit
        ? '方向命中'
        : '方向未命中';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradientHeroDark, AppColors.gradientHeroBright],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '赛后复盘',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: hit
                      ? AppColors.predictionGreenSoft.withValues(alpha: .9)
                      : Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(AppRadius.circle),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: hit
                        ? AppColors.predictionGreenText
                        : Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            headline,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: .72),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${data.homeLabel} $home% · ${data.drawLabel} $draw% · ${data.awayLabel} $away%',
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.data, required this.post});
  final MatchPrediction data;
  final PredictionPostMatch post;

  @override
  Widget build(BuildContext context) => _Card(
    tight: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '本场预测得分',
          style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${post.score}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.predictionDeepGreen,
              ),
            ),
            const Text(
              ' /100',
              style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.predictionGreenSoft,
            borderRadius: BorderRadius.circular(AppRadius.circle),
          ),
          child: Text(
            post.calibrationLabel,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.predictionDeepGreen,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ChallengeResultCard extends StatelessWidget {
  const _ChallengeResultCard({required this.data, required this.post});
  final MatchPrediction data;
  final PredictionPostMatch post;

  @override
  Widget build(BuildContext context) {
    final stake = data.myPrediction?.stake ?? 0;
    final joined = stake > 0;
    final reward = post.rewardBeans;
    final positive = reward >= 0;
    final color = positive
        ? AppColors.predictionDeepGreen
        : AppColors.predictionOrange;
    return _Card(
      tight: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '看台挑战',
            style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                joined ? '${positive ? '+' : ''}$reward豆' : '未参与',
                style: TextStyle(
                  fontSize: joined ? 20 : 16,
                  fontWeight: FontWeight.w700,
                  color: joined ? color : AppColors.inkMuted,
                ),
              ),
              const Spacer(),
              Text(
                '${_formatCount(post.balance)}豆',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.inkTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            joined
                ? (positive
                      ? '收益$reward豆 成功返还'
                      : '未命中 扣除$stake豆')
                : '本场未参加挑战',
            style: const TextStyle(fontSize: 10, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _HighlightsCard extends StatelessWidget {
  const _HighlightsCard({required this.highlights});
  final List<String> highlights;

  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '这场你赢在哪里',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final item in highlights) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.ink,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.predictionGreenSoft,
            borderRadius: BorderRadius.circular(AppRadius.circle),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '好友邀请',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.predictionGreenText,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: AppColors.predictionGreenText,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _TrajectoryCard extends StatelessWidget {
  const _TrajectoryCard({required this.data});
  final MatchPrediction data;

  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '赛前判断轨迹',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < data.trajectory.length; i++)
          _TrajectoryRow(
            point: data.trajectory[i],
            first: i == 0,
            last: i == data.trajectory.length - 1,
          ),
        const SizedBox(height: 6),
        Text(
          '赛前共识→最终结果 ${data.postMatch?.actualOutcomeLabel ?? '—'}',
          style: const TextStyle(fontSize: 12, color: AppColors.brand),
        ),
      ],
    ),
  );
}

class _TrajectoryRow extends StatelessWidget {
  const _TrajectoryRow({
    required this.point,
    required this.first,
    required this.last,
  });

  final PredictionTrajectoryPoint point;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final dotColor = first
        ? AppColors.inkDisabled
        : last
        ? AppColors.brand
        : const Color(0xFFA8E6C3);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 18,
            child: Column(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(width: 1, color: AppColors.border),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Text(
                    point.stageLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      '${point.outcomeLabel} ${point.homePercent}%',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.tight = false});
  final Widget child;
  final bool tight;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: tight
        ? const EdgeInsets.all(12)
        : const EdgeInsets.fromLTRB(16, 10, 16, 16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: child,
  );
}

String _formatCount(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
    buffer.write(text[i]);
  }
  return buffer.toString();
}
