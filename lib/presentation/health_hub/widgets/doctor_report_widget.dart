import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/vitamin_d_calculator.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/uv_data_provider.dart';
import '../../../core/services/firebase_storage_service.dart';

class DoctorReportWidget extends StatefulWidget {
  const DoctorReportWidget({super.key});

  @override
  State<DoctorReportWidget> createState() => _DoctorReportWidgetState();
}

class _DoctorReportWidgetState extends State<DoctorReportWidget> {
  bool _generating = false;
  String? _uploadedUrl;

  Future<void> _generatePDF() async {
    setState(() {
      _generating = true;
      _uploadedUrl = null;
    });

    final auth = context.read<AuthProvider>();
    final uv   = context.read<UVDataProvider>();
    final p    = auth.profile!;

    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Vitamin D Health Report',
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.Text('Generated: ${AppDateUtils.formatDate(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            ]),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text('CONFIDENTIAL',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey600)),
            ),
          ]),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 12),

          // Patient info
          pw.Text('Patient Information',
               style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _pdfRow('Name',       p.name),
          _pdfRow('Age',        '${p.age} years'),
          _pdfRow('Gender',     p.gender),
          _pdfRow('City',       p.city),
          _pdfRow('Skin Type',  'Fitzpatrick Type ${p.skinTone}'),
          pw.SizedBox(height: 16),

          // Today's summary
          pw.Text('Today\'s Vitamin D Summary',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _pdfRow('Total intake',         '${uv.totalIU.round()} IU'),
          _pdfRow('From sun synthesis',   '${uv.synthesizedIU.round()} IU'),
          _pdfRow('From supplements',     '${uv.supplementIU.round()} IU'),
          _pdfRow('From diet',            '${uv.dietaryIU.round()} IU'),
          _pdfRow('Daily target',         '${p.age > 70 ? 800 : 600} IU (WHO)'),
          _pdfRow('Status',               VitaminDCalculator.statusLabel(uv.status)),
          pw.SizedBox(height: 16),

          // Weekly sessions
          pw.Text('Weekly Exposure Sessions (last 30 days)',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: ['Date', 'UV Index', 'Duration', 'IU Synthesised']
                    .map((h) => pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                )).toList(),
              ),
              ...uv.weeklySessions.map((s) => pw.TableRow(children: [
                AppDateUtils.formatDate(s.date),
                s.uvIndex.toStringAsFixed(1),
                '${s.durationMinutes.round()} min',
                '${s.synthesizedIU.round()} IU',
              ].map((cell) => pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(cell, style: const pw.TextStyle(fontSize: 9)),
              )).toList())),
              if (uv.weeklySessions.isEmpty)
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('No sessions recorded', style: const pw.TextStyle(fontSize: 9))),
                  pw.SizedBox(), pw.SizedBox(), pw.SizedBox(),
                ]),
            ],
          ),
          pw.SizedBox(height: 16),

          // Note
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              'Note: This report is generated by the Vitamin D Sensor app. '
              'Data is based on UV sensor readings and user-reported intake. '
              'Please consult your physician before making changes to supplementation.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    ));

    final bytes = await pdf.save();
    final fileName = 'VitaminD_Report_${AppDateUtils.formatDate(DateTime.now()).replaceAll(' ', '_')}.pdf';

    // Upload to Cloud Storage in the background
    try {
      final url = await FirebaseStorageService().uploadReport(
        userId: p.uid,
        pdfBytes: bytes,
        fileName: fileName,
      );
      setState(() => _uploadedUrl = url);
    } catch (_) {}

    setState(() => _generating = false);

    await Printing.sharePdf(
      bytes: bytes,
      filename: fileName,
    );
  }

  pw.Widget _pdfRow(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 5),
    child: pw.Row(children: [
      pw.SizedBox(width: 160,
          child: pw.Text('$label:', style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10))),
      pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final uv   = context.watch<UVDataProvider>();
    final auth = context.watch<AuthProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Doctor Report', style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        const Text('Export a 30-day summary to share with your physician',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 20),

        // Preview card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgCard, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('Report Preview', style: TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ]),
            const Divider(height: 20),
            _PreviewRow('Patient',       auth.profile?.name ?? '—'),
            _PreviewRow('Age',           '${auth.profile?.age ?? '—'} years'),
            _PreviewRow('City',          auth.profile?.city ?? '—'),
            _PreviewRow('Skin type',     'Fitzpatrick ${auth.profile?.skinTone ?? '—'}'),
            _PreviewRow('Today total',   '${uv.totalIU.round()} IU'),
            _PreviewRow('Status',        VitaminDCalculator.statusLabel(uv.status)),
            _PreviewRow('Sessions (30d)', '${uv.weeklySessions.length}'),
          ]),
        ),
        const SizedBox(height: 24),

        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: auth.profile == null || _generating ? null : _generatePDF,
              icon: _generating
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.share_outlined),
              label: Text(_generating ? 'Generating...' : 'Export & Share PDF'),
            ),
          ),
          if (_uploadedUrl != null) ...[
            const SizedBox(width: 12),
            IconButton.filledTonal(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _uploadedUrl!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Secure report URL copied to clipboard!'),
                    backgroundColor: AppColors.statusNormal,
                  ),
                );
              },
              icon: const Icon(Icons.copy_all_rounded),
              tooltip: 'Copy Cloud PDF Link',
            ),
          ],
        ]),
        const SizedBox(height: 12),
        const Text('The PDF will open a share sheet — send via WhatsApp, email, or save locally.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ]),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label, value;
  const _PreviewRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Expanded(child: Text(label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
      Text(value, style: const TextStyle(
          color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
    ]),
  );
}
