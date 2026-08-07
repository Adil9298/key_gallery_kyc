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
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _aadharController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _keyCuttingController = TextEditingController();

  String? _vehicleType;

  File? _aadharFront;
  File? _aadharBack;
  File? _customerPhoto;
  File? _rcPhoto;

  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading:
                  const Icon(Icons.camera_alt, color: AppTheme.gold),
                  title: const Text('Camera'),
                  onTap: () async {
                    Navigator.pop(context);
                    final file =
                    await _pickImage(ImageSource.camera);
                    if (file != null) onSelected(file);
                  },
                ),
                ListTile(
                  leading:
                  const Icon(Icons.photo, color: AppTheme.gold),
                  title: const Text('Gallery'),
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

  /*Future<void> _processAadharFront() async {
    if (_aadharFront == null) return;

    final recognizer = TextRecognizer();
    final inputImage =
    InputImage.fromFile(_aadharFront!);

    final result =
    await recognizer.processImage(inputImage);

    final text = result.text;

    final aadhaarMatch = RegExp(
      r'\b\d{4}\s?\d{4}\s?\d{4}\b',
    ).firstMatch(text);

    if (aadhaarMatch != null) {
      _aadharController.text = aadhaarMatch.group(0)!;
    }

    final lines = text.split('\n');

    for (final line in lines) {
      final value = line.trim();

      if (value.length > 3 &&
          RegExp(r'^[A-Za-z ]+$').hasMatch(value)) {
        _nameController.text = value;
        break;
      }
    }

    recognizer.close();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Front OCR completed')),
      );
    }
  }

  Future<void> _processAadharBack() async {
    if (_aadharBack == null) return;

    final recognizer = TextRecognizer();
    final inputImage =
    InputImage.fromFile(_aadharBack!);

    final result =
    await recognizer.processImage(inputImage);

    final text = result.text;

    final pinMatch =
    RegExp(r'\b\d{6}\b').firstMatch(text);

    if (pinMatch != null) {
      _pincodeController.text = pinMatch.group(0)!;
    }

    if (_addressController.text.isEmpty) {
      _addressController.text = text;
    }

    recognizer.close();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Back OCR completed')),
      );
    }
  }*/

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final customer = CustomerModel(
      customerName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      aadharNumber: _aadharController.text.trim().isEmpty
          ? null
          : _aadharController.text.trim(),
      pincode: _pincodeController.text.trim().isEmpty
          ? null
          : _pincodeController.text.trim(),
      vehicleType: _vehicleType,
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
      const SnackBar(content: Text('Customer saved successfully')),
    );

    Navigator.pop(context, true);
  }

  Widget _imagePickerCard({
    required String title,
    required File? file,
    required VoidCallback onTap,
    VoidCallback? onOcr,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.gold.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (onOcr != null)
                TextButton.icon(
                  onPressed: onOcr,
                  icon: const Icon(Icons.document_scanner,
                      size: 18),
                  label: const Text('OCR'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Container(
              height: 170,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surface2,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppTheme.gold.withValues(alpha: 0.12),
                ),
                image: file != null
                    ? DecorationImage(
                  image: FileImage(file),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: file == null
                  ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined,
                      color: AppTheme.gold, size: 36),
                  SizedBox(height: 8),
                  Text(
                    'Tap to add image',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  bool _isScanning = false;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Customer'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ImagePickerTile(
                title: 'Aadhaar Front',
                file: _aadharFront,
                onTap: () => _showImagePicker(
                      (f) async {
                    setState(() => _aadharFront = f);

                    // Auto scan immediately
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
                    setState(() => _aadharBack = f);

                    // Auto scan immediately
                    await _autoFillBack();
                  },
                ),
                onOcr: _autoFillBack,
              ),
              const SizedBox(height: 26),

              const Text(
                'Customer Details',
                style: TextStyle(
                  color: AppTheme.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Customer Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                v == null || v.trim().isEmpty
                    ? 'Enter customer name'
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Enter phone number';
                  }
                  if (v.trim().length != 10) {
                    return 'Enter valid 10 digit number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _aadharController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Aadhaar Number',
                  prefixIcon: Icon(Icons.credit_card),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _pincodeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Pincode',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.home_outlined),
                ),
              ),
              const SizedBox(height: 26),

              const Text(
                'Vehicle Details',
                style: TextStyle(
                  color: AppTheme.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _vehicleType,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Type',
                  prefixIcon: Icon(Icons.directions_car_outlined),
                ),
                items: vehicleTypes
                    .map(
                      (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ),
                )
                    .toList(),
                onChanged: (v) => setState(() => _vehicleType = v),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _vehicleNumberController,
                textCapitalization:
                TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Registration Number',
                  prefixIcon: Icon(Icons.confirmation_number_outlined),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _keyCuttingController,
                decoration: const InputDecoration(
                  labelText: 'Key Cutting Number (Optional)',
                  prefixIcon: Icon(Icons.key_outlined),
                ),
              ),
              const SizedBox(height: 26),

              const Text(
                'Optional Photos',
                style: TextStyle(
                  color: AppTheme.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

              _imagePickerCard(
                title: 'Customer Photo',
                file: _customerPhoto,
                onTap: () => _showImagePicker(
                      (f) => setState(() => _customerPhoto = f),
                ),
              ),
              const SizedBox(height: 18),

              _imagePickerCard(
                title: 'Vehicle RC Photo',
                file: _rcPhoto,
                onTap: () => _showImagePicker(
                      (f) => setState(() => _rcPhoto = f),
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
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.black,
                    padding:
                    const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.black,
                    ),
                  )
                      : const Text(
                    'Save Customer',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _aadharController.dispose();
    _pincodeController.dispose();
    _vehicleNumberController.dispose();
    _keyCuttingController.dispose();
    super.dispose();
  }
}