// Used where on-device scanning is not available (the web version).
import 'scan_result.dart';
export 'scan_result.dart';

bool get scannerSupported => false;

Future<ScanResult?> scanLabel({bool fromGallery = false}) async => null;
