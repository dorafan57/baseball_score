import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../logic/box_score_report.dart';
import '../../services/excel_export_service.dart';
import '../../services/pdf_export_service.dart';
import '../stats/box_score_view.dart';

/// ボックススコアをプレビュー表示し、PDF・Excelとして書き出せるダイアログ。
void showBoxScoreDialog(BuildContext context, {required BoxScoreReport report}) {
  showDialog(
    context: context,
    builder: (ctx) => _BoxScoreDialog(report: report),
  );
}

class _BoxScoreDialog extends StatefulWidget {
  final BoxScoreReport report;

  const _BoxScoreDialog({required this.report});

  @override
  State<_BoxScoreDialog> createState() => _BoxScoreDialogState();
}

class _BoxScoreDialogState extends State<_BoxScoreDialog> {
  bool _exporting = false;

  String get _fileNameBase =>
      '${widget.report.top.teamName}_vs_${widget.report.bottom.teamName}';

  Future<void> _exportPdf() async {
    setState(() => _exporting = true);
    try {
      final bytes = await buildBoxScorePdf(widget.report);
      await Share.shareXFiles([
        XFile.fromData(
          bytes,
          mimeType: 'application/pdf',
          name: '$_fileNameBase.pdf',
        ),
      ]);
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _exporting = true);
    try {
      final bytes = Uint8List.fromList(buildBoxScoreXlsx(widget.report));
      await Share.shareXFiles([
        XFile.fromData(
          bytes,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          name: '$_fileNameBase.xlsx',
        ),
      ]);
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: SizedBox(
        width: double.maxFinite,
        height: double.maxFinite,
        child: Column(
          children: [
            AppBar(
              title: const Text('ボックススコア'),
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(child: BoxScoreView(report: widget.report)),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _exporting ? null : _exportPdf,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('PDF書き出し'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _exporting ? null : _exportExcel,
                      icon: const Icon(Icons.table_chart),
                      label: const Text('Excel書き出し'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
