import 'package:flutter/material.dart';

/// Semantic palette for the football community visual language.
///
/// Every value is transcribed from the Lanhu (Figma JSON) source of truth.
/// See `docs/14_LANHU_ALIGNMENT_PLAN.md` §2.1 — do not hand-pick colours
/// outside this file.
abstract final class AppColors {
  // Brand greens.
  static const brand = Color(0xFF23BD69);
  static const brandBright = Color(0xFF1CBC68);
  static const brandDark = Color(0xFF118A50);
  static const brandSoft = Color(0xFFE7F7EE);
  static const accent = Color(0xFF2BA774);
  static const onBrand = Color(0xFFFFFFFF);

  // Surfaces.
  static const page = Color(0xFFF5F6F7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF3F4F5);

  // Text ladder: primary -> tertiary -> muted -> disabled.
  static const ink = Color(0xFF1D2129);
  static const inkTertiary = Color(0xFF4E5969);
  static const inkMuted = Color(0xFF86909C);
  static const inkDisabled = Color(0xFFC9CDD4);

  // Lines.
  static const border = Color(0xFFE5E6EB);
  static const divider = Color(0xFFE5E6EB);
  static const dividerLight = Color(0xFFF2F3F5);
  static const surfaceSubtle = Color(0xFFF7F8FA);

  // Feedback.
  static const success = Color(0xFF23BD69);
  static const error = Color(0xFFE53935);
  static const errorSoft = Color(0xFFFFF1F0);
  static const warning = Color(0xFFEBB737);

  // Card gradient endpoints — use [AppGradients] instead of these directly.
  static const matchDark = Color(0xFF12444D);
  static const matchBright = Color(0xFF34896C);
  static const topicBlue = Color(0xFF1E48B6);
  static const topicBlueBright = Color(0xFF4B8AF4);

  /// 个人主页 / 比赛详情 hero 遮罩渐变（蓝湖 p23、p31 实测）。
  static const gradientHeroDark = Color(0xFF032122);
  static const gradientHeroBright = Color(0xFF1B5D4F);

  /// 球队/比赛详情页深酒红底色（蓝湖 `#971E48`）。
  static const teamHero = Color(0xFF971E48);

  // Prediction tab (Lanhu 预测1/2/3): green/orange semantic accents.
  static const predictionDeepGreen = Color(0xFF197C4E);
  static const predictionGreenText = Color(0xFF338C62);
  static const predictionGreenSoft = Color(0xFFE9F9F0);
  static const predictionOrange = Color(0xFFEB5008);
  static const predictionOrangeSoft = Color(0xFFFFF0E4);
}
