import 'package:excel/excel.dart';

import '../logic/box_score_report.dart';

/// ボックススコアを3シート構成（ラインスコア／打者成績／投手成績）の
/// xlsxファイルとしてバイト列で生成する。
List<int> buildBoxScoreXlsx(BoxScoreReport report) {
  final excel = Excel.createExcel();
  final defaultSheet = excel.getDefaultSheet();

  _writeLineScoreSheet(excel, report);
  _writeBatterSheet(excel, '打者成績', report);
  _writePitcherSheet(excel, '投手成績', report);

  if (defaultSheet != null && defaultSheet != 'ラインスコア') {
    excel.delete(defaultSheet);
  }

  return excel.encode()!;
}

List<TextCellValue> _row(List<String> values) =>
    values.map(TextCellValue.new).toList();

void _writeLineScoreSheet(Excel excel, BoxScoreReport report) {
  const sheetName = 'ラインスコア';
  final innings = report.lineScore.scoresTop.length;
  excel.appendRow(
    sheetName,
    _row(['チーム', ...List.generate(innings, (i) => '${i + 1}'), 'R', 'H', 'E']),
  );
  excel.appendRow(
    sheetName,
    _row([
      report.top.teamName,
      ...report.lineScore.scoresTop.map((s) => '$s'),
      '${report.lineScore.totalScoreTop}',
      '${report.lineScore.totalHitsTop}',
      '${report.lineScore.errorsTop}',
    ]),
  );
  excel.appendRow(
    sheetName,
    _row([
      report.bottom.teamName,
      ...report.lineScore.scoresBottom.map((s) => '$s'),
      '${report.lineScore.totalScoreBottom}',
      '${report.lineScore.totalHitsBottom}',
      '${report.lineScore.errorsBottom}',
    ]),
  );
}

void _writeBatterSheet(Excel excel, String sheetName, BoxScoreReport report) {
  excel.appendRow(sheetName, _row([
    'チーム', '順', '選手名', '打席', '打数', '安打', '2塁打', '3塁打', '本塁打',
    '打点', '得点', '盗塁', '四球', '死球', '犠打', '犠飛', '三振', '敵失',
    '打率', '出塁率', '長打率', 'OPS', '得点圏打率', '失策',
  ]));
  for (final team in [report.top, report.bottom]) {
    for (final b in team.batters) {
      excel.appendRow(sheetName, _row([
        team.teamName,
        '${b.order}',
        '${b.name}(${b.position})',
        '${b.pa}',
        '${b.ab}',
        '${b.hits}',
        '${b.doubles}',
        '${b.triples}',
        '${b.hr}',
        '${b.rbi}',
        '${b.runs}',
        '${b.sb}',
        '${b.bb}',
        '${b.hbp}',
        '${b.sh}',
        '${b.sf}',
        '${b.so}',
        '${b.roe}',
        b.battingAverage,
        b.onBasePercentage,
        b.sluggingPercentage,
        b.ops,
        b.rispBattingAverage,
        '${b.errorsCommitted}',
      ]));
    }
  }
}

void _writePitcherSheet(Excel excel, String sheetName, BoxScoreReport report) {
  excel.appendRow(sheetName, _row([
    'チーム', '投手名', '投球回', '対戦打者', '被安打', '被本塁打', '奪三振',
    '与四球', '与死球', '失点', '自責点', '防御率',
  ]));
  for (final team in [report.top, report.bottom]) {
    for (final p in team.pitchers) {
      excel.appendRow(sheetName, _row([
        team.teamName,
        '${p.name}(${p.position})',
        p.inningsPitched,
        '${p.battersFaced}',
        '${p.hitsAllowed}',
        '${p.hrAllowed}',
        '${p.strikeouts}',
        '${p.walks}',
        '${p.hitByPitch}',
        '${p.runsAllowed}',
        '${p.earnedRuns}',
        p.era,
      ]));
    }
  }
}
