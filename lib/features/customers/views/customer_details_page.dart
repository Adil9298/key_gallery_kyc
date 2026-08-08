import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/database/db_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../models/customer_model.dart';
import '../services/ocr_service.dart';

class CustomerDetailPage extends StatefulWidget {
  final CustomerModel customer;

  const CustomerDetailPage({
    super.key,
    required this.customer,
  });

  @override
  State<CustomerDetailPage> createState() =>
      _CustomerDetailPageState();
}

class _CustomerDetailPageState
    extends State<CustomerDetailPage>
    with SingleTickerProviderStateMixin {
  late CustomerModel customer;

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _aadharController;
  late final TextEditingController _pincodeController;
  late final TextEditingController _vehicleModelController;
  late final TextEditingController _vehicleNumberController;
  late final TextEditingController _keyCuttingController;

  String? _vehicleType;

  final ImagePicker _picker = ImagePicker();

  bool _isSaving = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    customer = widget.customer;

    _nameController =
        TextEditingController(text: customer.customerName);
    _phoneController =
        TextEditingController(text: customer.phone);
    _addressController =
        TextEditingController(text: customer.address ?? '');
    _aadharController =
        TextEditingController(text: customer.aadharNumber ?? '');
    _pincodeController =
        TextEditingController(text: customer.pincode ?? '');
    _vehicleModelController = TextEditingController(
        text: customer.vehicleModelName ?? '');
    _vehicleNumberController = TextEditingController(
        text: customer.vehicleNumber ?? '');
    _keyCuttingController = TextEditingController(
        text: customer.keyCuttingNumber ?? '');

    _vehicleType = customer.vehicleType;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  bool _isValidImage(String? path) {
    if (path == null || path.trim().isEmpty) return false;

    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }

  Future<void> _pickImage(String type) async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked == null) return;

    final path = picked.path;

    CustomerModel updated = customer;

    if (type == 'front') {
      final data =
      await OCRService.instance.processFront(File(path));

      _nameController.text =
          data.name ?? _nameController.text;

      _aadharController.text =
          data.aadhaarNumber ?? _aadharController.text;

      updated = customer.copyWith(
        aadharFrontPhoto: path,
        customerName: _nameController.text.trim(),
        aadharNumber: _aadharController.text.trim(),
      );
    } else if (type == 'back') {
      final data =
      await OCRService.instance.processBack(File(path));

      _addressController.text =
          data.address ?? _addressController.text;

      _pincodeController.text =
          data.pincode ?? _pincodeController.text;

      updated = customer.copyWith(
        aadharBackPhoto: path,
        address: _addressController.text.trim(),
        pincode: _pincodeController.text.trim(),
      );
    } else if (type == 'customer') {
      updated =
          customer.copyWith(customerPhoto: path);
    } else if (type == 'rc') {
      updated = customer.copyWith(rcPhoto: path);
    }

    await DBHelper.instance.updateCustomer(updated);

    if (!mounted) return;

    setState(() => customer = updated);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image updated successfully'),
      ),
    );
  }

  Future<void> _removeImage(String type) async {
    CustomerModel updated = customer;

    switch (type) {
      case 'customer':
        updated =
            customer.copyWith(customerPhoto: '');
        break;
      case 'rc':
        updated = customer.copyWith(rcPhoto: '');
        break;
      case 'front':
        updated = customer.copyWith(
            aadharFrontPhoto: '');
        break;
      case 'back':
        updated = customer.copyWith(
            aadharBackPhoto: '');
        break;
    }

    await DBHelper.instance.updateCustomer(updated);

    if (!mounted) return;

    setState(() => customer = updated);
  }

  Future<void> _showFullImage(String path) async {
    if (!_isValidImage(path)) return;

    await showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5,
              child: Image.file(File(path)),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveCustomer() async {
    setState(() => _isSaving = true);

    final updated = customer.copyWith(
      customerName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      aadharNumber: _aadharController.text.trim(),
      pincode: _pincodeController.text.trim(),
      vehicleType: _vehicleType,
      vehicleModelName:
      _vehicleModelController.text.trim(),
      vehicleNumber:
      _vehicleNumberController.text.trim(),
      keyCuttingNumber:
      _keyCuttingController.text.trim(),
    );

    await DBHelper.instance.updateCustomer(updated);

    if (!mounted) return;

    setState(() {
      customer = updated;
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Customer updated successfully'),
      ),
    );
  }

  InputDecoration _decoration(
      String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon:
      Icon(icon, color: AppTheme.gold),
      filled: true,
      fillColor: AppTheme.surface2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color:
          AppTheme.gold.withValues(alpha: 0.12),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: AppTheme.gold,
          width: 1.3,
        ),
      ),
    );
  }

  Widget _field(
      TextEditingController controller,
      String label,
      IconData icon, {
        int maxLines = 1,
        TextInputType? keyboardType,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(
          color: AppTheme.textPrimary,
        ),
        decoration: _decoration(label, icon),
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color:
          AppTheme.gold.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.25),
            blurRadius: 22,
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.gold
                          .withValues(alpha: 0.24),
                      AppTheme.gold
                          .withValues(alpha: 0.10),
                    ],
                  ),
                  borderRadius:
                  BorderRadius.circular(14),
                ),
                child: Icon(icon,
                    color: AppTheme.gold),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _imageSection(
      String title,
      String? path,
      String type,
      ) {
    final hasImage = _isValidImage(path);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
          AppTheme.gold.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        children: [
          if (hasImage)
            GestureDetector(
              onLongPress: () =>
                  _showFullImage(path),
              child: ClipRRect(
                borderRadius:
                const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: Image.file(
                  File(path!),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              height: 180,
              width: double.infinity,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.image_outlined,
                    size: 44,
                    color: AppTheme.textSecondary,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No image added',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                TextButton.icon(
                  onPressed: () =>
                      _pickImage(type),
                  icon: Icon(
                    hasImage
                        ? Icons.edit_rounded
                        : Icons.add_a_photo_rounded,
                    color: AppTheme.gold,
                  ),
                  label: Text(
                    hasImage ? 'Change' : 'Add',
                    style: const TextStyle(
                      color: AppTheme.gold,
                    ),
                  ),
                ),

                if (hasImage)
                  IconButton(
                    onPressed: () =>
                        _removeImage(type),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                    ),
                  ),
              ],
            ),
          ),

          if (hasImage)
            const Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 12,
              ),
              child: Text(
                'Long press image to view fullscreen',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _deleteCustomer() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
            ),
            SizedBox(width: 10),
            Text(
              'Delete Customer',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Delete ${customer.customerName} permanently?\n\nThis action cannot be undone.',
          style: const TextStyle(
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () =>
                Navigator.pop(context, true),
            icon: const Icon(Icons.delete_rounded),
            label: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (customer.id != null) {
      await DBHelper.instance.deleteCustomer(customer.id!);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade700,
        content: Text(
          '${customer.customerName} deleted successfully',
        ),
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics:
        const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor:
            AppTheme.background,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.arrow_back_ios_new_rounded),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8),
                  decoration: BoxDecoration(
                    color:
                    Colors.red.withValues(alpha: 0.12),
                    borderRadius:
                    BorderRadius.circular(16),
                    border: Border.all(
                      color:
                      Colors.red.withValues(alpha: 0.25),
                    ),
                  ),
                  child: IconButton(
                    tooltip: 'Delete Customer',
                    onPressed: _deleteCustomer,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.gold
                          .withValues(alpha: 0.18),
                      AppTheme.background,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.gold
                                .withValues(
                                alpha: 0.45),
                            width: 2,
                          ),
                          image: _isValidImage(
                              customer
                                  .customerPhoto)
                              ? DecorationImage(
                            image: FileImage(File(
                                customer
                                    .customerPhoto!)),
                            fit: BoxFit.cover,
                          )
                              : null,
                          gradient: !_isValidImage(
                              customer
                                  .customerPhoto)
                              ? LinearGradient(
                            colors: [
                              AppTheme.gold
                                  .withValues(
                                  alpha:
                                  0.22),
                              AppTheme.surface2,
                            ],
                          )
                              : null,
                        ),
                        child: !_isValidImage(
                            customer
                                .customerPhoto)
                            ? Center(
                          child: Text(
                            customer.initials,
                            style:
                            const TextStyle(
                              color:
                              AppTheme.gold,
                              fontSize: 34,
                              fontWeight:
                              FontWeight
                                  .w800,
                            ),
                          ),
                        )
                            : null,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        customer.customerName,
                        style: const TextStyle(
                          color:
                          AppTheme.textPrimary,
                          fontSize: 26,
                          fontWeight:
                          FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        customer.phone,
                        style: const TextStyle(
                          color:
                          AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                18, 20, 18, 120),
            sliver: SliverToBoxAdapter(
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _animationController,
                  curve: Curves.easeOut,
                ),
                child: Column(
                  children: [
                    _section(
                      title:
                      'Customer Information',
                      icon: Icons
                          .person_outline_rounded,
                      child: Column(
                        children: [
                          _field(
                            _nameController,
                            'Customer Name',
                            Icons.person_rounded,
                          ),
                          _field(
                            _phoneController,
                            'Phone Number',
                            Icons.phone_rounded,
                            keyboardType:
                            TextInputType.phone,
                          ),
                          _field(
                            _aadharController,
                            'Aadhaar Number',
                            Icons.badge_rounded,
                            keyboardType:
                            TextInputType.number,
                          ),
                          _field(
                            _pincodeController,
                            'Pincode',
                            Icons
                                .location_on_outlined,
                            keyboardType:
                            TextInputType.number,
                          ),
                          _field(
                            _addressController,
                            'Address',
                            Icons.home_outlined,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),

                    _section(
                      title:
                      'Vehicle Information',
                      icon: Icons
                          .directions_car_outlined,
                      child: Column(
                        children: [
                          DropdownButtonFormField<
                              String>(
                            initialValue: _vehicleType,
                            dropdownColor:
                            AppTheme.surface,
                            decoration:
                            _decoration(
                              'Vehicle Type',
                              Icons
                                  .category_outlined,
                            ),
                            items: const [
                              'Bike',
                              'Scooter',
                              'Car',
                              'Auto',
                              'Van',
                              'Truck',
                              'Bus',
                              'Other',
                            ]
                                .map(
                                  (e) =>
                                  DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                            )
                                .toList(),
                            onChanged: (v) {
                              setState(() =>
                              _vehicleType = v);
                            },
                          ),

                          const SizedBox(height: 16),

                          _field(
                            _vehicleModelController,
                            'Vehicle Model Name',
                            Icons
                                .model_training_rounded,
                          ),

                          _field(
                            _vehicleNumberController,
                            'Vehicle Number',
                            Icons
                                .confirmation_number_outlined,
                          ),

                          _field(
                            _keyCuttingController,
                            'Key Cutting Number',
                            Icons.key_rounded,
                          ),
                        ],
                      ),
                    ),

                    _section(
                      title:
                      'Documents & Photos',
                      icon: Icons
                          .photo_library_outlined,
                      child: Column(
                        children: [
                          _imageSection(
                            'Customer Photo',
                            customer.customerPhoto,
                            'customer',
                          ),
                          _imageSection(
                            'Vehicle RC Photo',
                            customer.rcPhoto,
                            'rc',
                          ),
                          _imageSection(
                            'Aadhaar Front',
                            customer.aadharFrontPhoto,
                            'front',
                          ),
                          _imageSection(
                            'Aadhaar Back',
                            customer.aadharBackPhoto,
                            'back',
                          ),
                        ],
                      ),
                    ),

                    _section(
                      title:
                      'Record Information',
                      icon:
                      Icons.event_note_rounded,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.calendar_today_rounded,
                          color: AppTheme.gold,
                        ),
                        title: const Text(
                          'Created On',
                          style: TextStyle(
                            color:
                            AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          DateFormat(
                            'dd MMM yyyy • hh:mm a',
                          ).format(customer.createdAt),
                          style: const TextStyle(
                            color:
                            AppTheme.textPrimary,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient:
                        AppTheme.goldGradient,
                        borderRadius:
                        BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.gold
                                .withValues(alpha: 0.35),
                            blurRadius: 26,
                            offset:
                            const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : _saveCustomer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          Colors.transparent,
                          shadowColor:
                          Colors.transparent,
                          foregroundColor:
                          Colors.black,
                          padding:
                          const EdgeInsets.symmetric(
                            vertical: 18,
                          ),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                                24),
                          ),
                        ),
                        icon: _isSaving
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.black,
                          ),
                        )
                            : const Icon(
                            Icons.save_rounded),
                        label: Text(
                          _isSaving
                              ? 'Saving...'
                              : 'Save Changes',
                          style: const TextStyle(
                            fontWeight:
                            FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();

    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _aadharController.dispose();
    _pincodeController.dispose();
    _vehicleModelController.dispose();
    _vehicleNumberController.dispose();
    _keyCuttingController.dispose();

    super.dispose();
  }
}