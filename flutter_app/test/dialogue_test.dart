import 'package:flutter_test/flutter_test.dart';
import 'package:echoes/dialogue/dialogue_controller.dart';

void main() {
  test(
    'typing, reveal, debounced advance, skip and replay preserve sequence state',
    () {
      final c = DialogueController()
        ..load(
          '{"memory":{"speaker":"Eco","lines":["Primeira voz","Segunda voz"]}}',
        );
      expect(c.start('memory'), isTrue);
      c.tick(.1);
      expect(c.visibleCharacters, 3);
      c.advance();
      expect(c.visibleText, 'Primeira voz');
      c.advance();
      expect(
        c.lineIndex,
        0,
        reason: 'A rapid repeated event must not skip a line.',
      );
      c.tick(.13);
      c.advance();
      expect(c.lineIndex, 1);
      c.skip();
      c.tick(.2);
      expect(c.active, isFalse);
      expect(c.viewed, contains('memory'));
      expect(c.start('memory'), isFalse);
      expect(c.start('memory', replay: true), isTrue);
      c.advance();
      c.tick(.13);
      c.advance();
      c.tick(.13);
      c.advance();
      c.tick(.13);
      c.advance();
      c.tick(.2);
      expect(c.active, isFalse);
      c.dispose();
    },
  );
}
