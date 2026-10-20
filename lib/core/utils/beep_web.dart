import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('window.AudioContext')
external JSFunction? get _audioContextCtor;

@JS('window.webkitAudioContext')
external JSFunction? get _webkitAudioContextCtor;

void beep() {
  try {
    final ctor = _audioContextCtor ?? _webkitAudioContextCtor;
    if (ctor == null) return;
    final ctx = ctor.callAsConstructor<JSObject>();
    final oscilador = (ctx.callMethod('createOscillator'.toJS) as JSObject);
    final ganancia = (ctx.callMethod('createGain'.toJS) as JSObject);
    (oscilador.getProperty('frequency'.toJS) as JSObject).setProperty('value'.toJS, 880.toJS);
    oscilador.callMethod('connect'.toJS, ganancia);
    ganancia.callMethod('connect'.toJS, ctx.getProperty('destination'.toJS));
    (ganancia.getProperty('gain'.toJS) as JSObject).setProperty('value'.toJS, 0.15.toJS);
    oscilador.callMethod('start'.toJS);
    final ahora = (ctx.getProperty('currentTime'.toJS) as JSNumber).toDartDouble;
    oscilador.callMethod('stop'.toJS, (ahora + 0.15).toJS);
  } catch (_) {
  }
}
