import '/common/common.dart';

import 'shapes.dart';

typedef ButtonCallBack = void Function(bool isPressed);

base class _Button extends HookWidget {
  const _Button({
    super.key,
    required this.size,
    required this.onPressed,
    this.child,
    this.builder,
    this.padding = const EdgeInsets.all(4),
    this.decoration,
  });

  final Widget? child;
  final WidgetBuilder? builder;
  final double? size;
  final ButtonCallBack onPressed;
  final EdgeInsets padding;
  final Decoration? decoration;

  @override
  Widget build(BuildContext context) {
    final ShadThemeData(:colorScheme, :textTheme) = context.theme;
    final pressed = useState(false);
    final ctrl = useAnimationController(
      duration: 100.ms,
      reverseDuration: 100.ms,
    );
    return GestureDetector(
      onTapDown: (value) {
        pressed.value = true;
        ctrl.forward();
        onPressed(true);
      },
      onTapUp: (value) {
        pressed.value = false;
        ctrl.reverse();
        onPressed(false);
      },
      onTapCancel: () {
        pressed.value = false;
        ctrl.reverse();
        onPressed(false);
      },
      child: Container(
        height: size,
        width: size,
        padding: padding,
        clipBehavior: .antiAlias,
        decoration:
            decoration ??
            BoxDecoration(
              color: colorScheme.ds3Bg,
              border: .all(color: colorScheme.ds3Border, width: 1),
              borderRadius: .circular(size ?? 8 / 2),
            ),
        child: child ?? builder?.call(context) ?? SizedBox.shrink(),
      ).animate(controller: ctrl, autoPlay: false).scale(end: Offset(.9, .9)),
    );
  }
}

final class CircleButton extends _Button {
  const CircleButton({super.key, required super.size, required super.onPressed})
    : super(child: const CustomPaint(painter: DS3CirclePainter()));
}

final class TriangleButton extends _Button {
  const TriangleButton({
    super.key,
    required super.size,
    required super.onPressed,
  }) : super(
         child: const CustomPaint(painter: DS3TrianglePainter()),
         padding: const .all(2),
       );
}

final class CrossButton extends _Button {
  const CrossButton({super.key, required super.size, required super.onPressed})
    : super(
        child: const CustomPaint(painter: DS3CrossPainter()),
        padding: const .all(6),
      );
}

final class SquareButton extends _Button {
  const SquareButton({super.key, required super.size, required super.onPressed})
    : super(child: const CustomPaint(painter: DS3SquarePainter()));
}

final class PSButton extends _Button {
  PSButton({super.key, required super.size, required super.onPressed})
    : super(
        child: Icon(LucideIcons.house300, size: (size ?? 0) / 2),
        padding: const .all(2),
      );

  @override
  Widget build(BuildContext context) {
    return IconTheme(
      data: IconThemeData(color: context.theme.colorScheme.ds3Fg),
      child: super.build(context),
    );
  }
}

final class StartButton extends _Button {
  StartButton({super.key, required super.onPressed})
    : super(child: Text('START'), padding: const .all(2), size: null);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: DefaultTextStyle(
        style: context.textTheme.muted.mono,
        textAlign: .center,
        child: super.build(context),
      ),
    );
  }
}

final class SelectButton extends _Button {
  SelectButton({super.key, required super.onPressed})
    : super(child: Text('SELECT'), padding: const .all(2), size: null);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: DefaultTextStyle(
        style: context.textTheme.muted.mono,
        textAlign: .center,
        child: super.build(context),
      ),
    );
  }
}

final class RButton extends _Button {
  RButton(
    int number, {
    super.key,
    required this.width,
    required super.onPressed,
  }) : super(child: Text('R$number'), padding: const .all(10), size: null);

  final double? width;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: context.textTheme.muted.sm.mono,
      textAlign: .center,
      child: SizedBox(width: width, child: super.build(context)),
    );
  }
}

final class LButton extends _Button {
  LButton(
    int number, {
    super.key,
    required this.width,
    required super.onPressed,
  }) : super(child: Text('L$number'), padding: const .all(10), size: null);

  final double? width;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: context.textTheme.muted.sm.mono,
      textAlign: .center,
      child: SizedBox(width: width, child: super.build(context)),
    );
  }
}

final class DirectionButton extends _Button {
  DirectionButton({
    super.key,
    required this.direction,
    required super.size,
    required super.onPressed,
  }) : super(
         decoration: const BoxDecoration(),
         builder: (context) => CustomPaint(
           painter: DS3DirectionPainter(
             direction: direction,
             color: context.colorScheme.ds3Bg,
             borderColor: context.colorScheme.ds3Border,
           ),
         ),
       );

  factory DirectionButton.up({
    required double size,
    required ButtonCallBack onPressed,
  }) => DirectionButton(direction: .up, size: size, onPressed: onPressed);

  factory DirectionButton.down({
    required double size,
    required ButtonCallBack onPressed,
  }) => DirectionButton(direction: .down, size: size, onPressed: onPressed);

  factory DirectionButton.left({
    required double size,
    required ButtonCallBack onPressed,
  }) => DirectionButton(direction: .left, size: size, onPressed: onPressed);

  factory DirectionButton.right({
    required double size,
    required ButtonCallBack onPressed,
  }) => DirectionButton(direction: .right, size: size, onPressed: onPressed);

  final DS3Direction direction;
}
