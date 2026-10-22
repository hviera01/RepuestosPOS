import 'dart:js_interop';
import 'dart:js_interop_unsafe';

void recargarPagina() {
  const script = '(async()=>{try{const r=await navigator.serviceWorker.getRegistrations();for(const x of r){await x.unregister();}const k=await caches.keys();for(const c of k){await caches.delete(c);}}catch(e){}location.reload();})()';
  globalContext.callMethod('eval'.toJS, script.toJS);
}
