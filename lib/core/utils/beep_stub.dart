import 'package:flutter/services.dart';

void beep() {
  SystemSound.play(SystemSoundType.click);
  HapticFeedback.mediumImpact();
}
