import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class Gap extends StatelessWidget {
  const Gap(
    this.mainAxisExtent, {
    super.key,
    this.crossAxisExtent,
    this.color,
    this.flexible = false,
  }) : assert(mainAxisExtent >= 0);

  const Gap.expand(
    double mainAxisExtent, {
    Key? key,
    Color? color,
    bool flexible = false,
  }) : this(
         mainAxisExtent,
         key: key,
         crossAxisExtent: double.infinity,
         color: color,
         flexible: flexible,
       );
  final double mainAxisExtent;
  final double? crossAxisExtent;
  final Color? color;
  final bool flexible;

  @override
  Widget build(BuildContext context) {
    final Widget gap = _RawGap(
      mainAxisExtent,
      crossAxisExtent: crossAxisExtent,
      color: color,
      fallbackDirection: Scrollable.maybeOf(context)?.axisDirection != null
          ? axisDirectionToAxis(Scrollable.maybeOf(context)!.axisDirection)
          : null,
    );
    return flexible ? Flexible(child: gap) : gap;
  }
}

class _RawGap extends LeafRenderObjectWidget {
  const _RawGap(
    this.mainAxisExtent, {
    this.crossAxisExtent,
    this.color,
    this.fallbackDirection,
  });

  final double mainAxisExtent;
  final double? crossAxisExtent;
  final Color? color;
  final Axis? fallbackDirection;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderGap(
    mainAxisExtent: mainAxisExtent,
    crossAxisExtent: crossAxisExtent ?? 0,
    color: color,
    fallbackDirection: fallbackDirection,
  );

  @override
  void updateRenderObject(BuildContext context, RenderGap renderObject) {
    renderObject
      ..mainAxisExtent = mainAxisExtent
      ..crossAxisExtent = crossAxisExtent ?? 0
      ..color = color
      ..fallbackDirection = fallbackDirection;
  }
}

class RenderGap extends RenderBox {
  RenderGap({
    required double mainAxisExtent,
    double? crossAxisExtent,
    Axis? fallbackDirection,
    Color? color,
  }) : _mainAxisExtent = mainAxisExtent,
       _crossAxisExtent = crossAxisExtent,
       _fallbackDirection = fallbackDirection,
       _color = color;

  double _mainAxisExtent;
  double? _crossAxisExtent;
  Axis? _fallbackDirection;
  Color? _color;

  double get mainAxisExtent => _mainAxisExtent;

  set mainAxisExtent(double value) {
    if (_mainAxisExtent != value) {
      _mainAxisExtent = value;
      markNeedsLayout();
    }
  }

  double? get crossAxisExtent => _crossAxisExtent;

  set crossAxisExtent(double? value) {
    if (_crossAxisExtent != value) {
      _crossAxisExtent = value;
      markNeedsLayout();
    }
  }

  Axis? get fallbackDirection => _fallbackDirection;

  set fallbackDirection(Axis? value) {
    if (_fallbackDirection != value) {
      _fallbackDirection = value;
      markNeedsLayout();
    }
  }

  Color? get color => _color;

  set color(Color? value) {
    if (_color != value) {
      _color = value;
      markNeedsPaint();
    }
  }

  Axis? get _direction => parent is RenderFlex
      ? (parent! as RenderFlex).direction
      : fallbackDirection;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final dir = _direction;
    if (dir == null) {
      throw FlutterError(
        'Gap must be inside a Flex or have a fallbackDirection.',
      );
    }
    return dir == Axis.horizontal
        ? constraints.constrain(Size(mainAxisExtent, crossAxisExtent ?? 0))
        : constraints.constrain(Size(crossAxisExtent ?? 0, mainAxisExtent));
  }

  @override
  void performLayout() => size = computeDryLayout(constraints);

  @override
  void paint(PaintingContext context, Offset offset) {
    if (color != null) {
      context.canvas.drawRect(offset & size, Paint()..color = color!);
    }
  }
}
