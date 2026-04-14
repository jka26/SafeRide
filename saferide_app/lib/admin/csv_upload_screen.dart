import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../theme/app_theme.dart';
import '../../providers/csv_upload_provider.dart';
import '../../models/csv_student_model.dart';

class CsvUploadScreen extends StatelessWidget {
  const CsvUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CsvUploadProvider(),
      child: const _CsvUploadBody(),
    );
  }
}

class _CsvUploadBody extends StatelessWidget {
  const _CsvUploadBody();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CsvUploadProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF6D28D9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Upload Student List',
          style: TextStyle(
            fontFamily: 'Outfit', fontSize: 16,
            fontWeight: FontWeight.w700, color: Colors.white,
          ),
        ),
      ),
      body: provider.isSuccess
          ? _SuccessView(
              count: provider.uploadedCount,
              skipped: provider.skippedCount,
              routeName: '',
              onUploadAnother: () => context.read<CsvUploadProvider>().reset(),
            )
          : provider.isPreviewing
              ? _PreviewView()
              : _UploadView(),
    );
  }
}

// ── Step 1: Upload view ───────────────────────────────────────────────────────

class _UploadView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CsvUploadProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF6D28D9).withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF6D28D9).withOpacity(0.2)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_rounded,
                    color: Color(0xFF6D28D9), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Upload a CSV file with student details. '
                    'Required columns: studentCode, fullName, grade.\n'
                    'You can also include optional columns for routing and contacts.',
                    style: TextStyle(
                      fontFamily: 'Outfit', fontSize: 12,
                      color: Color(0xFF6D28D9), height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // CSV format guide
          const _SectionLabel(label: 'CSV Format'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Required columns:',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                ...[
                  'studentCode', 'fullName', 'grade',
                ].asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6D28D9).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${e.key + 1}',
                          style: const TextStyle(
                            fontFamily: 'Outfit', fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6D28D9))),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(e.value,
                      style: const TextStyle(fontFamily: 'Outfit',
                        fontSize: 12, color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
                  ]),
                )),
                const SizedBox(height: 10),
                const Text('Optional supported columns:',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                const Text(
                  'routeName, busLabel, stopName, dropOffTime, '
                  'emergencyContactName, emergencyContactPhone',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Headers are matched by name, so strict column order is not required.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Upload button
          _PickFileButton(
            onFilePicked: (csvText, fileName) {
              context
                  .read<CsvUploadProvider>()
                  .previewCsv(csvText, fileName);
            },
          ),

          if (provider.errorMessage != null) ...[
            const SizedBox(height: 14),
            _ErrorBanner(message: provider.errorMessage!),
          ],
        ],
      ),
    );
  }
}

// ── File picker button ────────────────────────────────────────────────────────

class _PickFileButton extends StatefulWidget {
  final Function(String, String) onFilePicked;
  const _PickFileButton({required this.onFilePicked});

  @override
  State<_PickFileButton> createState() => _PickFileButtonState();
}

class _PickFileButtonState extends State<_PickFileButton> {
  bool _picking = false;

  Future<void> _pick() async {
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        String csvString;

        // Web returns bytes; mobile/desktop returns a path
        if (file.bytes != null) {
          csvString = String.fromCharCodes(file.bytes!);
        } else if (file.path != null) {
          csvString = await File(file.path!).readAsString();
        } else {
          throw Exception('Could not read file.');
        }

        widget.onFilePicked(csvString, file.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reading file: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _picking ? null : _pick,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF6D28D9).withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF6D28D9).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: _picking
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF6D28D9),
                      ),
                    )
                  : const Icon(Icons.upload_file_rounded,
                      color: Color(0xFF6D28D9), size: 26),
            ),
            const SizedBox(height: 12),
            const Text('Tap to select CSV file',
              style: TextStyle(fontFamily: 'Outfit', fontSize: 14,
                fontWeight: FontWeight.w600, color: Color(0xFF6D28D9))),
            const SizedBox(height: 4),
            const Text('.csv files only',
              style: TextStyle(fontFamily: 'Outfit', fontSize: 12,
                color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }
}

// ── Step 2: Preview view ──────────────────────────────────────────────────────

class _PreviewView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CsvUploadProvider>();
    final valid = provider.validStudents;
    final invalid = provider.invalidStudents;

    return Column(
      children: [
        // Summary bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(provider.fileName ?? 'Uploaded file',
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 13,
                      fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis),
                ],
              )),
              _CountBadge(count: valid.length, label: 'valid',
                  color: AppColors.secondary),
              if (invalid.isNotEmpty) ...[
                const SizedBox(width: 8),
                _CountBadge(count: invalid.length, label: 'errors',
                    color: AppColors.error),
              ],
            ],
          ),
        ),
        if (provider.hasPreviewTruncation)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6D28D9).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF6D28D9).withOpacity(0.2)),
            ),
            child: Text(
              'Showing first ${provider.previewCount} of ${provider.totalRows} rows to keep preview fast. Full file will still upload.',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11,
                color: Color(0xFF6D28D9),
                height: 1.4,
              ),
            ),
          ),

        const Divider(height: 1, color: AppColors.divider),

        // Error rows (if any)
        if (invalid.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.warning_rounded,
                      color: AppColors.error, size: 16),
                  const SizedBox(width: 6),
                  Text('${invalid.length} row(s) have errors and will be skipped',
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 12,
                      fontWeight: FontWeight.w600, color: AppColors.error)),
                ]),
                const SizedBox(height: 6),
                ...invalid.map((s) => Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    '• ${s.name.isNotEmpty ? s.name : "Row"}: ${s.errorMessage}',
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 11,
                      color: AppColors.error)),
                )),
              ],
            ),
          ),

        // Student preview list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: valid.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _PreviewStudentTile(student: valid[index]);
            },
          ),
        ),

        // Bottom action bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.06),
                  blurRadius: 10, offset: const Offset(0, -3)),
            ],
          ),
          child: Column(
            children: [
              if (provider.errorMessage != null) ...[
                _ErrorBanner(message: provider.errorMessage!),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  // Back button
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          context.read<CsvUploadProvider>().reset(),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: const Center(
                          child: Text('Back',
                            style: TextStyle(fontFamily: 'Outfit',
                              fontSize: 14, fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Confirm upload button
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: provider.isUploading || !provider.hasValidStudents
                          ? null
                          : () => context
                              .read<CsvUploadProvider>()
                              .uploadStudents(),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: provider.hasValidStudents
                              ? const Color(0xFF6D28D9)
                              : AppColors.textHint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: provider.isUploading
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                              : Text(
                                  'Upload ${valid.length} Student${valid.length != 1 ? "s" : ""}',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit', fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                        ),
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

// ── Preview student tile ──────────────────────────────────────────────────────

class _PreviewStudentTile extends StatelessWidget {
  final CsvStudentModel student;
  const _PreviewStudentTile({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.03), blurRadius: 4)],
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFF6D28D9), shape: BoxShape.circle),
            child: Center(child: Text(student.initials,
              style: const TextStyle(fontFamily: 'Outfit', fontSize: 13,
                fontWeight: FontWeight.w700, color: Colors.white))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name,
                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 13,
                    fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(student.grade,
                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 11,
                    color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 3: Success view ──────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final int count;
  final int skipped;
  final String routeName;
  final VoidCallback onUploadAnother;

  const _SuccessView({
    required this.count,
    required this.skipped,
    required this.routeName,
    required this.onUploadAnother,
  });

  @override
  Widget build(BuildContext context) {
    final String detail;
    if (count == 0 && skipped == 0) {
      detail =
          'No data rows were imported. Check that your CSV has a header row '
          'and columns the app recognizes for student code, name, and grade '
          '(e.g. studentCode, fullName, grade).';
    } else if (count == 0 && skipped > 0) {
      detail =
          'No new students were added. All $skipped row${skipped != 1 ? "s" : ""} '
          'use student codes that already exist in the database. '
          'Change codes in the file or remove existing students first.';
    } else if (skipped > 0) {
      detail =
          routeName.isEmpty
              ? '$count new student${count != 1 ? "s" : ""} added. '
                    '$skipped row${skipped != 1 ? "s" : ""} skipped (duplicate student codes).'
              : '$count new student${count != 1 ? "s" : ""} added to $routeName. '
                    '$skipped skipped (duplicate codes).';
    } else {
      detail = routeName.isEmpty
          ? '$count student${count != 1 ? "s" : ""} have been added.'
          : '$count student${count != 1 ? "s" : ""} have been added to $routeName.';
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              count == 0 && skipped == 0
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_rounded,
              color: count == 0 && skipped == 0
                  ? AppColors.accent
                  : AppColors.secondary,
              size: 44,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            count == 0 && skipped == 0
                ? 'Nothing imported'
                : 'Upload finished',
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 22,
              fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 14,
              color: AppColors.textSecondary, height: 1.6)),
          const SizedBox(height: 8),
          if (count > 0)
            Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'The driver\'s student list has been updated',
              style: TextStyle(fontFamily: 'Outfit', fontSize: 12,
                color: AppColors.secondary, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: onUploadAnother,
            child: Container(
              width: double.infinity, height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF6D28D9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text('Upload Another List',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 15,
                    fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity, height: 50,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Center(
                child: Text('Back to Dashboard',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small reusable widgets ────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
      style: const TextStyle(fontFamily: 'Outfit', fontSize: 13,
        fontWeight: FontWeight.w600, color: AppColors.textPrimary));
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _CountBadge(
      {required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text('$count $label',
        style: TextStyle(fontFamily: 'Outfit', fontSize: 11,
          fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(message,
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 13,
              color: AppColors.error, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
