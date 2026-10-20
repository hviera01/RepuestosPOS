import 'dart:js_interop';
import 'dart:js_interop_unsafe';

bool esDispositivoTactil() {
  try {
    final navigator = globalContext.getProperty('navigator'.toJS) as JSObject;
    final maxTouchPoints = navigator.getProperty('maxTouchPoints'.toJS);
    if (maxTouchPoints == null) return false;
    return (maxTouchPoints as JSNumber).toDartDouble > 0;
  } catch (_) {
    return false;
  }
}
