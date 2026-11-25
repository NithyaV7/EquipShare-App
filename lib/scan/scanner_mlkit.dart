// Android scanner. Text and barcode models run on the phone, so it works offline.
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'scan_result.dart';
export 'scan_result.dart';

bool get scannerSupported => true;

Future<ScanResult?> scanLabel({bool fromGallery = false}) async {
  final file = await ImagePicker().pickImage(
    source: fromGallery ? ImageSource.gallery : ImageSource.camera,
    imageQuality: 90,
  );
  if (file == null) return null;
  final input = InputImage.fromFilePath(file.path);
  final textReader = TextRecognizer(script: TextRecognitionScript.latin);
  final barcodeReader = BarcodeScanner();
  try {
    final text = (await textReader.processImage(input)).text;
    final codes = await barcodeReader.processImage(input);
    final code = codes.isEmpty ? null : codes.first.rawValue;
    return ScanResult(text, code);
  } finally {
    await textReader.close();
    await barcodeReader.close();
  }
}
