import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/database/db_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../models/customer_model.dart';
import '../services/ocr_service.dart';
import '../widgets/image_picker_tile.dart';

class AddCustomerPage extends StatefulWidget {
  const AddCustomerPage({super.key});

  @override
  State<AddCustomerPage> createState() =>
      _AddCustomerPageState();
}

class _AddCustomerPageState
    extends State<AddCustomerPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _aadharController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _vehicleNumberController =
  TextEditingController();
  final _vehicleModelController =
  TextEditingController();
  final _keyCuttingController =
  TextEditingController();

  String? _vehicleType;

  File? _aadharFront;
  File? _aadharBack;
  File? _customerPhoto;
  File? _rcPhoto;

  bool _isSaving = false;
  bool _isScanning = false;

  final ImagePicker _picker = ImagePicker();

  late final AnimationController _controller;

  final List<String> vehicleTypes = [
    'Bike',
    'Scooter',
    'Car',
    'Auto',
    'Van',
    'Truck',
    'Bus',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  Future<File?> _pickImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (file == null) return null;

    return File(file.path);
  }

  Future<void> _showImagePicker(
      Function(File) onSelected,
      ) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                    AppTheme.gold.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(18),
                  ),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.gold
                          .withValues(alpha: 0.14),
                      borderRadius:
                      BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: AppTheme.gold,
                    ),
                  ),
                  title: const Text('Take Photo'),
                  subtitle: const Text(
                    'Use device camera',
                  ),
                  onTap: () async {
                    Navigator.pop(context);

                    final file =
                    await _pickImage(ImageSource.camera);

                    if (file != null) onSelected(file);
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(18),
                  ),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.gold
                          .withValues(alpha: 0.14),
                      borderRadius:
                      BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: AppTheme.gold,
                    ),
                  ),
                  title: const Text('Choose from Gallery'),
                  subtitle: const Text(
                    'Select existing image',
                  ),
                  onTap: () async {
                    Navigator.pop(context);

                    final file =
                    await _pickImage(ImageSource.gallery);

                    if (file != null) onSelected(file);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _autoFillFront() async {
    if (_aadharFront == null) return;

    setState(() => _isScanning = true);

    final data =
    await OCRService.instance.processFront(_aadharFront!);

    if (data.name != null &&
        _nameController.text.trim().isEmpty) {
      _nameController.text = data.name!;
    }

    if (data.aadhaarNumber != null) {
      _aadharController.text = data.aadhaarNumber!;
    }

    setState(() => _isScanning = false);
  }

  Future<void> _autoFillBack() async {
    if (_aadharBack == null) return;

    setState(() => _isScanning = true);

    final data =
    await OCRService.instance.processBack(_aadharBack!);

    if (data.address != null &&
        _addressController.text.trim().isEmpty) {
      _addressController.text = data.address!;
    }

    if (data.pincode != null) {
      _pincodeController.text = data.pincode!;
    }

    setState(() => _isScanning = false);
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final customer = CustomerModel(
      customerName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      aadharNumber:
      _aadharController.text.trim().isEmpty
          ? null
          : _aadharController.text.trim(),
      pincode: _pincodeController.text.trim().isEmpty
          ? null
          : _pincodeController.text.trim(),
      vehicleType: _vehicleType,
      vehicleModelName:
      _vehicleModelController.text.trim().isEmpty
          ? null
          : _vehicleModelController.text.trim(),
      vehicleNumber:
      _vehicleNumberController.text.trim().isEmpty
          ? null
          : _vehicleNumberController.text.trim(),
      keyCuttingNumber:
      _keyCuttingController.text.trim().isEmpty
          ? null
          : _keyCuttingController.text.trim(),
      customerPhoto: _customerPhoto?.path,
      rcPhoto: _rcPhoto?.path,
      aadharFrontPhoto: _aadharFront?.path,
      aadharBackPhoto: _aadharBack?.path,
      createdAt: DateTime.now(),
    );

    await DBHelper.instance.insertCustomer(customer);

    setState(() => _isSaving = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Customer saved successfully'),
      ),
    );

    Navigator.pop(context, true);
  }

  Widget _sectionCard({
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
          color: AppTheme.gold.withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 24,
            offset: const Offset(0, 12),
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
                width: 42,
                height: 42,
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

  InputDecoration _decoration(
      String label,
      IconData icon,
      ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.gold.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon,
            color: AppTheme.gold, size: 22),
      ),
      filled: true,
      fillColor: AppTheme.surface2,
      labelStyle: const TextStyle(
        color: AppTheme.textSecondary,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(
          color: AppTheme.gold.withValues(alpha: 0.10),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(
          color: AppTheme.gold,
          width: 1.4,
        ),
      ),
      contentPadding:
      const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 16,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              stretch: true,
              leading: Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.arrow_back_ios_new_rounded),
                ),
              ),
              backgroundColor: AppTheme.background,
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [
                  StretchMode.zoomBackground,
                ],
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
                    child: Padding(
                      padding:
                      const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          const Text(
                            'New Customer',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Capture Aadhaar, vehicle details and customer records securely on this device.',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const Spacer(),
                          if (_isScanning)
                            Container(
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius:
                                BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppTheme.gold
                                      .withValues(alpha: 0.18),
                                ),
                              ),
                              child: Row(
                                children: const [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child:
                                    CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.gold,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Scanning Aadhaar...',
                                    style: TextStyle(
                                      color:
                                      AppTheme.goldLight,
                                      fontWeight:
                                      FontWeight.w600,
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
              ),
            ),

            SliverPadding(
              padding:
              const EdgeInsets.fromLTRB(18, 18, 18, 120),
              sliver: SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _controller,
                    curve: Curves.easeOut,
                  ),
                  child: Column(
                    children: [
                      _sectionCard(
                        title: 'Aadhaar Documents',
                        icon: Icons.badge_outlined,
                        child: Column(
                          children: [
                            ImagePickerTile(
                              title: 'Aadhaar Front',
                              file: _aadharFront,
                              onTap: () => _showImagePicker(
                                    (f) async {
                                  setState(() =>
                                  _aadharFront = f);
                                  await _autoFillFront();
                                },
                              ),
                              onOcr: _autoFillFront,
                            ),
                            const SizedBox(height: 18),
                            ImagePickerTile(
                              title: 'Aadhaar Back',
                              file: _aadharBack,
                              onTap: () => _showImagePicker(
                                    (f) async {
                                  setState(() =>
                                  _aadharBack = f);
                                  await _autoFillBack();
                                },
                              ),
                              onOcr: _autoFillBack,
                            ),
                          ],
                        ),
                      ),

                      _sectionCard(
                        title: 'Customer Details',
                        icon: Icons.person_outline_rounded,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: _decoration(
                                'Customer Name',
                                Icons.person_outline_rounded,
                              ),
                              validator: (v) =>
                              v == null ||
                                  v.trim().isEmpty
                                  ? 'Enter customer name'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller:
                              _phoneController,
                              keyboardType:
                              TextInputType.phone,
                              decoration: _decoration(
                                'Phone Number',
                                Icons.phone_rounded,
                              ),
                              validator: (v) {
                                if (v == null ||
                                    v.trim().isEmpty) {
                                  return 'Enter phone number';
                                }
                                if (v.trim().length !=
                                    10) {
                                  return 'Enter valid 10 digit number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller:
                              _aadharController,
                              keyboardType:
                              TextInputType.number,
                              decoration: _decoration(
                                'Aadhaar Number',
                                Icons.credit_card_rounded,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller:
                              _pincodeController,
                              keyboardType:
                              TextInputType.number,
                              decoration: _decoration(
                                'Pincode',
                                Icons.location_on_outlined,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller:
                              _addressController,
                              maxLines: 3,
                              decoration: _decoration(
                                'Address',
                                Icons.home_outlined,
                              ),
                            ),
                          ],
                        ),
                      ),

                      _sectionCard(
                        title: 'Vehicle Details',
                        icon:
                        Icons.directions_car_outlined,
                        child: Column(
                          children: [
                            DropdownButtonFormField<
                                String>(
                              value: _vehicleType,
                              dropdownColor:
                              AppTheme.surface,
                              decoration: _decoration(
                                'Vehicle Type',
                                Icons.category_outlined,
                              ),
                              items: vehicleTypes
                                  .map(
                                    (e) =>
                                    DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                              )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() =>
                                  _vehicleType = v),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller:
                              _vehicleModelController,
                              textCapitalization:
                              TextCapitalization.words,
                              decoration: _decoration(
                                'Vehicle Model Name',
                                Icons.model_training_rounded,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller:
                              _vehicleNumberController,
                              textCapitalization:
                              TextCapitalization
                                  .characters,
                              decoration: _decoration(
                                'Vehicle Registration Number',
                                Icons
                                    .confirmation_number_outlined,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller:
                              _keyCuttingController,
                              decoration: _decoration(
                                'Key Cutting Number',
                                Icons.key_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),

                      _sectionCard(
                        title: 'Photos (Optional)',
                        icon:
                        Icons.photo_camera_outlined,
                        child: Column(
                          children: [
                            ImagePickerTile(
                              title: 'Customer Photo',
                              file: _customerPhoto,
                              onTap: () =>
                                  _showImagePicker(
                                        (f) => setState(() =>
                                    _customerPhoto = f),
                                  ),
                            ),
                            const SizedBox(height: 18),
                            ImagePickerTile(
                              title: 'Vehicle RC Photo',
                              file: _rcPhoto,
                              onTap: () =>
                                  _showImagePicker(
                                        (f) => setState(
                                            () => _rcPhoto = f),
                                  ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient:
                          AppTheme.goldGradient,
                          borderRadius:
                          BorderRadius.circular(22),
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
                        child: ElevatedButton(
                          onPressed:
                          _isSaving ? null : _saveCustomer,
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
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(22),
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(
                                milliseconds: 250),
                            child: _isSaving
                                ? const SizedBox(
                              key: ValueKey('loading'),
                              width: 24,
                              height: 24,
                              child:
                              CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.black,
                              ),
                            )
                                : Row(
                              key: const ValueKey('save'),
                              mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                              children: const [
                                Icon(Icons.save_rounded),
                                SizedBox(width: 10),
                                Text(
                                  'Save Customer',
                                  style: TextStyle(
                                    fontWeight:
                                    FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
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
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _aadharController.dispose();
    _pincodeController.dispose();
    _vehicleNumberController.dispose();
    _vehicleModelController.dispose();
    _keyCuttingController.dispose();
    super.dispose();
  }
}