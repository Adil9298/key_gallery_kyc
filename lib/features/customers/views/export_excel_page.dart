import 'dart:io';

import 'package:excel/excel.dart' as ex;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/database/db_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../models/customer_model.dart';

enum ExportFilterType {
  today,
  week,
  month,
  previousMonth,
  quarter,
  year,
  all,
}

class ExportExcelPage extends StatefulWidget {
  const ExportExcelPage({super.key});

  @override
  State<ExportExcelPage> createState() =>
      _ExportExcelPageState();
}

class _ExportExcelPageState
    extends State<ExportExcelPage> {
  ExportFilterType selectedFilter =
      ExportFilterType.month;

  bool isLoading = false;
  int recordCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<List<CustomerModel>> _getData() async {
    switch (selectedFilter) {
      case ExportFilterType.today:
        return DBHelper.instance.getTodayCustomers();

      case ExportFilterType.week:
        return DBHelper.instance.getThisWeekCustomers();

      case ExportFilterType.month:
        return DBHelper.instance.getThisMonthCustomers();

      case ExportFilterType.previousMonth:
        return DBHelper.instance
            .getPreviousMonthCustomers();

      case ExportFilterType.quarter:
        return DBHelper.instance.getThisQuarterCustomers();

      case ExportFilterType.year:
        return DBHelper.instance.getThisYearCustomers();

      case ExportFilterType.all:
        return DBHelper.instance.getAllCustomers();
    }
  }

  Future<void> _loadCount() async {
    final data = await _getData();

    if (!mounted) return;

    setState(() {
      recordCount = data.length;
    });
  }

  String _filterName() {
    switch (selectedFilter) {
      case ExportFilterType.today:
        return 'Today';

      case ExportFilterType.week:
        return 'ThisWeek';

      case ExportFilterType.month:
        return 'ThisMonth';

      case ExportFilterType.previousMonth:
        return 'PreviousMonth';

      case ExportFilterType.quarter:
        return 'ThisQuarter';

      case ExportFilterType.year:
        return 'ThisYear';

      case ExportFilterType.all:
        return 'All';
    }
  }

  Future<void> _exportExcel() async {
    setState(() => isLoading = true);

    try {
      final customers = await _getData();

      final excel = ex.Excel.createExcel();

      final ex.Sheet sheet = excel['Customers'];

      // Header row
      sheet.appendRow([
        ex.TextCellValue('ID'),
        ex.TextCellValue('Customer Name'),
        ex.TextCellValue('Phone'),
        ex.TextCellValue('Address'),
        ex.TextCellValue('Aadhaar Number'),
        ex.TextCellValue('Pincode'),
        ex.TextCellValue('Vehicle Type'),
        ex.TextCellValue('Vehicle Number'),
        ex.TextCellValue('Key Cutting Number'),
        ex.TextCellValue('Created At'),
      ]);

      // Data rows
      for (final c in customers) {
        sheet.appendRow([
          ex.IntCellValue(c.id ?? 0),
          ex.TextCellValue(c.customerName),
          ex.TextCellValue(c.phone),
          ex.TextCellValue(c.address ?? ''),
          ex.TextCellValue(c.aadharNumber ?? ''),
          ex.TextCellValue(c.pincode ?? ''),
          ex.TextCellValue(c.vehicleType ?? ''),
          ex.TextCellValue(c.vehicleNumber ?? ''),
          ex.TextCellValue(c.keyCuttingNumber ?? ''),
          ex.TextCellValue(c.createdAt.toIso8601String()),
        ]);
      }

      final bytes = excel.encode();

      if (bytes == null) {
        throw Exception('Failed to generate Excel');
      }

      // Save directly to Android Downloads folder
      final downloadPath =
          '/storage/emulated/0/Download';

      final fileName =
          'customers_${_filterName()}_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      final filePath = '$downloadPath/$fileName';

      final file = File(filePath);

      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Text(
                'Excel exported successfully',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(file.path),
            ],
          ),
        ),
      );

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Export Successful'),
          content: SelectableText(
            'File saved to:\n\n$filePath',
            style: const TextStyle(
              color: AppTheme.textPrimary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
        ),
      );
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Widget _filterChip(
      String label,
      ExportFilterType value,
      ) {
    final selected = selectedFilter == value;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor:
      AppTheme.gold.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: selected
            ? AppTheme.gold
            : AppTheme.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: AppTheme.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected
              ? AppTheme.gold
              : AppTheme.gold.withValues(alpha: 0.15),
        ),
      ),
      onSelected: (_) {
        setState(() => selectedFilter = value);
        _loadCount();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export to Excel'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.gold.withValues(alpha: 0.16),
                    AppTheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppTheme.gold.withValues(alpha: 0.22),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.gold
                          .withValues(alpha: 0.18),
                    ),
                    child: const Icon(
                      Icons.table_view_rounded,
                      color: AppTheme.gold,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Export Customer Records',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Generate an Excel file of customer KYC records stored on this device.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            const Text(
              'Choose Filter',
              style: TextStyle(
                color: AppTheme.gold,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 14),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _filterChip('Today', ExportFilterType.today),
                _filterChip('Week', ExportFilterType.week),
                _filterChip('Month', ExportFilterType.month),
                _filterChip(
                  'Prev Month',
                  ExportFilterType.previousMonth,
                ),
                _filterChip(
                  'Quarter',
                  ExportFilterType.quarter,
                ),
                _filterChip('Year', ExportFilterType.year),
                _filterChip('All', ExportFilterType.all),
              ],
            ),

            const SizedBox(height: 26),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppTheme.gold.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Records Selected',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$recordCount',
                    style: const TextStyle(
                      color: AppTheme.gold,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Filter: ${_filterName()}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppTheme.gold.withValues(alpha: 0.15),
                ),
              ),
              child: const Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    'Included Fields',
                    style: TextStyle(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '• ID\n'
                        '• Customer Name\n'
                        '• Phone Number\n'
                        '• Address\n'
                        '• Aadhaar Number\n'
                        '• Pincode\n'
                        '• Vehicle Type\n'
                        '• Vehicle Number\n'
                        '• Key Cutting Number\n'
                        '• Created Date & Time',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color:
                    AppTheme.gold.withValues(alpha: 0.35),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed:
                isLoading ? null : _exportExcel,
                icon: isLoading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.black,
                  ),
                )
                    : const Icon(
                  Icons.download_rounded,
                  color: Colors.black,
                ),
                label: Text(
                  isLoading
                      ? 'Exporting...'
                      : 'Export Excel',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}