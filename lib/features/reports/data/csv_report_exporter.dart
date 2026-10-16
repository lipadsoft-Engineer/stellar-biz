import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart' show DateTimeRange, Rect;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'daily_profit_repository.dart';
import '../domain/profit_calculator.dart';

class CsvReportExporter {
  const CsvReportExporter();

  Future<void> share(
    List<DailyProfit> days, {
    required DateTimeRange range,
    Rect? sharePositionOrigin,
  }) async {
    if (days.isEmpty) return;
    final directory = await getTemporaryDirectory();
    final start = _fileDate(range.start);
    final end = _fileDate(range.end);
    final file = File(
      p.join(directory.path, 'profit_report_${start}_$end.csv'),
    );
    await file.writeAsString(_toCsv(days), encoding: utf8, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        title: 'Profit report',
        subject: 'Profit report $start to $end',
        files: [XFile(file.path, mimeType: 'text/csv')],
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  String _toCsv(List<DailyProfit> days) {
    final rows = <String>[
      'Date,Sales revenue (KES),Cost of goods (KES),Gross profit (KES),Operating expenses (KES),Net profit (KES)',
    ];
    for (final day in days) {
      final summary = day.summary;
      rows.add(
        [
          _csvText(_fileDate(day.date)),
          _moneyCell(summary.salesRevenueMinor),
          _moneyCell(summary.costOfGoodsSoldMinor),
          _moneyCell(summary.grossProfitMinor),
          _moneyCell(summary.operatingExpensesMinor),
          _moneyCell(summary.netProfitMinor),
        ].join(','),
      );
    }
    final total = _combine(days);
    rows.add(
      [
        'TOTAL',
        _moneyCell(total.salesRevenueMinor),
        _moneyCell(total.costOfGoodsSoldMinor),
        _moneyCell(total.grossProfitMinor),
        _moneyCell(total.operatingExpensesMinor),
        _moneyCell(total.netProfitMinor),
      ].join(','),
    );
    return '\uFEFF${rows.join('\r\n')}\r\n';
  }

  ProfitSummary _combine(List<DailyProfit> days) {
    var sales = 0;
    var costs = 0;
    var expenses = 0;
    for (final day in days) {
      sales += day.summary.salesRevenueMinor;
      costs += day.summary.costOfGoodsSoldMinor;
      expenses += day.summary.operatingExpensesMinor;
    }
    final gross = sales - costs;
    return ProfitSummary(
      salesRevenueMinor: sales,
      costOfGoodsSoldMinor: costs,
      grossProfitMinor: gross,
      operatingExpensesMinor: expenses,
      netProfitMinor: gross - expenses,
    );
  }

  String _moneyCell(int minor) {
    final absolute = minor.abs();
    final sign = minor < 0 ? '-' : '';
    return '$sign${absolute ~/ 100}.${(absolute % 100).toString().padLeft(2, '0')}';
  }

  String _csvText(String value) => '"${value.replaceAll('"', '""')}"';

  String _fileDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
