import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ImagePickerTile extends StatelessWidget {
  final String title;
  final File? file;
  final VoidCallback onTap;
  final VoidCallback? onOcr;

  const ImagePickerTile({
    super.key,
    required this.title,
    required this.file,
    required this.onTap,
    this.onOcr,
  });

  @override
  Widget build(BuildContext context) {
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
                  image: FileImage(file!),
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
}