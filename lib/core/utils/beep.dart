import 'beep_stub.dart' if (dart.library.html) 'beep_web.dart' as impl;

void reproducirBeep() => impl.beep();
