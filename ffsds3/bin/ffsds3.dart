import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:ffsds3/ffsds3.dart';

Future<void> main() async {
  final (gadget, controller) = createDualshock3();

  StreamSubscription<void>? stdinSubscription;
  try {
    final reg = await gadget.register();
    reg.bind(defaultUDC);
    await reg.udc?.awaitState(.configured);
    stdout.writeln(
      'Commands: ps, cross, square, circle, triangle, start, quit',
    );
    stdinSubscription = _loop(controller);
    await ProcessSignal.sigint.watch().first;
  } catch (e, st) {
    stderr.writeln('ERROR: $e\n$st');
  } finally {
    await stdinSubscription?.cancel();
    await gadget.remove();
  }
}

StreamSubscription<void> _loop(Dualshock3 c) {
  stdin.lineMode = true;

  const btns = {
    'ps': DS3Input.ps,
    'x': DS3Input.cross,
    'cross': DS3Input.cross,
    'o': DS3Input.circle,
    'circle': DS3Input.circle,
    'c': DS3Input.circle,
    'square': DS3Input.square,
    's': DS3Input.square,
    'triangle': DS3Input.triangle,
    't': DS3Input.triangle,
    'start': DS3Input.start,
    'select': DS3Input.select,
    'l1': DS3Input.l1,
    'l2': DS3Input.l2,
    'l3': DS3Input.l3,
    'r1': DS3Input.r1,
    'r2': DS3Input.r2,
    'r3': DS3Input.r3,
    'up': DS3Input.up,
    'u': DS3Input.up,
    'down': DS3Input.down,
    'd': DS3Input.down,
    'left': DS3Input.left,
    'l': DS3Input.left,
    'right': DS3Input.right,
    'r': DS3Input.right,
  };

  int randomByte() => (Random().nextDouble() * 255).toInt();

  return stdin.transform(const SystemEncoding().decoder).listen((line) {
    final cmd = line.trim().toLowerCase();
    switch (cmd) {
      case 'stk':
        c.input.setSticks(
          left: (x: randomByte(), y: randomByte()),
          right: (x: randomByte(), y: randomByte()),
        );
      case final command when btns.containsKey(command):
        final btn = btns[command]!;
        final pressed = !c.input.pressed(btn.bit);
        c.input.setInput(btn.bit, pressed);
    }
    stdout.writeln(c.input);
  });
}
