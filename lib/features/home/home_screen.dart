import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/widgets/toast_widget.dart';
import '../report/create_report_modal.dart';
import '../members/members_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_config.dart'; // Sesuaikan titik-titiknya dengan posisi foldermu

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  String _orgName = "Sekolahmu";
  String _orgDesc = "Menjaga Fasilitas dan Kebersihan Bersama!";
  String _userRole = "siswa";

  int _totalMembers = 0;
  Map<String, dynamic> _stats = {"total7Days": 0, "proses": 0, "selesai": 0};
  Map<String, dynamic> _pieChart = {"fasilitas": 0, "kebersihan": 0};
  List<dynamic> _barChart = [];
  List<dynamic> _todaysReports = [];

  Set<int> _expandedReports = {};
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // ── Apple Design System Colors ──
  static const Color _bg = Color(0xFFF5F5F7); // Apple Parchment
  static const Color _surface = Colors.white;
  static const Color _label = Color(0xFF1D1D1F); // Near-black ink
  static const Color _secondaryLabel = Color(0xFF8E8E93);
  static const Color _tertiaryLabel = Color(0xFFC7C7CC);
  static const Color _separator = Color(0xFFE5E5EA);
  static const Color _blue = Color(0xFF0066CC); // Action Blue
  static const Color _green = Color(0xFF34C759);
  static const Color _orange = Color(0xFFFF9500);
  static const Color _red = Color(0xFFFF3B30);
  static const Color _indigo = Color(0xFF5856D6);
  static const Color _darkTile = Color(0xFF272729); // Near-Black Tile 1
  static const Color _hairline = Color(0xFFE0E0E0);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fetchDashboardData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      _userRole = prefs.getString('userRole') ?? 'siswa';

      final dio = Dio();

      final response = await dio.get(
        "${ApiConfig.baseUrl}/api/dashboard",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _orgName = response.data['organizationName'] ?? "Sekolahmu";
          _orgDesc =
              response.data['organizationDesc'] ??
              "Menjaga Fasilitas dan Kebersihan Bersama!";
          _totalMembers = response.data['totalMembers'] ?? 0;
          _stats = response.data['stats'] ?? {};
          _pieChart = response.data['pieChart'] ?? {};
          _barChart = response.data['barChart'] ?? [];
          _todaysReports = response.data['todaysReports'] ?? [];
        });
        _fadeController.forward(from: 0);
      }
    } catch (e) {
      debugPrint("Error dashboard: $e");
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

      await _fetchDashboardData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: RefreshIndicator(
              onRefresh: _fetchDashboardData,
              color: _blue,
              strokeWidth: 2,
              child: _isLoading ? _buildLoadingState() : _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  // ── Loading State ──
  Widget _buildLoadingState() {
    return const CustomScrollView(
      slivers: [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: _blue,
                    strokeWidth: 2.5,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Memuat data...',
                  style: TextStyle(
                    fontSize: 14,
                    color: _secondaryLabel,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Main Content ──
  Widget _buildContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // ── Large Title Header ──
          SliverToBoxAdapter(child: _buildHeader()),

          // ── Spacing antara header dan member card ──
          const SliverToBoxAdapter(child: SizedBox(height: 30)),

          // ── Hero Member Card ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildMemberHeroCard(),
            ),
          ),

          // ── Stats Section Label ──
          SliverToBoxAdapter(child: _buildSectionLabel('Ringkasan 7 Hari')),

          // ── Stats Cards ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildStatsRow(),
            ),
          ),

          // ── Charts Section ──
          SliverToBoxAdapter(child: _buildSectionLabel('Analitik Laporan')),

          // ── Pie Chart Card ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildPieChartCard(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Bar Chart Card ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildBarChartCard(),
            ),
          ),

          // ── Today's Reports ──
          SliverToBoxAdapter(child: _buildTodayReportsHeader()),

          // ── Reports List ──
          if (_todaysReports.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyState())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildReportCard(_todaysReports[index]),
                ),
                childCount: _todaysReports.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }

  // ── Header dengan Large Title style iOS ──
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_bg, _surface],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: const Border(bottom: BorderSide(color: _hairline)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard $_orgName',
                  style: const TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: _label,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _orgDesc,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: _secondaryLabel,
                    letterSpacing: -0.1,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildNotificationButton(),
        ],
      ),
    );
  }

  Widget _buildNotificationButton() {
    return _AnimatedPressScale(
      onTap: () {},
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _surface,
          shape: BoxShape.circle,
          border: Border.all(color: _hairline),
        ),
        child: const Icon(
          Icons.notifications_none_rounded,
          size: 20,
          color: _label,
        ),
      ),
    );
  }

  // ── Section Label ──
  Widget _buildSectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _secondaryLabel,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ── Hero Member Card (Apple Premium Dark Tile) ──
  Widget _buildMemberHeroCard() {
    return Container(
      decoration: BoxDecoration(
        color: _darkTile,
        borderRadius: BorderRadius.circular(18), // rounded.lg (18px)
      ),
      child: Stack(
        children: [
          // ── Beautiful Apple-style structural lighting ──
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.02),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.people_alt_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'KOMUNITAS SEKOLAH',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white60,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Total Anggota',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$_totalMembers',
                      style: const TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 64,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 0.95,
                        letterSpacing: -2.5,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10, left: 8),
                      child: Text(
                        'orang di sekolahmu!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.white54,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // ── CTA Button berbentuk Pill Putih Premium ──
                _AnimatedPressScale(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MembersScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9999), // rounded.pill
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Lihat semua di $_orgName',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _label,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: _label,
                          size: 12,
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
    );
  }

  // ── Stats Row ──
  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard(
          'Total Laporan',
          _stats["total7Days"] ?? 0,
          Icons.insert_drive_file_outlined,
          _indigo,
        ),
        const SizedBox(width: 10),
        _buildStatCard(
          'Proses',
          _stats["proses"] ?? 0,
          Icons.arrow_circle_right_outlined,
          _orange,
        ),
        const SizedBox(width: 10),
        _buildStatCard(
          'Selesai',
          _stats["selesai"] ?? 0,
          Icons.check_circle_outline_rounded,
          _green,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18), // rounded.lg
          border: Border.all(color: _hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: accent),
            ),
            const SizedBox(height: 12),
            Text(
              '$count',
              style: const TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: _label,
                letterSpacing: -0.8,
                height: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: _secondaryLabel,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pie Chart Card ──
  Widget _buildPieChartCard() {
    final int total =
        (_pieChart["fasilitas"] ?? 0) + (_pieChart["kebersihan"] ?? 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18), // rounded.lg
        border: Border.all(color: _hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribusi Jenis Laporan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _label,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Fasilitas Rusak vs Kebersihan',
            style: TextStyle(
              fontSize: 12,
              color: _secondaryLabel,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Donut Chart
              SizedBox(
                width: 120,
                height: 120,
                child: total == 0
                    ? _buildEmptyPieState()
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 4,
                              centerSpaceRadius: 38,
                              sections: _buildPieChartSections(),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$total',
                                style: const TextStyle(
                                  fontFamily: 'SF Pro Display',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: _label,
                                  letterSpacing: -0.5,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'laporan',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _secondaryLabel,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: 28),
              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendTile(
                      'Fasilitas Rusak',
                      _pieChart["fasilitas"] ?? 0,
                      const Color(0xFF5856D6), // Apple Indigo
                    ),
                    const SizedBox(height: 16),
                    _buildLegendTile(
                      'Kebersihan',
                      _pieChart["kebersihan"] ?? 0,
                      const Color(0xFFFFCC00), // Apple Gold
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPieState() {
    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle, color: _bg),
      child: const Center(
        child: Text(
          'Kosong',
          style: TextStyle(fontSize: 11, color: _secondaryLabel),
        ),
      ),
    );
  }

  Widget _buildLegendTile(String label, int value, Color color) {
    final int total =
        (_pieChart["fasilitas"] ?? 0) + (_pieChart["kebersihan"] ?? 0);
    final String percent = total == 0
        ? '0%'
        : '${((value / total) * 100).toStringAsFixed(0)}%';

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: _secondaryLabel,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Row(
                children: [
                  Text(
                    '$value laporan',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _label,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      percent,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color,
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

  // ── Bar Chart Card ──
  Widget _buildBarChartCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
      decoration: BoxDecoration(
        color: _darkTile,
        borderRadius: BorderRadius.circular(18), // rounded.lg
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tren Laporan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '7 hari terakhir',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white54,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxBarY(),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: _getLeftAxisInterval(),
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value >= 0 && value < _barChart.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _barChart[value.toInt()]['day'],
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withOpacity(0.06),
                    strokeWidth: 1,
                  ),
                ),
                barGroups: _buildBarGroups(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBorderRadius: BorderRadius.circular(10),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toInt()} laporan',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxBarY() {
    if (_barChart.isEmpty) return 10;
    double max = 5;
    for (var item in _barChart) {
      final val = (item['count'] ?? 0).toDouble();
      if (val > max) max = val;
    }
    return (max * 1.3).ceilToDouble();
  }

  double _getLeftAxisInterval() {
    final max = _getMaxBarY();
    if (max <= 5) return 1;
    if (max <= 10) return 2;
    return (max / 5).ceilToDouble();
  }

  // ── Today's Reports Header ──
  Widget _buildTodayReportsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'LAPORAN HARI INI',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _secondaryLabel,
                letterSpacing: 0.8,
              ),
            ),
          ),
          // ── Create Report Button (Apple Action Blue Pill) ──
          _AnimatedPressScale(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const CreateReportModal(),
              ).then((_) => _fetchDashboardData());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _blue,
                borderRadius: BorderRadius.circular(9999), // rounded.pill
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Buat Laporan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State ──
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _hairline),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: _bg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_rounded,
                size: 26,
                color: _secondaryLabel,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak ada laporan hari ini',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _label,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Laporan yang dibuat hari ini akan muncul di sini',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: _secondaryLabel,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Report Card ──
  Widget _buildReportCard(dynamic report) {
    final int id = report['id'];
    final bool isExpanded = _expandedReports.contains(id);
    final String category = report['category'] ?? 'Laporan';
    final String location = report['location'] ?? '-';
    final String sender = report['author']?['firstName'] ?? '-';
    final String status = report['status'] ?? 'Dilaporkan';
    final String description = report['description'] ?? '-';
    final String? base64Photo = report['photoBase64'];
    final double? lat = (report['latitude'] as num?)?.toDouble();
    final double? lng = (report['longitude'] as num?)?.toDouble();
    final bool isGuru = _userRole.toLowerCase() == 'guru';
    final bool isKebersihan = (report['type'] ?? '')
        .toString()
        .toLowerCase()
        .contains('kebersihan');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18), // rounded.lg
        border: Border.all(color: _hairline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AnimatedPressScale(
              onTap: () => _toggleExpand(id),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // ── Icon dengan Latar Belakang Sangat Lembut ──
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isKebersihan
                            ? _orange.withOpacity(0.08)
                            : _indigo.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isKebersihan
                            ? Icons.cleaning_services_rounded
                            : Icons.build_rounded,
                        size: 18,
                        color: isKebersihan ? _orange : _indigo,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // ── Title & Location ──
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _label,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 11,
                                color: _secondaryLabel,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  location,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _secondaryLabel,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ── Status Badge + Chevron ──
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildStatusBadge(status),
                        const SizedBox(height: 6),
                        AnimatedRotation(
                          turns: isExpanded ? 0.25 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: _secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Sender row ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: _bg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 12,
                      color: _secondaryLabel,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    sender,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _secondaryLabel,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.1,
                    ),
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
                        Container(height: 1, color: _hairline),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Photo dengan Shadow Lembut khas Apple ──
                              if (base64Photo != null &&
                                  base64Photo.isNotEmpty) ...[
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
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.12),
                                        blurRadius: 18,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      base64Decode(base64Photo),
                                      width: double.infinity,
                                      height: 180,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // ── Peta Statis Geoapify (GPS) ──
                              if (lat != null && lng != null) ...[
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
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.12),
                                        blurRadius: 18,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Stack(
                                      children: [
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
                                          child: Image.network(
                                            'https://maps.geoapify.com/v1/staticmap?style=osm-carto&width=400&height=260&center=lonlat:$lng,$lat&zoom=16&marker=lonlat:$lng,$lat;color:%23ff0000;size:medium&apiKey=caa5e20481224996ab88f0837cdba468',
                                            width: double.infinity,
                                            height: 180,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                                  height: 180,
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
                                                      const Icon(
                                                        Icons.map_outlined,
                                                        size: 32,
                                                        color: _secondaryLabel,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'Buka Maps',
                                                        style: TextStyle(
                                                          fontFamily:
                                                              'SF Pro Text',
                                                          fontSize: 12,
                                                          color: Colors
                                                              .grey
                                                              .shade500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                          ),
                                        ),
                                        // Tap overlay hint
                                        Positioned(
                                          bottom: 10,
                                          right: 10,
                                          child: IgnorePointer(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(
                                                  0.6,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.open_in_new_rounded,
                                                    size: 11,
                                                    color: Colors.white,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Buka',
                                                    style: TextStyle(
                                                      fontFamily: 'SF Pro Text',
                                                      fontSize: 11,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // ── Description ──
                              const Text(
                                'DESKRIPSI LAPORAN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _secondaryLabel,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: _label,
                                  height: 1.5,
                                  letterSpacing: -0.1,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),

                              // ── Status Update (Guru) ──
                              if (isGuru) ...[
                                const SizedBox(height: 16),
                                Container(height: 1, color: _hairline),
                                const SizedBox(height: 14),
                                const Text(
                                  'PERBARUI STATUS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _secondaryLabel,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: ['Dilaporkan', 'Proses', 'Selesai']
                                      .map((s) {
                                        final isActive = status == s;
                                        final color = _getStatusColor(s);
                                        return Expanded(
                                          child: _AnimatedPressScale(
                                            onTap: () {
                                              if (!isActive) {
                                                _updateReportStatus(id, s);
                                              }
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              margin: EdgeInsets.only(
                                                right: s != 'Selesai' ? 8 : 0,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 9,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isActive
                                                    ? color
                                                    : color.withOpacity(0.08),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                s,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: isActive
                                                      ? Colors.white
                                                      : color,
                                                  letterSpacing: -0.2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      })
                                      .toList(),
                                ),
                              ],
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
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return _green;
      case 'proses':
        return _orange;
      default:
        return _red;
    }
  }

  // ── Chart Helpers ──
  List<PieChartSectionData> _buildPieChartSections() {
    int total = (_pieChart["fasilitas"] ?? 0) + (_pieChart["kebersihan"] ?? 0);
    if (total == 0) return [];

    double fasPercent = ((_pieChart["fasilitas"] ?? 0) / total) * 100;
    double kebPercent = ((_pieChart["kebersihan"] ?? 0) / total) * 100;

    return [
      PieChartSectionData(
        color: const Color(0xFF5856D6),
        value: fasPercent,
        title: '',
        radius: 16,
      ),
      PieChartSectionData(
        color: const Color(0xFFFFCC00),
        value: kebPercent,
        title: '',
        radius: 16,
      ),
    ];
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(_barChart.length, (i) {
      final double val = (_barChart[i]['count'] ?? 0).toDouble();
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: val,
            gradient: const LinearGradient(
              colors: [_blue, _indigo],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _getMaxBarY(),
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ],
      );
    });
  }
}

// ── Custom Interactive Scale-on-Press Widget ──
class _AnimatedPressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _AnimatedPressScale({required this.child, required this.onTap});

  @override
  State<_AnimatedPressScale> createState() => _AnimatedPressScaleState();
}

class _AnimatedPressScaleState extends State<_AnimatedPressScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
    )..value = 1.0;
    _scaleAnimation = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.reverse();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.forward();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
