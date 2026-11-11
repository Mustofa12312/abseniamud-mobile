import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/correction_provider.dart';
import '../widgets/status_badge.dart';

class CorrectionsScreen extends StatefulWidget {
  const CorrectionsScreen({super.key});

  @override
  State<CorrectionsScreen> createState() => _CorrectionsScreenState();
}

class _CorrectionsScreenState extends State<CorrectionsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<CorrectionProvider>(context, listen: false).fetchCorrections();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 160) {
      final provider = Provider.of<CorrectionProvider>(context, listen: false);
      if (provider.hasMore && !provider.isLoadingMore && !provider.isLoading) {
        provider.fetchCorrections(loadMore: true);
      }
    }
  }

  void _showAddCorrectionDialog() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddCorrectionBottomSheet(
        rootMessenger: ScaffoldMessenger.of(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final corrProvider = Provider.of<CorrectionProvider>(context);
    final corrections = corrProvider.corrections;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Pengajuan Koreksi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: RefreshIndicator(
        onRefresh: () => corrProvider.fetchCorrections(),
        color: AppColors.brand600,
        child: corrProvider.isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
            : corrections.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              corrProvider.errorMessage != null ? Icons.cloud_off_rounded : Icons.playlist_add_check_rounded,
                              size: 54,
                              color: const Color(0xFFCBD5E1),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                corrProvider.errorMessage ?? 'Belum ada pengajuan koreksi presensi.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (corrProvider.errorMessage != null)
                              ElevatedButton.icon(
                                onPressed: () => corrProvider.fetchCorrections(),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Muat Ulang'),
                              )
                            else
                              ElevatedButton.icon(
                                onPressed: _showAddCorrectionDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Buat Pengajuan Baru'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    itemCount: corrections.length + ((corrProvider.hasMore || corrProvider.isLoadingMore) ? 1 : 0),
                    itemBuilder: (context, index) {
                    if (index >= corrections.length) {
                      if (corrProvider.isLoadingMore) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 12),
                        child: OutlinedButton.icon(
                          onPressed: () => corrProvider.fetchCorrections(loadMore: true),
                          icon: const Icon(Icons.expand_more_rounded),
                          label: Text('Muat Lebih Banyak (${corrections.length}/${corrProvider.total})'),
                        ),
                      );
                    }
                    final item = corrections[index];
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
                                Text(
                                  item.date,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimaryLight,
                                  ),
                                ),
                                StatusBadge(status: item.status),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.brand50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.type,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.brand800,
                                ),
                              ),
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
        onPressed: _showAddCorrectionDialog,
        backgroundColor: AppColors.brand600,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ajukan Koreksi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _AddCorrectionBottomSheet extends StatefulWidget {
  final ScaffoldMessengerState rootMessenger;

  const _AddCorrectionBottomSheet({required this.rootMessenger});

  @override
  State<_AddCorrectionBottomSheet> createState() => _AddCorrectionBottomSheetState();
}

class _AddCorrectionBottomSheetState extends State<_AddCorrectionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'Lupa Presensi Masuk';
  String? _submitError;
  static const List<String> _correctionTypes = [
    'Lupa Presensi Masuk',
    'Lupa Presensi Pulang',
    'Kendala GPS / Sinyal',
    'Tugas Luar Kampus',
    'Dinas Akademik',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
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
                    'Ajukan Koreksi Presensi',
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

              const Text('Tanggal Presensi', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: sheetContext,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null && mounted) {
                    setState(() => _selectedDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.brand700),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('yyyy-MM-dd').format(_selectedDate),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      const Text('Ubah', style: TextStyle(fontSize: 12, color: AppColors.brand600, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              const Text('Jenis Koreksi', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                items: _correctionTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type, style: const TextStyle(fontSize: 13)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedType = val);
                  }
                },
              ),
              const SizedBox(height: 14),

              const Text('Alasan / Keterangan', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Jelaskan alasan pengajuan koreksi...',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Alasan wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              Consumer<CorrectionProvider>(
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
                              final result = await provider.submitCorrection(
                                date: DateFormat('yyyy-MM-dd').format(_selectedDate),
                                type: _selectedType,
                                reason: _reasonController.text.trim(),
                              );

                              if (!mounted) return;
                              if (result['success'] == true) {
                                Navigator.of(context).pop();
                                widget.rootMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(result['message'] ?? 'Pengajuan koreksi berhasil dikirim.'),
                                    backgroundColor: AppColors.brand600,
                                  ),
                                );
                              } else {
                                setState(() {
                                  _submitError = result['message']?.toString() ?? 'Gagal mengirim pengajuan koreksi.';
                                });
                              }
                            },
                      child: provider.isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Kirim Pengajuan Koreksi'),
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
