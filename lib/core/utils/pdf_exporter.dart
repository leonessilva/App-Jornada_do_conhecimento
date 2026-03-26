import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/repositories/admin_repository.dart';

class PdfExporter {
  static Future<void> exportSummary(List<ParticipantStats> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Jornada do Conhecimento — Relatório de Participantes',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Gerado em: ${_fmtDate(DateTime.now())}   '
              'Total: ${data.length} participantes',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.Divider(),
          ],
        ),
        build: (_) => [
          // Stats summary
          _buildStatsBox(data),
          pw.SizedBox(height: 16),
          // Table
          _buildTable(data),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'jornada_relatorio_${_stamp()}.pdf',
    );
  }

  static pw.Widget _buildStatsBox(List<ParticipantStats> data) {
    final comPre = data.where((s) => s.pctPre != null).toList();
    final comPos = data.where((s) => s.pctPos != null).toList();
    final ambos = data.where((s) => s.pctPre != null && s.pctPos != null).toList();

    final avgPre = comPre.isEmpty ? null :
        comPre.map((s) => s.pctPre!).reduce((a, b) => a + b) / comPre.length;
    final avgPos = comPos.isEmpty ? null :
        comPos.map((s) => s.pctPos!).reduce((a, b) => a + b) / comPos.length;
    final avgGanho = ambos.isEmpty ? null :
        ambos.map((s) => s.ganho!).reduce((a, b) => a + b) / ambos.length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        border: pw.Border.all(color: PdfColors.green200),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _statItem('Participantes', '${data.length}'),
          _statItem('Média Pré',
              avgPre != null ? '${avgPre.toStringAsFixed(1)}%' : '—'),
          _statItem('Média Pós',
              avgPos != null ? '${avgPos.toStringAsFixed(1)}%' : '—'),
          _statItem('Ganho Médio',
              avgGanho != null
                  ? '${avgGanho >= 0 ? '+' : ''}${avgGanho.toStringAsFixed(1)}%'
                  : '—'),
        ],
      ),
    );
  }

  static pw.Widget _statItem(String label, String value) => pw.Column(
        children: [
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Text(label,
              style: const pw.TextStyle(
                  fontSize: 9, color: PdfColors.grey600)),
        ],
      );

  static pw.Widget _buildTable(List<ParticipantStats> data) {
    final headers = [
      '#', 'Nome', 'Sexo', 'Faixa', 'Município', 'UF',
      'Pré%', 'Pós%', 'Ganho',
    ];

    return pw.TableHelper.fromTextArray(
      headers: headers,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 9,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellHeight: 22,
      columnWidths: {
        0: const pw.FixedColumnWidth(20),
        1: const pw.FlexColumnWidth(2.5),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.8),
        5: const pw.FixedColumnWidth(25),
        6: const pw.FixedColumnWidth(35),
        7: const pw.FixedColumnWidth(35),
        8: const pw.FixedColumnWidth(40),
      },
      data: List.generate(data.length, (i) {
        final s = data[i];
        final p = s.participant;
        final ganho = s.ganho;
        return [
          '${i + 1}',
          p.nome.isEmpty ? '—' : p.nome,
          p.sexo,
          p.idadeFaixa,
          p.municipio,
          p.estado,
          s.pctPre != null ? '${s.pctPre!.toStringAsFixed(0)}%' : '—',
          s.pctPos != null ? '${s.pctPos!.toStringAsFixed(0)}%' : '—',
          ganho != null
              ? '${ganho >= 0 ? '+' : ''}${ganho.toStringAsFixed(0)}%'
              : '—',
        ];
      }),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
    );
  }

  static String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';

  static String _stamp() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}';
  }
}
