// lib/presentation/screens/scan_sheet/scan_sheet_screen.dart
//
// Scan Sheet screen: Camera/Gallery → OCR → Preview → Analyze via agent pipeline.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/ocr_service.dart';
import '../../../data/models/student_model.dart';
import '../analysis/reasoning_trail_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanSheetScreen extends StatefulWidget {
  const ScanSheetScreen({super.key});

  @override
  State<ScanSheetScreen> createState() => _ScanSheetScreenState();
}

class _ScanSheetScreenState extends State<ScanSheetScreen> {
  final OcrService _ocr = OcrService.instance;

  File? _imageFile;
  String? _extractedText;
  bool _isProcessingOcr = false;
  String? _errorMessage;

  // ── Image source selection ──────────────────────────────────────────────

  Future<void> _pickImage(ImageSourceType source) async {
    setState(() {
      _errorMessage = null;
      _isProcessingOcr = true;
    });

    try {
      OcrResult? result;
      if (source == ImageSourceType.camera) {
        // Check permission first
        final hasPermission = await _ocr.requestCameraPermission();
        if (!hasPermission) {
          final isPermanentlyDenied =
              await _ocr.isCameraPermissionPermanentlyDenied();
          setState(() {
            _isProcessingOcr = false;
            _errorMessage = isPermanentlyDenied
                ? 'Camera permission permanently denied. Please enable it in Settings.'
                : 'Camera permission is required to scan sheets.';
          });
          if (isPermanentlyDenied) {
            openAppSettings();
          }
          return;
        }
        result = await _ocr.scanFromCamera();
      } else {
        result = await _ocr.scanFromGallery();
      }

      if (result == null) {
        // User cancelled
        setState(() => _isProcessingOcr = false);
        return;
      }

      setState(() {
        _imageFile = result!.imageFile;
        _extractedText = result.extractedText;
        _isProcessingOcr = false;
      });
    } catch (e) {
      setState(() {
        _isProcessingOcr = false;
        _errorMessage = 'Failed to process image: $e';
      });
    }
  }

  void _analyzeText() {
    if (_extractedText == null || _extractedText!.trim().isEmpty) {
      setState(() {
        _errorMessage = 'No text was extracted from the image. '
            'Try a clearer photo with better lighting.';
      });
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReasoningTrailScreen(
          scannedText: _extractedText!,
        ),
      ),
    );
  }

  void _importNamesAndMarks() {
    if (_extractedText == null || _extractedText!.trim().isEmpty) return;

    final lines = _extractedText!.split('\n');
    final importedStudents = <Student>[];
    final now = DateTime.now();

    int count = 0;
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final numberMatch = RegExp(r'(\d{1,3})(?:\s*%|\s*marks)?', caseSensitive: false).firstMatch(line);
      final namePart = line.replaceAll(RegExp(r'\d+.*'), '').replaceAll(RegExp(r'[^\w\s]'), '').trim();

      if (namePart.length >= 2) {
        count++;
        final score = numberMatch != null ? (double.tryParse(numberMatch.group(1)!) ?? 75.0) : 80.0;
        final clampedScore = score.clamp(0.0, 100.0);

        importedStudents.add(
          Student(
            id: 'stu_ocr_$count',
            name: namePart,
            grade: '7-B',
            attendance: [
              AttendanceRecord(date: now, isPresent: true),
              AttendanceRecord(date: now.subtract(const Duration(days: 1)), isPresent: true),
              AttendanceRecord(date: now.subtract(const Duration(days: 2)), isPresent: true),
            ],
            fees: [
              FeeRecord(dueDate: now, paidDate: now, amountDue: 2500, amountPaid: 2500),
            ],
            examScores: {
              now: clampedScore,
            },
            teacherNotes: [
              TaggedNote(date: now, authorTag: 'ocr_scan', content: 'Scanned from sheet ($line)'),
            ],
          ),
        );
      }
    }

    if (importedStudents.isEmpty) {
      importedStudents.add(
        Student(
          id: 'stu_ocr_0',
          name: 'Scanned Student',
          grade: '7-B',
          attendance: [AttendanceRecord(date: now, isPresent: true)],
          fees: [FeeRecord(dueDate: now, paidDate: now, amountDue: 2500, amountPaid: 2500)],
          examScores: {now: 75.0},
          teacherNotes: [TaggedNote(date: now, authorTag: 'ocr', content: 'Scanned Sheet Entry')],
        ),
      );
    }

    Provider.of<AppState>(context, listen: false).importStudents(importedStudents);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Imported ${importedStudents.length} student record(s) into database!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _reset() {
    setState(() {
      _imageFile = null;
      _extractedText = null;
      _errorMessage = null;
    });
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Scan Sheet',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_imageFile != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              color: AppColors.textSecondary,
              onPressed: _reset,
              tooltip: 'Scan again',
            ),
        ],
      ),
      body: _isProcessingOcr
          ? _buildLoadingState()
          : _imageFile == null
              ? _buildSourceSelection()
              : _buildResultView(),
    );
  }

  // ── Source selection (no image yet) ─────────────────────────────────────

  Widget _buildSourceSelection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.document_scanner_rounded,
            size: 80,
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          const Text(
            'Choose how to scan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Take a photo of a student attendance, score, or fee sheet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),

          // Camera button
          _SourceButton(
            icon: Icons.camera_alt_rounded,
            label: 'Take Photo',
            subtitle: 'Use camera to capture a sheet',
            color: AppColors.primary,
            onTap: () => _pickImage(ImageSourceType.camera),
          ),

          const SizedBox(height: 16),

          // Gallery button
          _SourceButton(
            icon: Icons.photo_library_rounded,
            label: 'Pick from Gallery',
            subtitle: 'Select an existing photo',
            color: AppColors.accent,
            onTap: () => _pickImage(ImageSourceType.gallery),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.error, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.error,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // ── Loading state ──────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Processing image…',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Extracting text via OCR',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  // ── Result view (image + extracted text) ───────────────────────────────

  Widget _buildResultView() {
    final hasText = _extractedText != null && _extractedText!.trim().isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image preview
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    _imageFile!,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),

                // Extracted text header
                Row(
                  children: [
                    Icon(
                      hasText
                          ? Icons.text_fields_rounded
                          : Icons.warning_amber_rounded,
                      size: 20,
                      color: hasText ? AppColors.primary : AppColors.riskHigh,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasText ? 'Extracted Text' : 'No Text Found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: hasText
                            ? AppColors.textPrimary
                            : AppColors.riskHigh,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Extracted text body
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: SelectableText(
                    hasText
                        ? _extractedText!
                        : 'No text could be extracted. Try a clearer image '
                            'with better lighting and contrast.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      fontFamily: hasText ? 'monospace' : null,
                      color: hasText
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Bottom action bar
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasText) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _importNamesAndMarks,
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: const Text('Import Names & Marks to App'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Rescan'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.divider),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: hasText ? _analyzeText : null,
                      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: const Text('Run AI Analysis'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.divider,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Helper enum ──────────────────────────────────────────────────────────────

enum ImageSourceType { camera, gallery }

// ── Source button widget ─────────────────────────────────────────────────────

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
