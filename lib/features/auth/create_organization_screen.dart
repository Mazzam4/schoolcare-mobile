import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_care/core/widgets/toast_widget.dart';
import '../main/main_screen.dart';
import '../../core/api_config.dart'; // Sesuaikan titik-titiknya dengan posisi foldermu

class CreateOrganizationScreen extends StatefulWidget {
  const CreateOrganizationScreen({super.key});

  @override
  State<CreateOrganizationScreen> createState() => _CreateOrganizationScreenState();
}

class _CreateOrganizationScreenState extends State<CreateOrganizationScreen> {
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  bool _isLoading = false;

  int get _wordCount {
    final text = _descController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  bool get _isDescValid => _wordCount >= 8 && _wordCount <= 12;

  @override
  void initState() {
    super.initState();
    _descController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _schoolController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _showToast({required String message, required bool isSuccess, IconData? icon}) {
    showAppToast(context, message: message, isSuccess: isSuccess, icon: icon);
  }

  Future<void> _createOrg() async {
    if (_schoolController.text.trim().isEmpty) {
      _showToast(message: 'Nama sekolah tidak boleh kosong!', isSuccess: false, icon: Icons.info_outline_rounded);
      return;
    }
    if (!_isDescValid) {
      _showToast(message: 'Deskripsi harus 8–12 kata.', isSuccess: false, icon: Icons.edit_outlined);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final dio = Dio();
      

      final response = await dio.post(
        "${ApiConfig.baseUrl}/api/org/create",
        data: {
          "name": _schoolController.text.trim(),
          "description": _descController.text.trim(),
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 201) {
        await prefs.setInt('organizationId', response.data['organization']['id']);
        await prefs.setString('userRole', 'guru');
        if (!mounted) return;
        _showToast(message: 'Organisasi berhasil dibuat!', isSuccess: true, icon: Icons.check_circle_outline_rounded);
        await Future.delayed(const Duration(milliseconds: 1200));
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      }
    } on DioException catch (e) {
      String errorMsg = 'Terjadi kesalahan jaringan';
      if (e.response?.data != null) errorMsg = e.response?.data['message'] ?? errorMsg;
      if (!mounted) return;
      _showToast(message: errorMsg, isSuccess: false, icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Warna counter kata
    Color wordCountColor = Colors.grey.shade400;
    if (_descController.text.trim().isNotEmpty) {
      if (_isDescValid) {
        wordCountColor = const Color(0xFF34C759);
      } else if (_wordCount > 12) {
        wordCountColor = const Color(0xFFFF453A);
      } else {
        wordCountColor = Colors.orange.shade400;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FE),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 30.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),

                        // Logo
                        Container(
                          width: 80,
                          height: 80,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade300, width: 1),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: SvgPicture.asset('assets/svg/LOGO.svg'),
                        ),
                        const SizedBox(height: 28),

                        const Text(
                          'Buat Organisasimu!',
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),

                        const Text(
                          'Daftarkan sekolah atau organisasimu.\nKamu akan otomatis menjadi guru.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'SF Pro Text',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Input Nama Sekolah
                        _buildTextField(controller: _schoolController, hintText: 'Nama sekolah / organisasi'),
                        const SizedBox(height: 14),

                        // Input Deskripsi — multiline
                        TextField(
                          controller: _descController,
                          maxLines: 3,
                          style: const TextStyle(fontFamily: 'SF Pro Text', fontWeight: FontWeight.w500, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Deskripsi singkat sekolahmu...',
                            hintStyle: TextStyle(fontFamily: 'SF Pro Text', color: Colors.grey.shade500, fontWeight: FontWeight.w400, fontSize: 15),
                            filled: true,
                            fillColor: const Color(0xFFC4C4C4).withOpacity(0.25),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: _isDescValid ? const Color(0xFF34C759) : const Color(0xFF0D6EFD),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Counter kata
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Minimal 8 kata, maksimal 12 kata',
                              style: TextStyle(fontFamily: 'SF Pro Text', fontSize: 11, color: Colors.black.withOpacity(0.4)),
                            ),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(fontFamily: 'SF Pro Text', fontSize: 11, fontWeight: FontWeight.w600, color: wordCountColor),
                              child: Text('$_wordCount / 12'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Badge Guru 
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC4C4C4).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade400, width: 1),
                          ),
                          child: const Text(
                            'Guru',
                            style: TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Teks bantuan di bawah badge
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text(
                              'Kamu otomatis menjadi guru saat membuat suatu organisasi,\nkamu juga bisa menambahkan orang lain jadi guru nantinya!',
                              style: TextStyle(
                                fontFamily: 'SF Pro Text',
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                color: Colors.black.withOpacity(0.5),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),
                        const SizedBox(height: 30),

                        // Tombol Continue
                        ElevatedButton(
                          onPressed: _isLoading ? null : _createOrg,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D6EFD),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFF0D6EFD).withOpacity(0.6),
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : const Text('Continue', style: TextStyle(fontFamily: 'SF Pro Display', fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.2)),
                        ),
                        const SizedBox(height: 12),

                        // Tombol Organisasi Lain
                        OutlinedButton(
                          onPressed: _isLoading ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            minimumSize: const Size(double.infinity, 52),
                            side: BorderSide(color: Colors.grey.shade300, width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                            elevation: 0,
                          ),
                          child: const Text('Organisasi Lain', style: TextStyle(fontFamily: 'SF Pro Display', fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 24),
                      ],
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

  Widget _buildTextField({required TextEditingController controller, required String hintText}) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontFamily: 'SF Pro Text', fontWeight: FontWeight.w500, fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(fontFamily: 'SF Pro Text', color: Colors.grey.shade500, fontWeight: FontWeight.w400, fontSize: 15),
        filled: true,
        fillColor: const Color(0xFFC4C4C4).withOpacity(0.25),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade400, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF0D6EFD), width: 1.5)),
      ),
    );
  }
}