import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import '../../theme/app_theme.dart';
import '../../providers/csv_upload_provider.dart';
import '../../models/csv_student_model.dart';

// Mock routes and buses — replace with API data when backend is ready
const _mockRoutes = [
  {'id': 'r1', 'name': 'Route North'},
  {'id': 'r2', 'name': 'Route East'},
  {'id': 'r3', 'name': 'Route South'},
  {'id': 'r4', 'name': 'Route West'},
  {'id': 'r5', 'name': 'Route Central'},
];

const _mockBuses = [
  {'id': 'b1', 'name': 'Bus B-42'},
  {'id': 'b2', 'name': 'Bus B-38'},
  {'id': 'b3', 'name': 'Bus B-51'},
  {'id': 'b4', 'name': 'Bus B-29'},
  {'id': 'b5', 'name': 'Bus B-15'},
];

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
              routeName: provider.selectedRouteName ?? '',
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
                    'The file must have columns in this order:\n'
                    'name, grade, stop_name, drop_off_time, '
                    'emergency_contact_name, emergency_contact_phone',
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

          // Route selector
          const _SectionLabel(label: 'Select Route'),
          const SizedBox(height: 8),
          _DropdownField(
            hint: 'Choose a route',
            icon: Icons.route_rounded,
            value: provider.selectedRouteName,
            items: _mockRoutes
                .map((r) => r['name']!)
                .toList(),
            onChanged: (val) {
              final route = _mockRoutes
                  .firstWhere((r) => r['name'] == val);
              context
                  .read<CsvUploadProvider>()
                  .selectRoute(route['id']!, route['name']!);
            },
          ),

          const SizedBox(height: 16),

          // Bus selector
          const _SectionLabel(label: 'Select Bus'),
          const SizedBox(height: 8),
          _DropdownField(
            hint: 'Choose a bus',
            icon: Icons.directions_bus_rounded,
            value: provider.selectedBusName,
            items: _mockBuses
                .map((b) => b['name']!)
                .toList(),
            onChanged: (val) {
              final bus =
                  _mockBuses.firstWhere((b) => b['name'] == val);
              context
                  .read<CsvUploadProvider>()
                  .selectBus(bus['id']!, bus['name']!);
            },
          ),

          const SizedBox(height: 28),

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
                const Text('Expected column order:',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                ...[
                  'name', 'grade', 'stop_name',
                  'drop_off_time', 'emergency_contact_name',
                  'emergency_contact_phone',
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
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Upload button
          _PickFileButton(
            onFilePicked: (rows, fileName) {
              context
                  .read<CsvUploadProvider>()
                  .loadParsedStudents(rows, fileName);
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
  final Function(List<List<dynamic>>, String) onFilePicked;
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

        final rows = const CsvToListConverter().convert(csvString);
        widget.onFilePicked(rows, file.name);
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
                  const SizedBox(height: 2),
                  Text(
                    '${provider.selectedRouteName ?? "--"}  ·  '
                    '${provider.selectedBusName ?? "--"}',
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 11,
                      color: AppColors.textSecondary)),
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
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on_rounded,
                      size: 11, color: AppColors.textHint),
                  Text(' ${student.stopName}',
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 11,
                      color: AppColors.textHint)),
                  const SizedBox(width: 8),
                  const Icon(Icons.schedule_rounded,
                      size: 11, color: AppColors.textHint),
                  Text(' ${student.dropOffTime}',
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 11,
                      color: AppColors.textHint)),
                ]),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.emergency_rounded,
                  size: 12, color: AppColors.textHint),
              const SizedBox(height: 2),
              Text(student.emergencyContactName,
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 10,
                  color: AppColors.textHint)),
              Text(student.emergencyContactPhone,
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 10,
                  color: AppColors.textHint)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Step 3: Success view ──────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final int count;
  final String routeName;
  final VoidCallback onUploadAnother;

  const _SuccessView({
    required this.count,
    required this.routeName,
    required this.onUploadAnother,
  });

  @override
  Widget build(BuildContext context) {
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
            child: const Icon(Icons.check_circle_rounded,
                color: AppColors.secondary, size: 44),
          ),
          const SizedBox(height: 20),
          const Text('Upload Successful',
            style: TextStyle(fontFamily: 'Outfit', fontSize: 22,
              fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          Text(
            '$count student${count != 1 ? "s" : ""} have been added to $routeName.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 14,
              color: AppColors.textSecondary, height: 1.6)),
          const SizedBox(height: 8),
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

class _DropdownField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final String? value;
  final List<String> items;
  final Function(String?) onChanged;

  const _DropdownField({
    required this.hint,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Row(children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(hint, style: const TextStyle(fontFamily: 'Outfit',
              fontSize: 14, color: AppColors.textHint)),
          ]),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          style: const TextStyle(fontFamily: 'Outfit', fontSize: 14,
            color: AppColors.textPrimary),
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
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