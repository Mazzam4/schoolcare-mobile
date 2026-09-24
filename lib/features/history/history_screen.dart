import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/widgets/toast_widget.dart';
import '../report/create_report_modal.dart';
import '../../core/api_config.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  String _orgName = "Sekolahmu";
  String _userRole = "siswa";
  List<dynamic> _myReports = [];

  // Filter Status (Bisa bernilai null agar bisa menampilkan semua data)
  String? _selectedStatusFilter;
  Set<int> _expandedReports = {};

  @override
  void initState() {
    super.initState();
    _fetchMyReports();
  }

  Future<void> _fetchMyReports() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      _userRole = prefs.getString('userRole') ?? 'siswa';

      final dio = Dio();

      // TEMBAK API KHUSUS RIWAYAT SAYA
      final response = await dio.get(
        "${ApiConfig.baseUrl}/api/reports/me",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _orgName = response.data['organizationName'] ?? "Sekolahmu";
          _myReports = response.data['reports'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateReportStatus(int reportId, String newStatus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final dio = Dio();

      await dio.put(
        "${ApiConfig.baseUrl}/api/reports/$reportId/status",
        data: {"status": newStatus},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      await _fetchMyReports();
      if (!mounted) return;
      showAppToast(
        context,
        message: 'Status diperbarui!',
        isSuccess: true,
        icon: Icons.check_circle_outline_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      showAppToast(
        context,
        message: 'Gagal memperbarui status.',
        isSuccess: false,
        icon: Icons.error_outline_rounded,
      );
    }
  }

  void _toggleExpand(int reportId) {
    setState(() {
      if (_expandedReports.contains(reportId)) {
        _expandedReports.clear();
      } else {
        _expandedReports.clear();
        _expandedReports.add(reportId);
      }
    });
  }

  // Warna & label status (diambil dari kodemu)
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return const Color(0xFF92C97A);
      case 'proses':
        return const Color(0xFFD9CE6A);
      default:
        return const Color(0xFFBA7063);
    }
  }

  Color _statusBorderColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return const Color(0xFF92C97A);
      case 'proses':
        return const Color(0xFFD9CE6A);
      default:
        return const Color(0xFFBA7063);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Logika Filter
    List<dynamic> filteredReports = _selectedStatusFilter == null
        ? _myReports
        : _myReports
              .where(
                (r) => (r['status'] ?? '').toLowerCase().contains(
                  _selectedStatusFilter!.toLowerCase(),
                ),
              )
              .toList();

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: RefreshIndicator(
            onRefresh: _fetchMyReports,
            color: const Color(0xFF1C1C1E),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 28.0,
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Text(
                          'Riwayat Laporan Kamu',
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C1C1E),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE5E5EA),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          size: 20,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ini adalah riwayat kamu dalam Menjaga Fasilitas\ndan Kebersihan di Organisasi/sekolah $_orgName',
                    style: TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 13,
                      color: Color(0xFF8E8E93),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── GREY BAR: "Riwayat Laporan Kamu" & Tombol Buat ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              'Riwayat Laporan Kamu',
                              style: TextStyle(
                                fontFamily: 'SF Pro Text',
                                fontSize: 12,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const CreateReportModal(),
                            ).then(
                              (_) => _fetchMyReports(),
                            ); // Auto-refresh setelah modal ditutup
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF007AFF,
                            ), // Biru iOS
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                            minimumSize: const Size(0, 34),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.add, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Buat Laporan',
                                style: TextStyle(
                                  fontFamily: 'SF Pro Text',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Status Filter Chips ──
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatusChip("Selesai"),
                        const SizedBox(width: 8),
                        _buildStatusChip("Dilaporkan"),
                        const SizedBox(width: 8),
                        _buildStatusChip("Proses"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Loading ──
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1C1C1E),
                          strokeWidth: 2,
                        ),
                      ),
                    ),

                  // ── Kosong ──
                  if (!_isLoading && _myReports.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 48,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Kamu belum pernah membuat laporan.',
                              style: TextStyle(
                                fontFamily: 'SF Pro Text',
                                fontSize: 15,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── List Laporan ──
                  if (!_isLoading && filteredReports.isNotEmpty)
                    ...filteredReports
                        .map((report) => _buildReportCard(report))
                        .toList(),

                  // ── Kosong (Karena Filter) ──
                  if (!_isLoading &&
                      filteredReports.isEmpty &&
                      _myReports.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Center(
                        child: Text(
                          'Tidak ada riwayat dengan status "$_selectedStatusFilter".',
                          style: TextStyle(
                            fontFamily: 'SF Pro Text',
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Fungsi membuat Card, persis dengan kodemu ──
  Widget _buildReportCard(dynamic report) {
    final int id = report['id'];
    final bool isExpanded = _expandedReports.contains(id);
    final String title = report['category'] ?? 'Laporan';
    final String location = report['location'] ?? '-';
    final String sender = report['author']?['firstName'] ?? '-';
    final String status = report['status'] ?? 'Dilaporkan';
    final String description = report['description'] ?? '-';
    final String? base64Photo = report['photoBase64'];
    final double? lat = (report['latitude'] as num?)?.toDouble();
    final double? lng = (report['longitude'] as num?)?.toDouble();
    final bool isGuru = _userRole.toLowerCase() == 'guru';

    final DateTime date = DateTime.parse(report['createdAt']).toLocal();
    final String timeStr =
        '${date.hour.toString().padLeft(2, '0')}.${date.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () => _toggleExpand(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isExpanded
                ? const Color(0xFFE5E5EA)
                : const Color(0xFFF2F2F7),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          (report['type'] ?? '')
                                  .toString()
                                  .toLowerCase()
                                  .contains('kebersihan')
                              ? Icons.cleaning_services_outlined
                              : Icons.build_circle_outlined,
                          size: 20,
                          color: const Color(0xFF555555),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1d1d1f),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 12,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  location,
                                  style: TextStyle(
                                    fontFamily: 'SF Pro Text',
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 12,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                    fontFamily: 'SF Pro Text',
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 280),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.grey.shade400,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 14,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Anda ($sender)",
                            style: const TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF1d1d1f),
                            ),
                          ),
                        ],
                      ),
                      if (isGuru && isExpanded)
                        _buildStatusDropdown(id, status)
                      else
                        _buildStatusBadge(status),
                    ],
                  ),
                ],
              ),
            ),

            // ── Detail (dengan animasi kebuka/ketutup) ──
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFF2F2F7),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (base64Photo != null &&
                                      base64Photo.isNotEmpty ||
                                  (lat != null && lng != null))
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (base64Photo != null &&
                                        base64Photo.isNotEmpty)
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Foto Bukti',
                                              style: TextStyle(
                                                fontFamily: 'SF Pro Text',
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.memory(
                                                base64Decode(base64Photo),
                                                width: double.infinity,
                                                height: 130,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (base64Photo != null &&
                                        base64Photo.isNotEmpty &&
                                        lat != null &&
                                        lng != null)
                                      const SizedBox(width: 10),
                                    if (lat != null && lng != null)
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Lokasi GPS',
                                              style: TextStyle(
                                                fontFamily: 'SF Pro Text',
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            GestureDetector(
                                              onTap: () async {
                                                final url =
                                                    'https://www.google.com/maps?q=$lat,$lng';
                                                if (await canLaunchUrl(
                                                  Uri.parse(url),
                                                ))
                                                  await launchUrl(
                                                    Uri.parse(url),
                                                    mode: LaunchMode
                                                        .externalApplication,
                                                  );
                                              },
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Stack(
                                                  children: [
                                                    Image.network(
                                                      'https://maps.geoapify.com/v1/staticmap?style=osm-carto&width=400&height=260&center=lonlat:$lng,$lat&zoom=16&marker=lonlat:$lng,$lat;color:%23ff0000;size:medium&apiKey=caa5e20481224996ab88f0837cdba468',
                                                      width: double.infinity,
                                                      height: 130,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => Container(
                                                        height: 130,
                                                        decoration: BoxDecoration(
                                                          color: const Color(
                                                            0xFFF2F2F7,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .map_outlined,
                                                              size: 28,
                                                              color: Colors
                                                                  .grey
                                                                  .shade400,
                                                            ),
                                                            const SizedBox(
                                                              height: 4,
                                                            ),
                                                            Text(
                                                              'Buka Maps',
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    'SF Pro Text',
                                                                fontSize: 11,
                                                                color: Colors
                                                                    .grey
                                                                    .shade500,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
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
                              if (base64Photo != null &&
                                      base64Photo.isNotEmpty ||
                                  (lat != null && lng != null))
                                const SizedBox(height: 14),
                              Text(
                                'Deskripsi',
                                style: TextStyle(
                                  fontFamily: 'SF Pro Text',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                description,
                                style: const TextStyle(
                                  fontFamily: 'SF Pro Text',
                                  fontSize: 14,
                                  color: Color(0xFF3A3A3C),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _statusBorderColor(status), width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontFamily: 'SF Pro Text',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _statusColor(status),
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(int reportId, String currentStatus) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _statusBorderColor(currentStatus).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentStatus,
          isDense: true,
          icon: Icon(
            Icons.arrow_drop_down_rounded,
            size: 16,
            color: _statusColor(currentStatus),
          ),
          dropdownColor: Colors.white,
          style: TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _statusColor(currentStatus),
          ),
          items: ['Dilaporkan', 'Proses', 'Selesai']
              .map(
                (val) => DropdownMenuItem<String>(value: val, child: Text(val)),
              )
              .toList(),
          onChanged: (newVal) {
            if (newVal != null && newVal != currentStatus)
              _updateReportStatus(reportId, newVal);
          },
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label) {
    // Tapping again unselects it (shows all)
    final bool isSelected = _selectedStatusFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatusFilter = isSelected ? null : label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _statusColor(label) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _statusBorderColor(label), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : _statusColor(label),
          ),
        ),
      ),
    );
  }
}
