import 'package:flutter/material.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../domain/prediction_models.dart';

Future<bool?> showPredictionSheet(
  BuildContext context, {
  required MatchPrediction data,
  required Future<void> Function(
    int homeProbability,
    int drawProbability,
    int awayProbability,
    int stake,
  )
  onSubmit,
  int? initialStake,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .5),
    builder: (_) => PredictionSheet(
      data: data,
      onSubmit: onSubmit,
      initialStake: initialStake,
    ),
  );
}

class PredictionSheet extends StatefulWidget {
  const PredictionSheet({
    required this.data,
    required this.onSubmit,
    this.initialStake,
    super.key,
  });

  final MatchPrediction data;
  final Future<void> Function(int, int, int, int) onSubmit;
  final int? initialStake;

  @override
  State<PredictionSheet> createState() => _PredictionSheetState();
}

class _PredictionSheetState extends State<PredictionSheet> {
  late int _home;
  late int _draw;
  late int _away;
  late int _stake;
  String? _error;
  bool _submitting = false;

  int get _balance => widget.data.challenge.balance ?? 0;

  @override
  void initState() {
    super.initState();
    final mine = widget.data.myPrediction;
    _home = mine?.homeProbability ?? 64;
    _draw = mine?.drawProbability ?? 22;
    _away = mine?.awayProbability ?? 14;
    final preferred = widget.initialStake ?? (mine?.stake ?? 0);
    _stake = _validStake(preferred) ? preferred : 0;
    if (_stake == 0 && widget.data.challenge.enabled && _balance >= 30) {
      _stake = 30;
    }
  }

  bool _validStake(int stake) {
    if (stake == 0) return true;
    if (!widget.data.challenge.enabled) return false;
    if (!widget.data.challenge.stakes.contains(stake)) return false;
    return _balance >= stake;
  }

  void _setProbability(int index, int value) {
    final next = [_home, _draw, _away];
    next[index] = value.clamp(0, 100);
    final remaining = 100 - next[index];
    final others = [0, 1, 2]..remove(index);
    final first = others[0];
    final second = others[1];
    final oldTotal = next[first] + next[second];
    int firstValue;
    if (oldTotal <= 0) {
      firstValue = remaining ~/ 2;
    } else {
      firstValue = (remaining * next[first] / oldTotal).round();
    }
    firstValue = firstValue.clamp(0, remaining);
    next[first] = firstValue;
    next[second] = remaining - firstValue;
    setState(() {
      _home = next[0];
      _draw = next[1];
      _away = next[2];
    });
  }

  void _applyPreset(List<int> preset) {
    final total = preset.fold<int>(0, (sum, value) => sum + value);
    final normalized = total == 100
        ? preset
        : [preset[0], preset[1], 100 - preset[0] - preset[1]];
    setState(() {
      _home = normalized[0];
      _draw = normalized[1];
      _away = normalized[2];
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_home + _draw + _away != 100) {
      setState(() => _error = '三项概率合计必须为 100%。');
      return;
    }
    if (_stake > 0 && _balance < _stake) {
      setState(() => _error = '看台豆余额不足，当前余额 $_balance 豆。');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_home, _draw, _away, _stake);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AppNetworkException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = '提交失败，请稍后重试。';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final highest = [_home, _draw, _away].reduce((a, b) => a > b ? a : b);
    final direction = _home == highest
        ? data.homeLabel
        : _draw == highest
        ? data.drawLabel
        : data.awayLabel;
    return Container(
      height: MediaQuery.sizeOf(context).height - 144,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetHeader(
              subtitle: '${data.homeTeam.shortName} VS ${data.awayTeam.shortName} · 赛果',
              onClose: _submitting ? null : () => Navigator.of(context).pop(),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ConsensusBlock(data: data),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      '分配你的概率',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    const Text(
                      '三项合计100%，概率越高代表你越有信心',
                      style: TextStyle(fontSize: 11, color: AppColors.inkMuted),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ProbabilityRow(
                      label: data.homeLabel,
                      value: _home,
                      color: AppColors.brand,
                      onChanged: (value) => _setProbability(0, value),
                    ),
                    _ProbabilityRow(
                      label: data.drawLabel,
                      value: _draw,
                      color: AppColors.inkMuted,
                      onChanged: (value) => _setProbability(1, value),
                    ),
                    _ProbabilityRow(
                      label: data.awayLabel,
                      value: _away,
                      color: AppColors.predictionOrange,
                      onChanged: (value) => _setProbability(2, value),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickChoice(
                            label: '接近五五开',
                            onTap: () => _applyPreset(const [34, 33, 33]),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: _QuickChoice(
                            label: '看好${data.homeTeam.shortName}',
                            onTap: () => _applyPreset(const [64, 22, 14]),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: _QuickChoice(
                            label: '看好${data.awayTeam.shortName}',
                            onTap: () => _applyPreset(const [16, 24, 60]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        const Text(
                          '看台挑战',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        const Text(
                          '可选',
                          style: TextStyle(fontSize: 11, color: AppColors.inkMuted),
                        ),
                        const Spacer(),
                        Text(
                          '余额${_formatCount(_balance)}豆',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.predictionOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '将挑战豆放在你的概率结果【$direction】上',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.inkTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        _StakeChoice(
                          label: '不参与',
                          selected: _stake == 0,
                          onTap: () => setState(() => _stake = 0),
                        ),
                        for (final stake in data.challenge.stakes) ...[
                          const SizedBox(width: AppSpacing.xs),
                          _StakeChoice(
                            label: '$stake豆',
                            selected: _stake == stake,
                            enabled:
                                data.challenge.enabled && _balance >= stake,
                            onTap: data.challenge.enabled && _balance >= stake
                                ? () => setState(() => _stake = stake)
                                : null,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.predictionOrangeSoft,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '挑战说明',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.predictionOrange,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            _stake == 0
                                ? '本次不参与看台挑战。提交后判断立即锁定。'
                                : '挑战成功，返还$_stake豆并获胜，失败扣除$_stake豆。',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.ink,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                children: [
                  Text(
                    data.disclaimer,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      key: const ValueKey('prediction_submit'),
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        disabledBackgroundColor: AppColors.inkDisabled,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _stake > 0 ? '提交判断并开始挑战' : '提交判断',
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
          ],
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.subtitle, this.onClose});
  final String subtitle;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '写下我的判断',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
        IconButton(
          key: const ValueKey('prediction_sheet_close'),
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded, color: AppColors.inkMuted),
        ),
      ],
    ),
  );
}

class _ConsensusBlock extends StatelessWidget {
  const _ConsensusBlock({required this.data});
  final MatchPrediction data;

  @override
  Widget build(BuildContext context) {
    final c = data.consensus;
    final highest = [c.homePercent, c.drawPercent, c.awayPercent].reduce(
      (a, b) => a > b ? a : b,
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '当前球迷共识',
                  style: TextStyle(fontSize: 11, color: AppColors.inkTertiary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${data.homeLabel} ${c.homePercent}% · ${data.drawLabel} ${c.drawPercent}% · ${data.awayLabel} ${c.awayPercent}%',
                  style: const TextStyle(fontSize: 12, color: AppColors.ink),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.predictionGreenSoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              '$highest%',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.predictionDeepGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProbabilityRow extends StatelessWidget {
  const _ProbabilityRow({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final int value;
  final Color color;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.ink),
            ),
          ),
          Text(
            '$value%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 8,
          activeTrackColor: color,
          inactiveTrackColor: AppColors.border,
          thumbColor: color,
          overlayColor: color.withValues(alpha: .12),
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          trackShape: const RoundedRectSliderTrackShape(),
        ),
        child: Slider(
          value: value.toDouble(),
          min: 0,
          max: 100,
          divisions: 100,
          onChanged: (next) => onChanged(next.round()),
        ),
      ),
    ],
  );
}

class _QuickChoice extends StatelessWidget {
  const _QuickChoice({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppRadius.sm),
    child: Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          style: const TextStyle(fontSize: 12, color: AppColors.inkTertiary),
        ),
      ),
    ),
  );
}

class _StakeChoice extends StatelessWidget {
  const _StakeChoice({
    required this.label,
    required this.selected,
    this.enabled = true,
    this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.predictionOrangeSoft
              : enabled
              ? AppColors.surface
              : AppColors.surfaceMuted,
          border: Border.all(
            color: selected ? AppColors.predictionOrange : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? AppColors.predictionOrange
                : enabled
                ? AppColors.ink
                : AppColors.inkDisabled,
          ),
        ),
      ),
    ),
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
