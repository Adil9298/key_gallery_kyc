import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/database/db_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../models/customer_model.dart';
import '../services/ocr_service.dart';
import '../widgets/image_picker_tile.dart';

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
    extends State<CustomerDetailPage> {
  late CustomerModel customer;

  bool isEditing = false;
  bool isSaving = false;
  bool _isScanning = false;

  final ImagePicker _picker = ImagePicker();

  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController addressController;
  late TextEditingController aadharController;
  late TextEditingController pincodeController;
  late TextEditingController vehicleTypeController;
  late TextEditingController vehicleNumberController;
  late TextEditingController keyCuttingController;

  @override
  void initState() {
    super.initState();

    customer = widget.customer;

    nameController =
        TextEditingController(text: customer.customerName);
    phoneController =
        TextEditingController(text: customer.phone);
    addressController =
        TextEditingController(text: customer.address);
    aadharController =
        TextEditingController(text: customer.aadharNumber);
    pincodeController =
        TextEditingController(text: customer.pincode);
    vehicleTypeController =
        TextEditingController(text: customer.vehicleType);
    vehicleNumberController =
        TextEditingController(text: customer.vehicleNumber);
    keyCuttingController = TextEditingController(
      text: customer.keyCuttingNumber,
    );
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
        BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: AppTheme.gold,
                  ),
                  title: const Text('Camera'),
                  onTap: () async {
                    Navigator.pop(context);

                    final file =
                    await _pickImage(ImageSource.camera);

                    if (file != null) onSelected(file);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo,
                    color: AppTheme.gold,
                  ),
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

  Future<void> _rescanFront(String path) async {
    setState(() => _isScanning = true);

    final data =
    await OCRService.instance.processFront(File(path));

    if (data.name != null &&
        data.name!.isNotEmpty) {
      nameController.text = data.name!;
    }

    if (data.aadhaarNumber != null &&
        data.aadhaarNumber!.isNotEmpty) {
      aadharController.text = data.aadhaarNumber!;
    }

    setState(() => _isScanning = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Front OCR updated'),
      ),
    );
  }

  Future<void> _rescanBack(String path) async {
    setState(() => _isScanning = true);

    final data =
    await OCRService.instance.processBack(File(path));

    if (data.address != null &&
        data.address!.isNotEmpty) {
      addressController.text = data.address!;
    }

    if (data.pincode != null &&
        data.pincode!.isNotEmpty) {
      pincodeController.text = data.pincode!;
    }

    setState(() => _isScanning = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Back OCR updated'),
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() => isSaving = true);

    final updated = customer.copyWith(
      customerName: nameController.text.trim(),
      phone: phoneController.text.trim(),
      address: addressController.text.trim(),
      aadharNumber: aadharController.text.trim(),
      pincode: pincodeController.text.trim(),
      vehicleType: vehicleTypeController.text.trim(),
      vehicleNumber: vehicleNumberController.text.trim(),
      keyCuttingNumber:
      keyCuttingController.text.trim(),
      customerPhoto: customer.customerPhoto,
      rcPhoto: customer.rcPhoto,
      aadharFrontPhoto: customer.aadharFrontPhoto,
      aadharBackPhoto: customer.aadharBackPhoto,
    );

    await DBHelper.instance.updateCustomer(updated);

    customer = updated;

    setState(() {
      isEditing = false;
      isSaving = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Customer updated successfully'),
      ),
    );
  }

  Future<void> _deleteCustomer() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Customer'),
        content: const Text(
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await DBHelper.instance.deleteCustomer(customer.id!);

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  void _openImage(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenImagePage(path: path),
      ),
    );
  }

  Widget _infoField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        enabled: isEditing,
        maxLines: maxLines,
        style: const TextStyle(
          color: AppTheme.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: isEditing
              ? AppTheme.surface2
              : AppTheme.surface,
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: AppTheme.gold.withValues(alpha: 0.12),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: AppTheme.gold.withValues(alpha: 0.22),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: AppTheme.gold,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _replaceButton({
    required String label,
    required Function(File) onSelected,
  }) {
    if (!isEditing) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.edit),
        label: Text(label),
        onPressed: () => _showImagePicker(onSelected),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Details'),
        actions: [
          IconButton(
            icon: Icon(
              isEditing ? Icons.close : Icons.edit_outlined,
            ),
            onPressed: () {
              setState(() {
                isEditing = !isEditing;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteCustomer,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isScanning)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(
                  color: AppTheme.gold,
                ),
              ),

            // Header
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
                  CircleAvatar(
                    radius: 42,
                    backgroundColor:
                    AppTheme.gold.withValues(alpha: 0.18),
                    child: Text(
                      customer.initials,
                      style: const TextStyle(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    customer.customerName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    customer.phone,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            const Text(
              'Personal Information',
              style: TextStyle(
                color: AppTheme.gold,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),

            _infoField(
              label: 'Customer Name',
              controller: nameController,
            ),
            _infoField(
              label: 'Phone Number',
              controller: phoneController,
            ),
            _infoField(
              label: 'Aadhaar Number',
              controller: aadharController,
            ),
            _infoField(
              label: 'Pincode',
              controller: pincodeController,
            ),
            _infoField(
              label: 'Address',
              controller: addressController,
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            const Text(
              'Vehicle Information',
              style: TextStyle(
                color: AppTheme.gold,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),

            _infoField(
              label: 'Vehicle Type',
              controller: vehicleTypeController,
            ),
            _infoField(
              label: 'Vehicle Number',
              controller: vehicleNumberController,
            ),
            _infoField(
              label: 'Key Cutting Number',
              controller: keyCuttingController,
            ),

            const SizedBox(height: 24),

            const Text(
              'Documents & Photos',
              style: TextStyle(
                color: AppTheme.gold,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),

            // Customer Photo
            ImagePickerTile(
              title: 'Customer Photo',
              file: customer.customerPhoto != null
                  ? File(customer.customerPhoto!)
                  : null,
              onTap: () {
                if (customer.customerPhoto != null) {
                  _openImage(customer.customerPhoto!);
                }
              },
            ),
            _replaceButton(
              label: 'Replace Customer Photo',
              onSelected: (file) {
                setState(() {
                  customer = customer.copyWith(
                    customerPhoto: file.path,
                  );
                });
              },
            ),

            // RC Photo
            ImagePickerTile(
              title: 'Vehicle RC',
              file: customer.rcPhoto != null
                  ? File(customer.rcPhoto!)
                  : null,
              onTap: () {
                if (customer.rcPhoto != null) {
                  _openImage(customer.rcPhoto!);
                }
              },
            ),
            _replaceButton(
              label: 'Replace RC Photo',
              onSelected: (file) {
                setState(() {
                  customer = customer.copyWith(
                    rcPhoto: file.path,
                  );
                });
              },
            ),

            // Aadhaar Front
            ImagePickerTile(
              title: 'Aadhaar Front',
              file: customer.aadharFrontPhoto != null
                  ? File(customer.aadharFrontPhoto!)
                  : null,
              onTap: () {
                if (customer.aadharFrontPhoto != null) {
                  _openImage(customer.aadharFrontPhoto!);
                }
              },
              onOcr: customer.aadharFrontPhoto == null
                  ? null
                  : () => _rescanFront(
                customer.aadharFrontPhoto!,
              ),
            ),
            _replaceButton(
              label: 'Replace Front Image',
              onSelected: (file) async {
                setState(() {
                  customer = customer.copyWith(
                    aadharFrontPhoto: file.path,
                  );
                });

                await _rescanFront(file.path);
              },
            ),

            // Aadhaar Back
            ImagePickerTile(
              title: 'Aadhaar Back',
              file: customer.aadharBackPhoto != null
                  ? File(customer.aadharBackPhoto!)
                  : null,
              onTap: () {
                if (customer.aadharBackPhoto != null) {
                  _openImage(customer.aadharBackPhoto!);
                }
              },
              onOcr: customer.aadharBackPhoto == null
                  ? null
                  : () => _rescanBack(
                customer.aadharBackPhoto!,
              ),
            ),
            _replaceButton(
              label: 'Replace Back Image',
              onSelected: (file) async {
                setState(() {
                  customer = customer.copyWith(
                    aadharBackPhoto: file.path,
                  );
                });

                await _rescanBack(file.path);
              },
            ),

            const SizedBox(height: 32),

            if (isEditing)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ElevatedButton(
                  onPressed:
                  isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.black,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.black,
                    ),
                  )
                      : const Text(
                    'Save Changes',
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
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    aadharController.dispose();
    pincodeController.dispose();
    vehicleTypeController.dispose();
    vehicleNumberController.dispose();
    keyCuttingController.dispose();
    super.dispose();
  }
}

class _FullScreenImagePage extends StatelessWidget {
  final String path;

  const _FullScreenImagePage({
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Stack(
          children: [
            Center(
              child: Hero(
                tag: path,
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Image.file(
                    File(path),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 12,
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () =>
                    Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}