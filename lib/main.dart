import 'package:flutter/material.dart';
import 'package:key_gallery_kyc/core/theme/app_theme.dart';
import 'package:key_gallery_kyc/features/customers/views/customer_list_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Key Gallery KYC',
      theme: AppTheme.darkGoldTheme,
      debugShowCheckedModeBanner: false,
      home: CustomerListPage(),
    );
  }
}
