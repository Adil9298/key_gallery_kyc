import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:key_gallery_kyc/features/customers/views/add_customer_page.dart';
import 'package:key_gallery_kyc/features/customers/views/customer_details_page.dart';
import 'package:key_gallery_kyc/features/customers/views/export_excel_page.dart';

import '../../../core/database/db_helper.dart';
import '../../../core/services/auth_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/views/login_page.dart';
import '../models/customer_model.dart';

enum FilterType {
  today,
  week,
  month,
  previousMonth,
  quarter,
  year,
  all,
}

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() =>
      _CustomerListPageState();
}

class _CustomerListPageState
    extends State<CustomerListPage> {
  final TextEditingController _searchController =
  TextEditingController();

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
          data = await DBHelper.instance
              .getPreviousMonthCustomers();
          break;
        case FilterType.quarter:
          data = await DBHelper.instance
              .getThisQuarterCustomers();
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
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Database error: $e')),
      );
    }
  }

  Widget _filterChip(FilterType type, String label) {
    final selected = selectedFilter == type;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        height: 46,
        decoration: BoxDecoration(
          gradient: selected ? AppTheme.goldGradient : null,
          color: selected ? null : AppTheme.surface2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : AppTheme.gold.withValues(alpha: 0.16),
          ),
          boxShadow: selected
              ? [
            BoxShadow(
              color: AppTheme.gold.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ]
              : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            setState(() => selectedFilter = type);
            await _loadCustomers();
          },
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                  selected ? Colors.black : AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          titlePadding: const EdgeInsets.fromLTRB(
              24, 24, 24, 12),
          contentPadding: const EdgeInsets.fromLTRB(
              24, 0, 24, 24),
          actionsPadding: const EdgeInsets.fromLTRB(
              16, 0, 16, 16),

          title: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.gold
                      .withValues(alpha: 0.12),
                  borderRadius:
                  BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppTheme.gold,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Logout',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          content: const Text(
            'Are you sure you want to logout from Key Gallery KYC?\n\nYou will need to answer the secret question again to unlock the app.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.shade600,
                    Colors.red.shade400,
                  ],
                ),
                borderRadius:
                BorderRadius.circular(14),
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context, true);
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    await AuthService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 520),
        reverseTransitionDuration:
        const Duration(milliseconds: 420),

        pageBuilder: (context, animation,
            secondaryAnimation) {
          return const LoginPage();
        },

        transitionsBuilder: (context, animation,
            secondaryAnimation, child) {
          // Fade animation
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          // Scale animation
          final scale = Tween<double>(
            begin: 0.92,
            end: 1.0,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
          );

          // Slight upward movement
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          );

          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: ScaleTransition(
                scale: scale,
                child: child,
              ),
            ),
          );
        },
      ),(route) => false,
    );
  }

  Widget _customerCard(CustomerModel customer, int index) {
    final photoPath = customer.customerPhoto;

    return Dismissible(
      key: ValueKey(customer.id),
      direction: DismissDirection.endToStart,

      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [
              Colors.red.shade700,
              Colors.red.shade400,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.delete_forever_rounded,
              color: Colors.white,
              size: 34,
            ),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),

      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.red),
                SizedBox(width: 10),
                Text(
                  'Delete Record',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
              ],
            ),
            content: Text(
              'Delete ${customer.customerName} permanently?',
              style: const TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },

      onDismissed: (_) async {
        if (customer.id != null) {
          await DBHelper.instance.deleteCustomer(customer.id!);
          await _loadCustomers();
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text(
              '${customer.customerName} deleted',
            ),
            action: SnackBarAction(
              label: 'Close',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      },
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 250 + index * 40),
        tween: Tween(begin: 0, end: 1),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: Opacity(opacity: value, child: child),
          );
        },
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () async {
            final result = await Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 520),
                reverseTransitionDuration:
                const Duration(milliseconds: 420),

                pageBuilder: (context, animation,
                    secondaryAnimation) {
                  return CustomerDetailPage(customer: customer);
                },

                transitionsBuilder: (context, animation,
                    secondaryAnimation, child) {
                  // Fade animation
                  final fade = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  );

                  // Scale animation
                  final scale = Tween<double>(
                    begin: 0.92,
                    end: 1.0,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                    ),
                  );

                  // Slight upward movement
                  final slide = Tween<Offset>(
                    begin: const Offset(0, 0.06),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  );

                  return FadeTransition(
                    opacity: fade,
                    child: SlideTransition(
                      position: slide,
                      child: ScaleTransition(
                        scale: scale,
                        child: child,
                      ),
                    ),
                  );
                },
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
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppTheme.gold.withValues(alpha: 0.14),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.30),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: 'customer_${customer.id}',
                    child: Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                          AppTheme.gold.withValues(alpha: 0.45),
                          width: 1.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                            AppTheme.gold.withValues(alpha: 0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        image: customer.hasCustomerPhoto &&
                            File(photoPath!).existsSync()
                            ? DecorationImage(
                          image: FileImage(File(photoPath)),
                          fit: BoxFit.cover,
                        )
                            : null,
                        gradient: !customer.hasCustomerPhoto
                            ? LinearGradient(
                          colors: [
                            AppTheme.gold
                                .withValues(alpha: 0.22),
                            AppTheme.surface2,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                            : null,
                      ),
                      child: !customer.hasCustomerPhoto
                          ? Center(
                        child: Text(
                          customer.initials,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.gold,
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                          ),
                        ),
                      )
                          : null,
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Row(
                          children: [
                            const Icon(
                              Icons.phone_rounded,
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

                        const SizedBox(height: 10),

                        if ((customer.vehicleNumber ?? '')
                            .isNotEmpty)
                          Container(
                            padding:
                            const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.gold
                                  .withValues(alpha: 0.10),
                              borderRadius:
                              BorderRadius.circular(14),
                              border: Border.all(
                                color: AppTheme.gold
                                    .withValues(alpha: 0.18),
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

                        if ((customer.keyCuttingNumber ?? '')
                            .isNotEmpty)
                          Padding(
                            padding:
                            const EdgeInsets.only(top: 10),
                            child: Container(
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                gradient:
                                LinearGradient(colors: [
                                  AppTheme.gold
                                      .withValues(alpha: 0.18),
                                  AppTheme.gold
                                      .withValues(alpha: 0.08),
                                ]),
                                borderRadius:
                                BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppTheme.gold
                                      .withValues(alpha: 0.28),
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

                        const SizedBox(height: 12),

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

                  const SizedBox(width: 10),

                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color:
                      AppTheme.gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.goldGradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color:
              AppTheme.gold.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 520),
                reverseTransitionDuration:
                const Duration(milliseconds: 420),

                pageBuilder: (context, animation,
                    secondaryAnimation) {
                  return const AddCustomerPage();
                },

                transitionsBuilder: (context, animation,
                    secondaryAnimation, child) {
                  // Fade animation
                  final fade = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  );

                  // Scale animation
                  final scale = Tween<double>(
                    begin: 0.92,
                    end: 1.0,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                    ),
                  );

                  // Slight upward movement
                  final slide = Tween<Offset>(
                    begin: const Offset(0, 0.06),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  );

                  return FadeTransition(
                    opacity: fade,
                    child: SlideTransition(
                      position: slide,
                      child: ScaleTransition(
                        scale: scale,
                        child: child,
                      ),
                    ),
                  );
                },
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
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),

      body: RefreshIndicator(
        color: AppTheme.gold,
        onRefresh: _loadCustomers,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 250,
              pinned: true,
              stretch: true,
              backgroundColor: AppTheme.background,
              actions: [
                IconButton(
                  tooltip: 'Export / Import',
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 520),
                        reverseTransitionDuration:
                        const Duration(milliseconds: 420),

                        pageBuilder: (context, animation,
                            secondaryAnimation) {
                          return const ExportExcelPage();
                        },

                        transitionsBuilder: (context, animation,
                            secondaryAnimation, child) {
                          // Fade animation
                          final fade = CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          );

                          // Scale animation
                          final scale = Tween<double>(
                            begin: 0.92,
                            end: 1.0,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutBack,
                            ),
                          );

                          // Slight upward movement
                          final slide = Tween<Offset>(
                            begin: const Offset(0, 0.06),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          );

                          return FadeTransition(
                            opacity: fade,
                            child: SlideTransition(
                              position: slide,
                              child: ScaleTransition(
                                scale: scale,
                                child: child,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.sync_alt_rounded,
                  ),
                ),
                IconButton(
                  tooltip: 'Logout',
                  onPressed: _confirmLogout,
                  icon: const Icon(Icons.logout_rounded),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [
                  StretchMode.zoomBackground,
                  StretchMode.blurBackground,
                ],
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.gold
                            .withValues(alpha: 0.16),
                        AppTheme.background,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding:
                      const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          const Text(
                            'Customer Register',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            DateFormat(
                              'EEEE, dd MMMM yyyy',
                            ).format(now),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Expanded(
                                child: _glassStatCard(
                                  'Today',
                                  '$todayCount',
                                  Icons.today_rounded,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _glassStatCard(
                                  'Records',
                                  '${customers.length}',
                                  Icons.people_alt_rounded,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverPersistentHeader(
              pinned: true,
              delegate: _FilterHeaderDelegate(
                minExtent: 154,
                maxExtent: 154,
                child: Container(
                  color: AppTheme.background,
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
                  child: Column(
                    children: [
                      Container(
                        height: 62,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.06),
                              Colors.white.withValues(alpha: 0.02),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: AppTheme.gold.withValues(alpha: 0.22),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.gold.withValues(alpha: 0.08),
                              blurRadius: 24,
                              spreadRadius: 1,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 22,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => _loadCustomers(),
                          cursorColor: AppTheme.gold,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search customers, vehicle or key number',
                            hintStyle: TextStyle(
                              color: AppTheme.textSecondary.withValues(alpha: 0.85),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),

                            // Premium leading icon
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 10, right: 6),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.gold.withValues(alpha: 0.28),
                                      AppTheme.gold.withValues(alpha: 0.10),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: AppTheme.gold.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.search_rounded,
                                  color: AppTheme.gold,
                                  size: 22,
                                ),
                              ),
                            ),
                            prefixIconConstraints:
                            const BoxConstraints(minWidth: 64),

                            // Animated clear button
                            suffixIcon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _searchController.text.isNotEmpty
                                  ? Padding(
                                padding:
                                const EdgeInsets.only(right: 8),
                                child: IconButton(
                                  key: const ValueKey('clear'),
                                  onPressed: () async {
                                    _searchController.clear();
                                    await _loadCustomers();
                                    setState(() {});
                                  },
                                  icon: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: AppTheme.gold
                                          .withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: AppTheme.gold,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              )
                                  : const SizedBox(
                                key: ValueKey('empty'),
                                width: 12,
                              ),
                            ),

                            filled: true,
                            fillColor: Colors.transparent,

                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),

                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 8,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        height: 48,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics:
                          const BouncingScrollPhysics(),
                          children: [
                            _filterChip(
                                FilterType.today, 'Today'),
                            _filterChip(
                                FilterType.week, 'Week'),
                            _filterChip(
                                FilterType.month, 'Month'),
                            _filterChip(FilterType.previousMonth,
                                'Prev Month'),
                            _filterChip(
                                FilterType.quarter, 'Quarter'),
                            _filterChip(
                                FilterType.year, 'Year'),
                            _filterChip(FilterType.all, 'All'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.gold,
                  ),
                ),
              )
            else if (customers.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'No customer records found',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    18, 10, 18, 120),
                sliver: SliverList.builder(
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    return _customerCard(
                        customers[index], index);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _glassStatCard(
      String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.gold.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:
              AppTheme.gold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon,
                color: AppTheme.gold, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterHeaderDelegate
    extends SliverPersistentHeaderDelegate {
  final double minExtent;
  final double maxExtent;
  final Widget child;

  _FilterHeaderDelegate({
    required this.minExtent,
    required this.maxExtent,
    required this.child,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset,
      bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(
      covariant _FilterHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}