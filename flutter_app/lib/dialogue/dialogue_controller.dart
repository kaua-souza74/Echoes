import 'dart:convert';
import 'package:flutter/foundation.dart';

class DialogueSequence {
  const DialogueSequence(this.id, this.speaker, this.lines);
  final String id, speaker;
  final List<String> lines;
}

class DialogueController extends ChangeNotifier {
  final Map<String, DialogueSequence> sequences = {};
  final Set<String> viewed = {};
  DialogueSequence? sequence;
  int lineIndex = 0, visibleCharacters = 0;
  double _typing = 0, _cooldown = 0;
  double _age = 0, _exitAge = 0;
  bool closing = false;
  double get opacity => (closing ? 1 - _exitAge / .2 : _age / .25).clamp(0, 1);
  double charactersPerSecond = 32;
  bool get active => sequence != null;
  String get fullText => active ? sequence!.lines[lineIndex] : '';
  String get visibleText =>
      fullText.substring(0, visibleCharacters.clamp(0, fullText.length));
  bool get typing => active && visibleCharacters < fullText.length;

  void load(String source) {
    final data = jsonDecode(source) as Map<String, dynamic>;
    for (final e in data.entries) {
      sequences[e.key] = DialogueSequence(
        e.key,
        e.value['speaker'],
        List<String>.from(e.value['lines']),
      );
    }
  }

  bool start(String id, {bool replay = false}) {
    if (active ||
        (!replay && viewed.contains(id)) ||
        !sequences.containsKey(id)) {
      return false;
    }
    sequence = sequences[id];
    lineIndex = visibleCharacters = 0;
    _typing = _cooldown = 0;
    _age = _exitAge = 0;
    closing = false;
    notifyListeners();
    return true;
  }

  void tick(double dt) {
    if (!active) return;
    _age += dt;
    if (closing) {
      _exitAge += dt;
      if (_exitAge >= .2) {
        sequence = null;
        closing = false;
        notifyListeners();
      }
      return;
    }
    _cooldown = (_cooldown - dt).clamp(0, .12);
    if (!typing) return;
    _typing += dt * charactersPerSecond;
    final count = _typing.floor().clamp(0, fullText.length);
    if (count != visibleCharacters) {
      visibleCharacters = count;
      notifyListeners();
    }
  }

  void advance() {
    if (!active || closing || _cooldown > 0) return;
    _cooldown = .12;
    if (typing) {
      visibleCharacters = fullText.length;
      _typing = visibleCharacters.toDouble();
    } else if (lineIndex + 1 < sequence!.lines.length) {
      lineIndex++;
      visibleCharacters = 0;
      _typing = 0;
    } else {
      _close();
      return;
    }
    notifyListeners();
  }

  void skip() {
    if (!active || closing) return;
    _close();
  }

  void _close() {
    viewed.add(sequence!.id);
    closing = true;
    _exitAge = 0;
    notifyListeners();
  }

  void dismissImmediately() {
    if (!active) return;
    viewed.add(sequence!.id);
    sequence = null;
    closing = false;
    notifyListeners();
  }
}
