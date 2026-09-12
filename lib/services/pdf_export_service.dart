import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../logic/box_score_report.dart';

/// ボックススコアをA4縦のPDFとして生成する。
///
/// 既定のPDFフォントは日本語グリフを持たないため、Google Fonts の
/// Noto Sans JP を実行時に取得して埋め込む（`printing` パッケージの
/// [PdfGoogleFonts] がダウンロード・キャッシュを行う）。
Future<Uint8List> buildBoxScorePdf(BoxScoreReport report) async {
  final regular = await PdfGoogleFonts.notoSansJPRegular();
  final bold = await PdfGoogleFonts.notoSansJPBold();
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) => [
        pw.Text(
          '${report.top.teamName} vs ${report.bottom.teamName}',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        _sectionTitle('ラインスコア'),
        _lineScoreTable(context, report),
        pw.SizedBox(height: 16),
        ..._teamSection(context, report.top),
        pw.SizedBox(height: 16),
        ..._teamSection(context, report.bottom),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _sectionTitle(String text) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: 4),
  child: pw.Text(
    text,
    style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
  ),
);

pw.Widget _lineScoreTable(pw.Context context, BoxScoreReport report) {
  final innings = report.lineScore.scoresTop.length;
  return pw.TableHelper.fromTextArray(
    context: context,
    headers: ['チーム', ...List.generate(innings, (i) => '${i + 1}'), 'R', 'H', 'E'],
    data: [
      [
        report.top.teamName,
        ...report.lineScore.scoresTop.map((s) => '$s'),
        '${report.lineScore.totalScoreTop}',
        '${report.lineScore.totalHitsTop}',
        '${report.lineScore.errorsTop}',
      ],
      [
        report.bottom.teamName,
        ...report.lineScore.scoresBottom.map((s) => '$s'),
        '${report.lineScore.totalScoreBottom}',
        '${report.lineScore.totalHitsBottom}',
        '${report.lineScore.errorsBottom}',
      ],
    ],
  );
}

List<pw.Widget> _teamSection(pw.Context context, BoxScoreTeamReport team) {
  return [
    _sectionTitle('${team.teamName} 打者成績'),
    pw.TableHelper.fromTextArray(
      context: context,
      headers: const [
        '順',
        '選手名',
        '打席',
        '打数',
        '安打',
        '本塁',
        '打点',
        '得点',
        '盗塁',
        '打率',
        '出塁率',
        '長打率',
        'OPS',
        '得点圏',
      ],
      data: team.batters
          .map(
            (b) => [
              '${b.order}',
              '${b.name}(${b.position})',
              '${b.pa}',
              '${b.ab}',
              '${b.hits}',
              '${b.hr}',
              '${b.rbi}',
              '${b.runs}',
              '${b.sb}',
              b.battingAverage,
              b.onBasePercentage,
              b.sluggingPercentage,
              b.ops,
              b.rispBattingAverage,
            ],
          )
          .toList(),
    ),
    pw.SizedBox(height: 8),
    _sectionTitle('${team.teamName} 投手成績'),
    pw.TableHelper.fromTextArray(
      context: context,
      headers: const [
        '投手名',
        '回数',
        '打者',
        '安打',
        '本塁',
        '三振',
        '四球',
        '失点',
        '自責',
        '防御率',
      ],
      data: team.pitchers
          .map(
            (p) => [
              '${p.name}(${p.position})',
              p.inningsPitched,
              '${p.battersFaced}',
              '${p.hitsAllowed}',
              '${p.hrAllowed}',
              '${p.strikeouts}',
              '${p.walks}',
              '${p.runsAllowed}',
              '${p.earnedRuns}',
              p.era,
            ],
          )
          .toList(),
    ),
  ];
}
