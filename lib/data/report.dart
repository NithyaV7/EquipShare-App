import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../app_state.dart';
import '../ui/widgets.dart';

/// Builds the ESG report and opens the share or download sheet.
Future<void> exportEsgPdf(AppState s) async {
  final kg = s.deliveredKg;
  final rows = [
    for (final l in s.deliveredLots)
      [l.name, l.category.name, l.kg.toStringAsFixed(1), fmtDate(l.expiry), fmtDate(l.createdAt)]
  ];
  final doc = pw.Document();
  doc.addPage(pw.MultiPage(
    build: (c) => [
      pw.Header(level: 0, child: pw.Text('EquiShare ESG report')),
      pw.Text('Donor: ${s.userName}'),
      pw.Text('Generated: ${fmtTime(DateTime.now())}'),
      pw.SizedBox(height: 12),
      pw.Text('Delivered: ${kg.toStringAsFixed(1)} kg in ${s.deliveredLots.length} lots'),
      pw.Text('Estimated CO2e avoided: ${(kg * AppState.co2PerKg).toStringAsFixed(1)} kg'),
      pw.Text('Estimated donation value: Rs. ${(kg * AppState.rupeesPerKg).toStringAsFixed(0)}'),
      pw.SizedBox(height: 12),
      if (rows.isEmpty)
        pw.Text('No delivered lots yet.')
      else
        pw.TableHelper.fromTextArray(
          headers: ['Item', 'Type', 'Kg', 'Expiry', 'Scanned'],
          data: rows,
        ),
      pw.SizedBox(height: 12),
      pw.Text(
        'Estimates use placeholder factors (2.5 kg CO2e and Rs. 600 per kg). '
        'Use figures accepted by your accountant or regulator before filing.',
        style: const pw.TextStyle(fontSize: 9),
      ),
    ],
  ));
  await Printing.sharePdf(bytes: await doc.save(), filename: 'equishare-esg-report.pdf');
}
