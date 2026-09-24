import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/widgets/toast_widget.dart'; // Sesuaikan path jika berbeda
import '../../core/api_config.dart'; // Sesuaikan titik-titiknya dengan posisi foldermu

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  bool _isLoading = true;
  String _orgName = "Sekolahmu";
  String _currentUserRole = "siswa";
  String _currentUserEmail = "";

  List<dynamic> _allMembers =[];
  String _filter = "Semua"; // "Semua", "Guru", "Siswa"
  
  Set<int> _expandedMembers = {};

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      _currentUserRole = prefs.getString('userRole') ?? 'siswa';
      _currentUserEmail = prefs.getString('userEmail') ?? '';

      final dio = Dio();

      final response = await dio.get(
        "${ApiConfig.baseUrl}/api/org/members",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _orgName = response.data['organizationName'] ?? "Sekolahmu";
          _allMembers = response.data['members'] ??[];
        });
      }
    } catch (e) {
      debugPrint("Error ambil anggota: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Fungsi Tembak API "Jadikan Guru"
  Future<void> _makeTeacher(int targetUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final dio = Dio();
      
      final response = await dio.put(
        "${ApiConfig.baseUrl}/api/org/members/$targetUserId/role",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200) {
        showAppToast(context, message: 'Berhasil mengubah role menjadi Guru!', isSuccess: true, icon: Icons.check_circle_outline_rounded);
        // Refresh data setelah berhasil
        _expandedMembers.remove(targetUserId); // Tutup dropdown
        await _fetchMembers();
      }
    } catch (e) {
      showAppToast(context, message: 'Gagal mengubah role.', isSuccess: false, icon: Icons.error_outline_rounded);
    }
  }

  void _toggleExpand(int userId) {
    setState(() {
      _expandedMembers.contains(userId) ? _expandedMembers.remove(userId) : _expandedMembers.add(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filter Data Anggota
    List<dynamic> filteredMembers = _allMembers;
    if (_filter == "Guru") {
      filteredMembers = _allMembers.where((m) => m['role'].toString().toLowerCase() == 'guru').toList();
    } else if (_filter == "Siswa") {
      filteredMembers = _allMembers.where((m) => m['role'].toString().toLowerCase() == 'siswa').toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F5FE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context), // Tombol kembali ke Beranda
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                // ── HEADER ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:[
                      Expanded(
                        child: Text(
                          'Anggota DI $_orgName',
                          style: const TextStyle(fontFamily: 'SF Pro Display', fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black87),
                        ),
                      ),
                      const Icon(Icons.notifications_outlined, size: 28, color: Colors.black54),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28.0),
                  child: Text('Anggota seperti siswa, guru di dalam sekolah atau\norganisasi mu!', style: TextStyle(fontFamily: 'SF Pro Text', fontSize: 13, color: Colors.black54, height: 1.4)),
                ),
                const SizedBox(height: 24),

                // ── FILTER TABS ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(25)),
                    child: Row(
                      children:[
                        _buildFilterBtn("Semua"),
                        _buildFilterBtn("Guru"),
                        _buildFilterBtn("Siswa"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── LIST ANGGOTA ──
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.black87))
                      : RefreshIndicator(
                          onRefresh: _fetchMembers,
                          child: filteredMembers.isEmpty
                              ? const Center(child: Text("Tidak ada anggota.", style: TextStyle(color: Colors.black54)))
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 10.0),
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  itemCount: filteredMembers.length,
                                  itemBuilder: (context, index) {
                                    final member = filteredMembers[index];
                                    return _buildMemberCard(member);
                                  },
                                ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCard(dynamic member) {
    final int id = member['id'];
    final String firstName = member['firstName'] ?? '';
    final String lastName = member['lastName'] ?? '';
    final String email = member['email'] ?? '';
    final String role = member['role'] ?? 'siswa';
    final String? base64Image = member['profileImage'];
    
    final bool isMe = email == _currentUserEmail;
    final bool isGuru = role.toLowerCase() == 'guru';
    final bool isExpanded = _expandedMembers.contains(id);

    // Inisial untuk fallback jika belum ada foto
    String initials = firstName.isNotEmpty ? firstName[0].toUpperCase() : "?";

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        children:[
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            // Jika dia siswa DAN yang login adalah guru (bukan dirinya sendiri), bisa diklik
            onTap: (!isGuru && _currentUserRole == 'guru' && !isMe) ? () => _toggleExpand(id) : null,
            
            // --- KODE AVATAR YANG DIPERBARUI ---
            leading: CircleAvatar(
              backgroundColor: Colors.blueAccent.shade100,
              radius: 24,
              // Jika ada foto dari database, jadikan background
              backgroundImage: (base64Image != null && base64Image.isNotEmpty)
                  ? MemoryImage(base64Decode(base64Image))
                  : null,
              // Jika tidak ada foto, tampilkan inisial teks di tengah
              child: (base64Image == null || base64Image.isEmpty)
                  ? Text(initials, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18))
                  : null,
            ),
            // -----------------------------------

            title: Text(
              "$firstName $lastName ${isMe ? '(Anda)' : ''}",
              style: const TextStyle(fontFamily: 'SF Pro Display', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
            ),
            subtitle: Text(
              isGuru ? "Guru" : "Siswa",
              style: const TextStyle(fontFamily: 'SF Pro Text', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
            ),
            trailing: isGuru
                ? const Icon(Icons.workspace_premium_rounded, color: Colors.black87, size: 28) // Ikon Mahkota untuk Guru
                : (_currentUserRole == 'guru' && !isMe)
                    ? Icon(isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: Colors.black87)
                    : null,
          ),
          
          // Tombol Expand "Jadikan Guru" (Hanya muncul jika di-expand)
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _makeTeacher(id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A9062), 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Jadikan $firstName menjadi guru',
                    style: const TextStyle(fontFamily: 'SF Pro Text', fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterBtn(String label) {
    bool isSelected = _filter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2C2C2E) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(fontFamily: 'SF Pro Display', fontSize: 14, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Colors.black87),
          ),
        ),
      ),
    );
  }
}