import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/aadhar_data.dart';


class OCRService {
  OCRService._();

  static final OCRService instance = OCRService._();

  final TextRecognizer _recognizer = TextRecognizer();

  // FRONT SIDE

  Future<AadhaarData> processFront(File file) async {
    final inputImage = InputImage.fromFile(file);

    final RecognizedText result =
    await _recognizer.processImage(inputImage);

    String? aadhaar;
    String? name;

    // Aadhaar number
    final aadhaarRegex =
    RegExp(r'\b\d{4}\s?\d{4}\s?\d{4}\b');

    final aadhaarMatch =
    aadhaarRegex.firstMatch(result.text);

    if (aadhaarMatch != null) {
      aadhaar = aadhaarMatch.group(0);
    }

    final lines = result.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final candidates = <String>[];

    for (final line in lines) {
      final lower = line.toLowerCase();

      // Ignore common Aadhaar texts
      if (lower.contains('government') ||
          lower.contains('india') ||
          lower.contains('aadhaar') ||
          lower.contains('dob') ||
          lower.contains('year of birth') ||
          lower.contains('male') ||
          lower.contains('female') ||
          lower.contains('govt') ||
          lower.contains('address') ||
          lower.contains('uidai') ||
          lower.contains('issue date')) {
        continue;
      }

      // Ignore lines with digits
      if (RegExp(r'\d').hasMatch(line)) {
        continue;
      }

      // Allow English letters, spaces and dots
      if (RegExp(r'^[A-Za-z .]+$').hasMatch(line)) {
        final cleaned = line
            .replaceAll(RegExp(r'\s+'), ' ')
            .replaceAll(RegExp(r'\.+'), '.')
            .trim();

        if (cleaned.length >= 3) {
          candidates.add(cleaned);
        }
      }
    }

    if (candidates.isNotEmpty) {
      // Choose longest reasonable candidate
      candidates.sort(
            (a, b) => b.length.compareTo(a.length),
      );

      name = candidates.first;
    }

    debugPrint('OCR TEXT:\\n${result.text}');
    debugPrint('NAME CANDIDATES: $candidates');
    debugPrint('FINAL NAME: $name');

    return AadhaarData(
      name: name,
      aadhaarNumber: aadhaar,
    );
  }

  // BACK SIDE

  Future<AadhaarData> processBack(File file) async {
    final inputImage = InputImage.fromFile(file);

    final RecognizedText result =
    await _recognizer.processImage(inputImage);

    final text = result.text;

    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    String? pincode;
    String? address;

    final pinRegex = RegExp(r'\b\d{6}\b');

    // Pincode
    for (final line in lines) {
      final match = pinRegex.firstMatch(line);

      if (match != null) {
        pincode = match.group(0);
        break;
      }
    }

    // Address lines after "Address"
    int startIndex = -1;

    for (int i = 0; i < lines.length; i++) {
      if (lines[i].toLowerCase().contains('address')) {
        startIndex = i + 1;
        break;
      }
    }

    if (startIndex != -1) {
      final addressLines = <String>[];

      for (int i = startIndex; i < lines.length; i++) {
        final line = lines[i];

        // Stop at pincode
        if (pinRegex.hasMatch(line)) {
          addressLines.add(line);
          break;
        }

        // Ignore footer lines
        final lower = line.toLowerCase();

        if (lower.contains('uidai') ||
            lower.contains('www.') ||
            lower.contains('help') ||
            lower.contains('vid')) {
          break;
        }

        addressLines.add(line);

        // Usually 2-4 lines are enough
        if (addressLines.length >= 4) break;
      }

      address = addressLines.join(', ');
    }

    return AadhaarData(
      address: address,
      pincode: pincode,
    );
  }

  void dispose() {
    _recognizer.close();
  }
}