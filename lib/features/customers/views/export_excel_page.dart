import 'dart:io';

import 'package:excel/excel.dart' as ex;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/database/db_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../models/customer_model.dart';

enum ExportFilter {
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
    extends State<ExportExcelPage>
    with SingleTickerProviderStateMixin {
  ExportFilter selectedFilter = ExportFilter.month;

  int totalRecords = 0;
  int importedCount = 0;

  bool isExporting = false;
  bool isImporting = false;

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _loadCount();
  }

  Future<void> _loadCount() async {
    totalRecords =
    await DBHelper.instance.getCustomerCount();

    if (mounted) setState(() {});
  }

  String _filterLabel(ExportFilter filter) {
    switch (filter) {
      case ExportFilter.today:
        return 'Today';
      case ExportFilter.week:
        return 'Week';
      case ExportFilter.month:
        return 'Month';
      case ExportFilter.previousMonth:
        return 'Previous Month';
      case ExportFilter.quarter:
        return 'Quarter';
      case ExportFilter.year:
        return 'Year';
      case ExportFilter.all:
        return 'All';
    }
  }

  Future<List<CustomerModel>>
  _getFilteredCustomers() async {
    switch (selectedFilter) {
      case ExportFilter.today:
        return DBHelper.instance.getTodayCustomers();

      case ExportFilter.week:
        return DBHelper.instance.getThisWeekCustomers();

      case ExportFilter.month:
        return DBHelper.instance.getThisMonthCustomers();

      case ExportFilter.previousMonth:
        return DBHelper.instance
            .getPreviousMonthCustomers();

      case ExportFilter.quarter:
        return DBHelper.instance
            .getThisQuarterCustomers();

      case ExportFilter.year:
        return DBHelper.instance.getThisYearCustomers();

      case ExportFilter.all:
        return DBHelper.instance.getAllCustomers();
    }
  }

  Future<void> _exportExcel() async {
    setState(() => isExporting = true);

    try {
      final customers =
      await _getFilteredCustomers();

      if (customers.isEmpty) {
        throw Exception(
            'No records found for selected filter');
      }

      final excel = ex.Excel.createExcel();

      final sheet = excel['Customers'];

      // Header row
      sheet.appendRow([
        ex.TextCellValue('ID'),
        ex.TextCellValue('Customer Name'),
        ex.TextCellValue('Phone'),
        ex.TextCellValue('Address'),
        ex.TextCellValue('Aadhaar Number'),
        ex.TextCellValue('Pincode'),
        ex.TextCellValue('Vehicle Type'),
        ex.TextCellValue('Vehicle Model Name'),
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
          ex.TextCellValue(c.vehicleModelName ?? ''),
          ex.TextCellValue(c.vehicleNumber ?? ''),
          ex.TextCellValue(c.keyCuttingNumber ?? ''),
          ex.TextCellValue(
            c.createdAt.toIso8601String(),
          ),
        ]);
      }

      final bytes = excel.encode();

      if (bytes == null) {
        throw Exception('Failed to generate Excel');
      }

      // Android Downloads folder
      final downloadDir = Directory('/storage/emulated/0/Download');

      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final fileName =
          'customers_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      final file = File('${downloadDir.path}/$fileName');

      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          content: Text(
            'Excel saved to Downloads\n${file.path}',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('Export failed: $e'),
        ),
      );
    }

    if (mounted) {
      setState(() => isExporting = false);
    }
  }

  Future<void> _importExcel() async {
    setState(() => isImporting = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null || result.files.single.path == null) {
        setState(() => isImporting = false);
        return;
      }

      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();

      final excel = ex.Excel.decodeBytes(bytes);

      final sheet = excel.tables['Customers'];

      if (sheet == null) {
        throw Exception('Sheet "Customers" not found');
      }

      if (sheet.rows.isEmpty) {
        throw Exception('Excel sheet is empty');
      }

      // Read header row
      final headerRow = sheet.rows.first;

      final Map<String, int> headerMap = {};

      for (int i = 0; i < headerRow.length; i++) {
        final header = headerRow[i]?.value
            ?.toString()
            .trim() ??
            '';

        if (header.isNotEmpty) {
          headerMap[header] = i;
        }
      }

      String getValue(List<ex.Data?> row, String header) {
        final index = headerMap[header];

        if (index == null || index >= row.length) {
          return '';
        }

        final cell = row[index];

        if (cell == null) return '';

        return cell.value?.toString().trim() ?? '';
      }

      int success = 0;

      // Start from second row
      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];

        final customerName =
        getValue(row, 'Customer Name');

        final phone = getValue(row, 'Phone');

        if (customerName.isEmpty || phone.isEmpty) {
          continue;
        }

        final customer = CustomerModel(
          customerName: customerName,
          phone: phone,
          address: getValue(row, 'Address'),
          aadharNumber:
          getValue(row, 'Aadhaar Number'),
          pincode: getValue(row, 'Pincode'),
          vehicleType:
          getValue(row, 'Vehicle Type'),
          vehicleModelName:
          getValue(row, 'Vehicle Model Name'),
          vehicleNumber:
          getValue(row, 'Vehicle Number'),
          keyCuttingNumber:
          getValue(row, 'Key Cutting Number'),
          customerPhoto: null,
          rcPhoto: null,
          aadharFrontPhoto: null,
          aadharBackPhoto: null,
          createdAt: DateTime.tryParse(
            getValue(row, 'Created At'),
          ) ??
              DateTime.now(),
        );

        await DBHelper.instance.insertCustomer(customer);

        success++;
      }

      importedCount = success;

      await _loadCount();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          content: Text(
            '$success records imported successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('Import failed: $e'),
        ),
      );
    }

    if (mounted) {
      setState(() => isImporting = false);
    }
  }

  Widget _statCard(
      String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
          AppTheme.gold.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppTheme.gold
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child:
            Icon(icon, color: AppTheme.gold),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(ExportFilter filter) {
    final selected = selectedFilter == filter;

    return AnimatedContainer(
      duration:
      const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(
          right: 10, bottom: 10),
      child: ChoiceChip(
        label: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 2),
          child: Text(
            _filterLabel(filter),
            style: TextStyle(
              color: selected
                  ? Colors.black
                  : AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        selected: selected,
        selectedColor: AppTheme.gold,
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected
                ? AppTheme.gold
                : AppTheme.gold
                .withValues(alpha: 0.12),
          ),
        ),
        onSelected: (_) {
          setState(() => selectedFilter = filter);
        },
      ),
    );
  }

  Widget _actionCard({
    required String title,
    required String description,
    required IconData icon,
    required String buttonLabel,
    required bool loading,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.gold.withValues(alpha: 0.10),
            AppTheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color:
          AppTheme.gold.withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.24),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.gold
                      .withValues(alpha: 0.14),
                  borderRadius:
                  BorderRadius.circular(16),
                ),
                child: Icon(icon,
                    color: AppTheme.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.gold,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: loading ? null : onPressed,
              icon: loading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.black,
                ),
              )
                  : Icon(icon),
              label: Text(
                loading
                    ? 'Please wait...'
                    : buttonLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gold,
                foregroundColor: Colors.black,
                padding:
                const EdgeInsets.symmetric(
                  vertical: 16,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back_ios_new_rounded),
          ),
        ),
        title: const Text(
          'Data Management',
          style: TextStyle(
            color: AppTheme.gold,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.background,
              Color(0xFF111111),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOut,
          ),
          child: SingleChildScrollView(
            physics:
            const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
                18, 12, 18, 28),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.gold
                            .withValues(alpha: 0.16),
                        AppTheme.surface,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                    BorderRadius.circular(30),
                    border: Border.all(
                      color: AppTheme.gold
                          .withValues(alpha: 0.16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Local Data Center',
                        style: TextStyle(
                          color: AppTheme.gold,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Export customer records to Excel and import the same exported Excel back into local storage. Everything works completely offline.',
                        style: TextStyle(
                          color:
                          AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics:
                  const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.12,
                  children: [
                    _statCard(
                      'Total Records',
                      '$totalRecords',
                      Icons.people_alt_rounded,
                    ),
                    _statCard(
                      'Last Imported',
                      '$importedCount',
                      Icons.download_done_rounded,
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                const Text(
                  'Filter Records',
                  style: TextStyle(
                    color: AppTheme.gold,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 14),

                Wrap(
                  children: ExportFilter.values
                      .map(_filterChip)
                      .toList(),
                ),

                const SizedBox(height: 28),

                _actionCard(
                  title: 'Import Excel',
                  description:
                  'Select the same Excel (.xlsx) file exported by this app. All rows will be added to local SQLite storage.',
                  icon: Icons.file_upload_rounded,
                  buttonLabel:
                  'Import Exported Excel File',
                  loading: isImporting,
                  onPressed: _importExcel,
                ),

                const SizedBox(height: 22),

                _actionCard(
                  title: 'Export Excel',
                  description:
                  'Generate an Excel file for the selected filter and save it locally on the device.',
                  icon: Icons.file_download_rounded,
                  buttonLabel:
                  'Export Filtered Records',
                  loading: isExporting,
                  onPressed: _exportExcel,
                ),

                const SizedBox(height: 22),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius:
                    BorderRadius.circular(22),
                    border: Border.all(
                      color: AppTheme.gold
                          .withValues(alpha: 0.10),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.info_outline_rounded,
                          color: AppTheme.gold),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Import expects the same Excel structure generated by this app, including Vehicle Model Name and Key Cutting Number columns.',
                          style: TextStyle(
                            color:
                            AppTheme.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}