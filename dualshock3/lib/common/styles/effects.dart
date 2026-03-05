import 'dart:math';

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart' show Easing;
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart' show Widget;
import 'package:flutter_animate/flutter_animate.dart';
import '/common/styles/styles.dart';

abstract final class Effects {
  static const veryShortDuration = Duration(milliseconds: 150);
  static const shortDuration = Duration(milliseconds: 250);
  static const mediumDuration = Duration(milliseconds: 500);
  static const longDuration = Duration(milliseconds: 800);
  static const veryLongDuration = Duration(milliseconds: 1200);

  static const engagingCurve = Cubic(.4, 0, .2, 1);
  static const playfulCurve = Cubic(.22, .74, .38, 19);
  static const swiftOutCurve = Cubic(.175, .885, .32, 1.1);
  static const snappyOutCurve = Cubic(.19, 1, .22, 1);
  static const snappyInCurve = Cubic(.22, 1, .19, 1);
  static const outQuartCurve = Cubic(.165, .84, .44, 1);
  static const outQuintCurve = Cubic(.23, 1, .32, 1);

  static final windowPadding = <Effect<double>>[
    const PaddingEffect(
      padding: EdgeInsets.all(6),
      curve: Easing.emphasizedDecelerate,
      duration: Duration(seconds: 1),
    ),
    const FadeEffect(begin: 0, end: 1),
  ];

  static final fadeIn = <Effect<double>>[const FadeEffect(begin: 0, end: 1)];

  static final fadeOut = <Effect<double>>[const FadeEffect(begin: 1, end: 0)];

  static const blur = BlurEffect(
    duration: Duration(milliseconds: 300),
    curve: Easing.emphasizedDecelerate,
    begin: Offset(8, 8),
    end: Offset.zero,
  );

  static const scaleIn = ScaleEffect(
    duration: Duration(milliseconds: 300),
    curve: Easing.emphasizedDecelerate,
    begin: Offset(1.1, 1.1),
    end: Offset(1, 1),
  );
}

extension ListAnimationX<T> on List<Widget> {
  List<Widget> slideUpReveal({
    Duration delay = Duration.zero,
    Duration interval = const Duration(milliseconds: 52),
    Duration fadeInDuration = const Duration(milliseconds: 200),
  }) => animate(interval: interval)
      .then(delay: delay)
      .slideY(begin: 0.2, end: 0, curve: Effects.outQuintCurve)
      .fadeIn(duration: fadeInDuration, curve: Effects.outQuintCurve);
}

extension WidgetAnimationX on Widget {
  Animate focusAnimation({
    Duration duration = const Duration(milliseconds: 500),
    required Color color,
    AnimationController? controller,
    Duration delay = Duration.zero,
    Curve curve = Curves.easeInOut,
    double angle = pi / 2,
  }) {
    return animate(
      controller: controller,
      onComplete: (c) => c.reset(),
    ).shimmer(
      delay: delay,
      color: color,
      duration: duration,
      curve: curve,
      angle: angle,
    );
  }
}
