// Continuous scanning: the camera stays open, barcodes and dates are read from
// the live video, and you add one lot after another. Runs on the phone, so it
// works offline.
import 'dart:io' show Platform;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../app_state.dart';
import '../core/theme.dart';
import '../domain/compliance.dart';
import '../domain/date_parser.dart';
import '../ui/widgets.dart';

bool get liveScanSupported => Platform.isAndroid;

Widget buildLiveScanScreen() => const LiveScanScreen();

class LiveScanScreen extends StatefulWidget {
  const LiveScanScreen({super.key});
  @override
  State<LiveScanScreen> createState() => _LiveScanScreenState();
}

class _LiveScanScreenState extends State<LiveScanScreen> {
  CameraController? _cam;
  CameraDescription? _desc;
  final _text = TextRecognizer(script: TextRecognitionScript.latin);
  final _codes = BarcodeScanner();
  final _name = TextEditingController();
  bool _busy = false;
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _pauseUntil = DateTime.fromMillisecondsSinceEpoch(0);
  String? _barcode;
  DateTime? _expiry;
  double? _conf;
  LotCategory _cat = LotCategory.food;
  int _added = 0;
  String? _error;

  static const _orient = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        if (mounted) setState(() => _error = 'No camera found on this device.');
        return;
      }
      final desc = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );
      final c = CameraController(
        desc,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      _desc = desc;
      _cam = c;
      await c.startImageStream(_onFrame);
      if (mounted) setState(() {});
    } on CameraException catch (e) {
      if (mounted) {
        setState(() => _error = e.code.contains('Denied')
            ? 'Camera permission was refused. Allow it in the phone settings.'
            : 'Camera error: ${e.description ?? e.code}');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not start the camera: $e');
    }
  }

  InputImage? _toInput(CameraImage image) {
    final cam = _cam;
    final desc = _desc;
    if (cam == null || desc == null) return null;
    var comp = _orient[cam.value.deviceOrientation];
    if (comp == null) return null;
    if (desc.lensDirection == CameraLensDirection.front) {
      comp = (desc.sensorOrientation + comp) % 360;
    } else {
      comp = (desc.sensorOrientation - comp + 360) % 360;
    }
    final rotation = InputImageRotationValue.fromRawValue(comp);
    if (rotation == null) return null;
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null || format != InputImageFormat.nv21 || image.planes.length != 1) {
      return null;
    }
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_busy || !mounted) return;
    final now = DateTime.now();
    if (now.isBefore(_pauseUntil) || now.difference(_last).inMilliseconds < 600) return;
    _busy = true;
    _last = now;
    try {
      final input = _toInput(image);
      if (input == null) return;
      final text = (await _text.processImage(input)).text;
      final codes = await _codes.processImage(input);
      final code = codes.isEmpty ? null : codes.first.rawValue;
      final p = parseExpiryFromText(text);
      if (!mounted) return;
      setState(() {
        if (code != null) _barcode = code;
        if (p != null) {
          _expiry = p.date;
          _conf = p.confidence;
        }
        if (_name.text.isEmpty) {
          final first = text
              .split('\n')
              .map((e) => e.trim())
              .firstWhere((e) => e.length > 2 && !RegExp(r'^[\d\s/.\-]+$').hasMatch(e),
                  orElse: () => '');
          if (first.isNotEmpty) _name.text = first;
        }
      });
    } catch (_) {
      // Skip a bad frame.
    } finally {
      _busy = false;
    }
  }

  void _add() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      snack(context, 'Type the item name first.');
      return;
    }
    AppScope.read(context).addLot(
      name: name,
      barcode: _barcode ?? '',
      category: _cat,
      expiry: _expiry,
      kg: 1,
    );
    setState(() {
      _added++;
      _name.clear();
      _barcode = null;
      _expiry = null;
      _conf = null;
      _pauseUntil = DateTime.now().add(const Duration(seconds: 2));
    });
  }

  @override
  void dispose() {
    final c = _cam;
    _cam = null;
    _name.dispose();
    () async {
      try {
        await c?.stopImageStream();
      } catch (_) {}
      await c?.dispose();
      await _text.close();
      await _codes.close();
    }();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = _cam;
    final result = evaluate(name: _name.text, category: _cat, expiry: _expiry, rules: s.rules);
    final conf = _conf;
    Widget body;
    if (_error != null) {
      body = Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)));
    } else if (c == null || !c.value.isInitialized) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = Column(children: [
        Expanded(flex: 3, child: ClipRect(child: Center(child: CameraPreview(c)))),
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Barcode: ${_barcode ?? 'point at the barcode'}'),
              Text(_expiry == null
                  ? 'Expiry: point at the date'
                  : 'Expiry: ${fmtDate(_expiry)}${conf != null && conf < 0.8 ? ' (low confidence, check it)' : ''}'),
              const SizedBox(height: 8),
              TextField(
                controller: _name,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                    labelText: 'Item name', border: OutlineInputBorder(), isDense: true),
              ),
              const SizedBox(height: 8),
              SegmentedButton<LotCategory>(
                segments: const [
                  ButtonSegment(value: LotCategory.food, label: Text('Food')),
                  ButtonSegment(value: LotCategory.medicine, label: Text('Medicine')),
                ],
                selected: {_cat},
                onSelectionChanged: (v) => setState(() => _cat = v.first),
              ),
              const SizedBox(height: 8),
              Row(children: [
                VerdictBadge(result.verdict),
                const SizedBox(width: 8),
                Expanded(child: Text(result.reason, style: const TextStyle(fontSize: 12))),
              ]),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _add, child: const Text('Add to batch and keep scanning')),
            ]),
          ),
        ),
      ]);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Live scan · $_added added'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
        ],
      ),
      backgroundColor: Tokens.background,
      body: body,
    );
  }
}
