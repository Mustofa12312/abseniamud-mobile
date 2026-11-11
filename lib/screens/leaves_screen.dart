import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/leave_provider.dart';
import '../widgets/status_badge.dart';

class LeavesScreen extends StatefulWidget {
  const LeavesScreen({super.key});

  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<LeaveProvider>(context, listen: false).fetchLeaves();
    });
  }

  void _showAddLeaveDialog() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddLeaveBottomSheet(
        rootMessenger: ScaffoldMessenger.of(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leaveProvider = Provider.of<LeaveProvider>(context);
    final leaves = leaveProvider.leaves;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Pengajuan Izin & Cuti', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: RefreshIndicator(
        onRefresh: () => leaveProvider.fetchLeaves(),
        color: AppColors.brand600,
        child: leaveProvider.isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
            : leaves.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              leaveProvider.errorMessage != null ? Icons.cloud_off_rounded : Icons.assignment_turned_in_rounded,
                              size: 54,
                              color: const Color(0xFFCBD5E1),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                leaveProvider.errorMessage ?? 'Belum ada pengajuan izin, sakit, atau cuti.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (leaveProvider.errorMessage != null)
                              ElevatedButton.icon(
                                onPressed: () => leaveProvider.fetchLeaves(),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Muat Ulang'),
                              )
                            else
                              ElevatedButton.icon(
                                onPressed: _showAddLeaveDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Buat Pengajuan Baru'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: leaves.length,
                    itemBuilder: (context, index) {
                    final item = leaves[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.brand50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.type.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.brand800,
                                    ),
                                  ),
                                ),
                                StatusBadge(status: item.status),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.date_range_rounded, size: 16, color: AppColors.textSecondaryLight),
                                const SizedBox(width: 6),
                                Text(
                                  '${item.startDate} s/d ${item.endDate}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimaryLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.reason,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondaryLight,
                                height: 1.3,
                              ),
                            ),
                            if (item.documentPath != null && item.documentPath!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.attachment_rounded, size: 14, color: AppColors.brand700),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Dokumen: ${item.documentPath}',
                                      style: const TextStyle(fontSize: 11.5, color: AppColors.brand700, fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (item.adminNotes != null && item.adminNotes!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.borderLight),
                                ),
                                child: Text(
                                  'Catatan Admin: ${item.adminNotes}',
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155)),
                                ),
                              ),
                            ],
                            const Divider(height: 20),
                            Text(
                              'Diajukan pada: ${item.createdAt}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddLeaveDialog,
        backgroundColor: AppColors.brand600,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ajukan Izin / Cuti', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _AddLeaveBottomSheet extends StatefulWidget {
  final ScaffoldMessengerState rootMessenger;

  const _AddLeaveBottomSheet({required this.rootMessenger});

  @override
  State<_AddLeaveBottomSheet> createState() => _AddLeaveBottomSheetState();
}

class _AddLeaveBottomSheetState extends State<_AddLeaveBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _docController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _selectedType = 'Izin';
  String? _submitError;
  static const List<String> _leaveTypes = ['Izin', 'Sakit', 'Cuti'];

  @override
  void dispose() {
    _reasonController.dispose();
    _docController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext sheetContext) {
    return Padding(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pengajuan Izin / Sakit / Cuti',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_submitError != null) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.securityAlertBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.securityAlertBorder),
                  ),
                  child: Text(
                    _submitError!,
                    style: const TextStyle(fontSize: 12, color: AppColors.securityAlertText, fontWeight: FontWeight.w600),
                  ),
                ),
              ],

              const Text('Jenis Pengajuan', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                items: _leaveTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type, style: const TextStyle(fontSize: 13)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedType = val);
                  }
                },
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tanggal Mulai', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: sheetContext,
                              initialDate: _startDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (picked != null && mounted) {
                              setState(() {
                                _startDate = picked;
                                if (_endDate.isBefore(_startDate)) {
                                  _endDate = _startDate;
                                }
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.brand700),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('dd/MM/yyyy').format(_startDate),
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tanggal Selesai', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: sheetContext,
                              initialDate: _endDate,
                              firstDate: _startDate,
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (picked != null && mounted) {
                              setState(() => _endDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.brand700),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('dd/MM/yyyy').format(_endDate),
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              const Text('Alasan / Keterangan', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Jelaskan alasan pengajuan izin/sakit/cuti...',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Alasan wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              const Text('Nomor Surat / Link Dokumen Pendukung (Opsional)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _docController,
                decoration: const InputDecoration(
                  hintText: 'Contoh: No. Surat Dokter / Bukti Penugasan',
                  prefixIcon: Icon(Icons.attachment_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 20),

              Consumer<LeaveProvider>(
                builder: (ctx, provider, _) {
                  return SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: provider.isSubmitting
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              setState(() => _submitError = null);
                              final docText = _docController.text.trim();
                              final result = await provider.submitLeave(
                                type: _selectedType,
                                startDate: DateFormat('yyyy-MM-dd').format(_startDate),
                                endDate: DateFormat('yyyy-MM-dd').format(_endDate),
                                reason: _reasonController.text.trim(),
                                documentPath: docText.isNotEmpty ? docText : null,
                              );

                              if (!mounted) return;
                              if (result['success'] == true) {
                                Navigator.of(context).pop();
                                widget.rootMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(result['message'] ?? 'Pengajuan berhasil dikirim.'),
                                    backgroundColor: AppColors.brand600,
                                  ),
                                );
                              } else {
                                setState(() {
                                  _submitError = result['message']?.toString() ?? 'Gagal mengirim pengajuan.';
                                });
                              }
                            },
                      child: provider.isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Kirim Pengajuan'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
