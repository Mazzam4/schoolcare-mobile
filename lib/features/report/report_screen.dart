import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/widgets/toast_widget.dart';
import '../../core/api_config.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _isLoading = true;
  String _orgName = "Sekolahmu";
  String _userRole = "siswa";
  List<dynamic> _allReports = [];

  bool _isWaktuLaporan = true;
  String _selectedStatusFilter = "Dilaporkan";
  Set<int> _expandedReports = {};

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      _userRole = prefs.getString('userRole') ?? 'siswa';

      final dio = Dio();
      final response = await dio.get(
        "${ApiConfig.baseUrl}/api/reports",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _orgName = response.data['organizationName'] ?? "Sekolahmu";
          _allReports = response.data['reports'] ?? [];
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

      await _fetchReports();
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

  String _getDateCategory(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final reportDate = DateTime(date.year, date.month, date.day);

    if (reportDate == today) return "Laporan Hari ini";
    if (reportDate == yesterday) return "Laporan Kemarin";
    String d = date.day.toString().padLeft(2, '0');
    String m = date.month.toString().padLeft(2, '0');
    return "Laporan Tanggal $d/$m/${date.year}";
  }

  // Warna & label status
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
    Map<String, List<dynamic>> groupedReports = {};
    List<dynamic> filteredByStatus = [];

    if (_isWaktuLaporan) {
      for (var report in _allReports) {
        DateTime date = DateTime.parse(report['createdAt']).toLocal();
        String category = _getDateCategory(date);
        if (!groupedReports.containsKey(category))
          groupedReports[category] = [];
        groupedReports[category]!.add(report);
      }
    } else {
      filteredByStatus = _allReports
          .where(
            (r) => (r['status'] ?? '').toLowerCase().contains(
              _selectedStatusFilter.toLowerCase(),
            ),
          )
          .toList();
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: RefreshIndicator(
            onRefresh: _fetchReports,
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
                      Expanded(
                        child: Text(
                          'Laporan di $_orgName',
                          style: const TextStyle(
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
                    'Disini adalah tempat laporan yang dikirim\ndari sekolah/organisasi $_orgName',
                    style: TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 13,
                      color: Color(0xFF8E8E93),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Main Tab Toggle ──
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFe0e0e0),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        _buildMainTab("Waktu Laporan", _isWaktuLaporan),
                        _buildMainTab("Status Laporan", !_isWaktuLaporan),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Status Filter ──
                  if (!_isWaktuLaporan) ...[
                    Row(
                      children: [
                        _buildStatusChip("Dilaporkan"),
                        const SizedBox(width: 8),
                        _buildStatusChip("Proses"),
                        const SizedBox(width: 8),
                        _buildStatusChip("Selesai"),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

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
                  if (!_isLoading && _allReports.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              size: 48,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada laporan.',
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

                  // ── Mode Waktu: Timeline ──
                  if (!_isLoading &&
                      _isWaktuLaporan &&
                      groupedReports.isNotEmpty)
                    ...groupedReports.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14, top: 8),
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2C2C2C),
                              ),
                            ),
                          ),
                          ...entry.value
                              .map((report) => _buildReportCard(report))
                              .toList(),
                        ],
                      );
                    }).toList(),

                  // ── Mode Status ──
                  if (!_isLoading &&
                      !_isWaktuLaporan &&
                      filteredByStatus.isNotEmpty)
                    ...filteredByStatus
                        .map((report) => _buildReportCard(report))
                        .toList(),

                  if (!_isLoading &&
                      !_isWaktuLaporan &&
                      filteredByStatus.isEmpty &&
                      _allReports.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Center(
                        child: Text(
                          'Tidak ada laporan "$_selectedStatusFilter".',
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
            // ── Row Utama (selalu tampil) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon type
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
                      // Chevron
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

                  // ── Footer row: pengirim + status ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 24,
                            decoration: BoxDecoration(
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
                            sender,
                            style: const TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF1d1d1f),
                            ),
                          ),
                        ],
                      ),

                      // Status — dropdown untuk guru saat expanded, badge untuk siswa
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
                              // ── Foto + Maps berdampingan ──
                              if (base64Photo != null &&
                                      base64Photo.isNotEmpty ||
                                  (lat != null && lng != null))
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Foto bukti
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

                                    // Static maps
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
                                                )) {
                                                  await launchUrl(
                                                    Uri.parse(url),
                                                    mode: LaunchMode
                                                        .externalApplication,
                                                  );
                                                }
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
                                                    // Tap overlay hint
                                                    Positioned(
                                                      bottom: 6,
                                                      right: 6,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.black
                                                              .withOpacity(
                                                                0.55,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: const Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .open_in_new_rounded,
                                                              size: 10,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                            SizedBox(width: 3),
                                                            Text(
                                                              'Buka',
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    'SF Pro Text',
                                                                fontSize: 10,
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
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

                              // Jika hanya ada satu dari keduanya, tambah jarak
                              if (base64Photo != null &&
                                      base64Photo.isNotEmpty ||
                                  (lat != null && lng != null))
                                const SizedBox(height: 14),

                              // ── Deskripsi ──
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

  // ── Status badge (siswa) ──
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

  // ── Status dropdown (guru, saat expanded) ──
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
          items: ['Dilaporkan', 'Proses', 'Selesai'].map((val) {
            return DropdownMenuItem<String>(value: val, child: Text(val));
          }).toList(),
          onChanged: (newVal) {
            if (newVal != null && newVal != currentStatus)
              _updateReportStatus(reportId, newVal);
          },
        ),
      ),
    );
  }

  Widget _buildMainTab(String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isWaktuLaporan = label == "Waktu Laporan"),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF3d3d3d) : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? const Color(0xFFf5f5f7)
                  : const Color(0xFF949494),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label) {
    final bool isSelected = _selectedStatusFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatusFilter = label),
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
