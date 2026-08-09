// lib/core/services/ocr_service.dart
//
// Handles camera/gallery image picking and OCR text extraction
// using google_mlkit_text_recognition + image_picker + permission_handler.

import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Result of an OCR scan operation.
class OcrResult {
  final String extractedText;
  final File imageFile;

  const OcrResult({required this.extractedText, required this.imageFile});
}

/// Service that handles camera permissions, image capture/pick, and OCR.
class OcrService {
  OcrService._();
  static final OcrService instance = OcrService._();

  final ImagePicker _picker = ImagePicker();

  // ── Permission handling ─────────────────────────────────────────────────

  /// Requests camera permission. Returns true if granted.
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;

    final result = await Permission.camera.request();
    return result.isGranted;
  }

  /// Checks if camera permission is currently granted.
  Future<bool> isCameraPermissionGranted() async {
    return await Permission.camera.isGranted;
  }

  /// Returns true if the user permanently denied camera permission.
  Future<bool> isCameraPermissionPermanentlyDenied() async {
    return await Permission.camera.isPermanentlyDenied;
  }

  // ── Image capture ───────────────────────────────────────────────────────

  /// Captures an image from the camera.
  /// Returns null if the user cancels.
  Future<File?> captureFromCamera() async {
    final hasPermission = await requestCameraPermission();
    if (!hasPermission) return null;

    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
      maxWidth: 2048,
      maxHeight: 2048,
    );

    if (photo == null) return null;
    return File(photo.path);
  }

  /// Picks an image from the gallery.
  /// Returns null if the user cancels.
  Future<File?> pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 2048,
      maxHeight: 2048,
    );

    if (image == null) return null;
    return File(image.path);
  }

  // ── OCR text extraction ────────────────────────────────────────────────

  /// Runs OCR on the given [imageFile] and returns the extracted text.
  /// Returns an empty string if no text is found.
  Future<String> extractText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      final buffer = StringBuffer();
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          buffer.writeln(line.text);
        }
        buffer.writeln(); // Blank line between blocks
      }

      return buffer.toString().trim();
    } finally {
      await textRecognizer.close();
    }
  }

  // ── Combined scan flow ─────────────────────────────────────────────────

  /// Full scan flow: pick image (camera or gallery) → extract text.
  /// Returns null if the user cancels at any step.
  Future<OcrResult?> scanFromCamera() async {
    final file = await captureFromCamera();
    if (file == null) return null;

    final text = await extractText(file);
    return OcrResult(extractedText: text, imageFile: file);
  }

  /// Full scan flow from gallery.
  Future<OcrResult?> scanFromGallery() async {
    final file = await pickFromGallery();
    if (file == null) return null;

    final text = await extractText(file);
    return OcrResult(extractedText: text, imageFile: file);
  }
}
