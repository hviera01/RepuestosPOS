import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/widgets.dart';
import 'tablet_utils_stub.dart' if (dart.library.html) 'tablet_utils_web.dart' as impl;

bool esTabletTactil(BuildContext context) {
  if (MediaQuery.sizeOf(context).shortestSide < 600) return false;
  if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) return true;
  if (kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) return impl.esDispositivoTactil();
  return false;
}
