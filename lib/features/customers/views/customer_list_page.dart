import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:key_gallery_kyc/features/customers/views/add_customer_page.dart';
import 'package:key_gallery_kyc/features/customers/views/customer_details_page.dart';
import 'package:key_gallery_kyc/features/customers/views/export_excel_page.dart';

import '../../../core/database/db_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../models/customer_model.dart';

enum FilterType { today, week, month, previousMonth, quarter, year, all }

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  final TextEditingController _searchController = TextEditingController();

  List<CustomerModel> customers = [];
  bool isLoading = true;

  FilterType selectedFilter = FilterType.today;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => isLoading = true);

    try {
      List<CustomerModel> data;

      switch (selectedFilter) {
        case FilterType.today:
          data = await DBHelper.instance.getTodayCustomers();
          break;
        case FilterType.week:
          data = await DBHelper.instance.getThisWeekCustomers();
          break;
        case FilterType.month:
          data = await DBHelper.instance.getThisMonthCustomers();
          break;
        case FilterType.previousMonth:
          data =
          await DBHelper.instance.getPreviousMonthCustomers();
          break;
        case FilterType.quarter:
          data =
          await DBHelper.instance.getThisQuarterCustomers();
          break;
        case FilterType.year:
          data = await DBHelper.instance.getThisYearCustomers();
          break;
        case FilterType.all:
          data = await DBHelper.instance.getAllCustomers();
          break;
      }

      if (_searchController.text.trim().isNotEmpty) {
        final query =
        _searchController.text.trim().toLowerCase();

        data = data.where((c) {
          return c.customerName
              .toLowerCase()
              .contains(query) ||
              c.phone.contains(query) ||
              (c.vehicleNumber ?? '')
                  .toLowerCase()
                  .contains(query) ||
              (c.keyCuttingNumber ?? '')
                  .toLowerCase()
                  .contains(query);
        }).toList();
      }

      if (!mounted) return;

      setState(() {
        customers = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Load customers error: $e');

      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Database error: $e')),
      );
    }
  }

  Future<void> _deleteCustomer(int id) async {
    await DBHelper.instance.deleteCustomer(id);
    await _loadCustomers();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Customer deleted')));
  }

  Widget _filterChip(FilterType type, String label) {
    final selected = selectedFilter == type;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: selected ? AppTheme.goldGradient : null,
          color: selected ? null : AppTheme.surface2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : AppTheme.gold.withValues(alpha: 0.18),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            setState(() => selectedFilter = type);
            await _loadCustomers();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.black : AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.gold.withValues(alpha: 0.16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.gold, size: 28),
            const SizedBox(height: 14),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _customerCard(CustomerModel customer, int index) {
    final photoPath = customer.customerPhoto;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 350 + (index * 40)),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Dismissible(
        key: ValueKey(customer.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          return await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete customer?'),
                  content: const Text(
                    'This record will be removed permanently.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ) ??
              false;
        },
        onDismissed: (_) => _deleteCustomer(customer.id!),
        background: Container(
          alignment: Alignment.centerRight,
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
          ),
          child: const Icon(
            Icons.delete_outline,
            color: Colors.redAccent,
            size: 30,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CustomerDetailPage(customer: customer),
              ),
            );

            if (result == true) {
              await _loadCustomers();
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.14)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: 'customer_${customer.id}',
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppTheme.gold.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                        image:
                            customer.hasCustomerPhoto &&
                                File(photoPath!).existsSync()
                            ? DecorationImage(
                                image: FileImage(File(photoPath)),
                                fit: BoxFit.cover,
                              )
                            : null,
                        gradient: !customer.hasCustomerPhoto
                            ? LinearGradient(
                                colors: [
                                  AppTheme.gold.withValues(alpha: 0.18),
                                  AppTheme.surface2,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                      ),
                      child: !customer.hasCustomerPhoto
                          ? Text(
                              customer.initials,
                              style: const TextStyle(
                                color: AppTheme.gold,
                                fontWeight: FontWeight.w700,
                                fontSize: 24,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 16,
                              color: AppTheme.goldLight,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              customer.phone,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if ((customer.vehicleNumber ?? '').isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.gold.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.gold.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.directions_car_rounded,
                                  size: 14,
                                  color: AppTheme.goldLight,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  customer.vehicleNumber!,
                                  style: const TextStyle(
                                    color: AppTheme.goldLight,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if ((customer.keyCuttingNumber ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.gold.withValues(alpha: 0.18),
                                    AppTheme.gold.withValues(alpha: 0.08),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.gold.withValues(alpha: 0.28),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.key_rounded,
                                    size: 14,
                                    color: AppTheme.gold,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Key No: ${customer.keyCuttingNumber}',
                                    style: const TextStyle(
                                      color: AppTheme.gold,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: AppTheme.goldLight,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat(
                                'dd MMM yyyy • hh:mm a',
                              ).format(customer.createdAt),
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      color: AppTheme.gold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final todayCount = customers.where((e) {
      return e.createdAt.year == now.year &&
          e.createdAt.month == now.month &&
          e.createdAt.day == now.day;
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Key Gallery KYC'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ExportExcelPage(),
                ),
              );
            },
            icon: const Icon(Icons.download_rounded),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.goldGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.gold.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddCustomerPage(),
              ),
            );

            if (result == true) {
              await _loadCustomers();
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add, color: Colors.black),
          label: const Text(
            'Add Customer',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.gold,
        onRefresh: _loadCustomers,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer Register',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy').format(now),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        _statCard('Today', '$todayCount', Icons.today_rounded),
                        const SizedBox(width: 14),
                        _statCard(
                          'Records',
                          '${customers.length}',
                          Icons.people_alt_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => _loadCustomers(),
                      decoration: InputDecoration(
                        hintText: 'Search name, phone or vehicle number',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () async {
                                  _searchController.clear();
                                  await _loadCustomers();
                                },
                                icon: const Icon(Icons.close_rounded),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 54,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _filterChip(FilterType.today, 'Today'),
                          _filterChip(FilterType.week, 'Week'),
                          _filterChip(FilterType.month, 'Month'),
                          _filterChip(FilterType.previousMonth, 'Prev Month'),
                          _filterChip(FilterType.quarter, 'Quarter'),
                          _filterChip(FilterType.year, 'Year'),
                          _filterChip(FilterType.all, 'All'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            if (isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (customers.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'No customer records found',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                sliver: SliverList.builder(
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    return _customerCard(customers[index], index);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
