import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../auth/login_screen.dart';
import '../auth/join_school_screen.dart';
import '../../core/widgets/toast_widget.dart';
import '../members/members_screen.dart';
import '../../core/api_config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _firstName = "";
  String _lastName = "";
  String _email = "";
  String _role = "";
  Uint8List? _profileImageBytes;
  bool _isNotifOn = false;

  // Expand state untuk dropdown
  bool _expandName = false;
  bool _expandPassword = false;

  // Controller untuk form inline
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _oldPassCtrl = TextEditingController();
  final TextEditingController _newPassCtrl = TextEditingController();

  bool _isLoadingName = false;
  bool _isLoadingPass = false;
  bool _obscureOld = true;
  bool _obscureNew = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? base64Image = prefs.getString('profile_image_base64');
    Uint8List? loadedImage;
    if (base64Image != null && base64Image.isNotEmpty) {
      loadedImage = base64Decode(base64Image);
    }
    setState(() {
      _firstName = prefs.getString('userFirstName') ?? "User";
      _lastName = prefs.getString('userLastName') ?? "";
      _email = prefs.getString('userEmail') ?? "email@belum.ada";
      _role = prefs.getString('userRole') ?? "siswa";
      _profileImageBytes = loadedImage;
      _firstNameCtrl.text = _firstName;
      _lastNameCtrl.text = _lastName;
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 25);
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      final String base64String = base64Encode(bytes);
      
      // Simpan di lokal (agar langsung berubah di layar)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_base64', base64String);

      setState(() {
        _profileImageBytes = bytes;
      });

      // --- KODE BARU: KIRIM FOTO KE DATABASE NODE.JS ---
      try {
        final token = prefs.getString('jwt_token');
        final dio = Dio();
        

        await dio.put(
          "${ApiConfig.baseUrl}/api/user/update",
          data: { "profileImage": base64String },
          options: Options(headers: {"Authorization": "Bearer $token"}),
        );
        print("Foto profil berhasil di-upload ke server!");
      } catch (e) {
        print("Gagal upload foto ke server: $e");
      }
    }
  }

  Future<void> _saveName() async {
    if (_firstNameCtrl.text.trim().isEmpty) {
      showAppToast(context, message: 'Nama depan tidak boleh kosong', isSuccess: false, icon: Icons.info_outline_rounded);
      return;
    }
    setState(() => _isLoadingName = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final dio = Dio();
      
      final response = await dio.put(
        "${ApiConfig.baseUrl}/api/user/update",
        data: {"firstName": _firstNameCtrl.text, "lastName": _lastNameCtrl.text},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (response.statusCode == 200) {
        await prefs.setString('userFirstName', _firstNameCtrl.text);
        await prefs.setString('userLastName', _lastNameCtrl.text);
        setState(() {
          _firstName = _firstNameCtrl.text;
          _lastName = _lastNameCtrl.text;
          _expandName = false;
        });
        if (!mounted) return;
        showAppToast(context, message: 'Nama berhasil diperbarui!', isSuccess: true, icon: Icons.check_circle_outline_rounded);
      }
    } on DioException catch (e) {
      String errorMsg = e.response?.data['message'] ?? 'Terjadi kesalahan jaringan';
      if (!mounted) return;
      showAppToast(context, message: errorMsg, isSuccess: false, icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _isLoadingName = false);
    }
  }

  Future<void> _savePassword() async {
    if (_oldPassCtrl.text.isEmpty || _newPassCtrl.text.isEmpty) {
      showAppToast(context, message: 'Harap isi semua field password', isSuccess: false, icon: Icons.lock_outline_rounded);
      return;
    }
    setState(() => _isLoadingPass = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final dio = Dio();
      
      final response = await dio.put(
        "${ApiConfig.baseUrl}/api/user/update",
        data: {"oldPassword": _oldPassCtrl.text, "newPassword": _newPassCtrl.text},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (response.statusCode == 200) {
        _oldPassCtrl.clear();
        _newPassCtrl.clear();
        setState(() => _expandPassword = false);
        if (!mounted) return;
        showAppToast(context, message: 'Password berhasil diperbarui!', isSuccess: true, icon: Icons.check_circle_outline_rounded);
      }
    } on DioException catch (e) {
      String errorMsg = e.response?.data['message'] ?? 'Terjadi kesalahan jaringan';
      if (!mounted) return;
      showAppToast(context, message: errorMsg, isSuccess: false, icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _isLoadingPass = false);
    }
  }

  // Pop up iOS-style — Sign Out
  void _confirmSignOut() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (context) => _IosDialog(
        title: 'Sign Out',
        message: 'Kamu akan keluar dari akun ini.',
        confirmLabel: 'Sign Out',
        isDestructive: true,
        onConfirm: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        },
      ),
    );
  }

  // Pop up iOS-style — Ganti Sekolah
  void _confirmChangeSchool() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (context) => _IosDialog(
        title: 'Ganti Sekolah',
        message: 'Sekolah barumu akan menggantikan yang sekarang.',
        confirmLabel: 'Ya, Ganti',
        isDestructive: false,
        onConfirm: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('organizationId');
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const JoinSchoolScreen()),
            (route) => false,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGuru = _role.toLowerCase() == 'guru';
    final fullName = '$_firstName $_lastName'.trim();

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  // ── Avatar ──
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFE5E5EA),
                            image: _profileImageBytes != null
                                ? DecorationImage(image: MemoryImage(_profileImageBytes!), fit: BoxFit.cover)
                                : null,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
                          ),
                          child: _profileImageBytes == null
                              ? const Icon(Icons.person_rounded, size: 48, color: Color(0xFFAEAEB2))
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    fullName.isEmpty ? 'Nama Pengguna' : fullName,
                    style: const TextStyle(fontFamily: 'SF Pro Display', fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF1d1d1f)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _email,
                    style: const TextStyle(fontFamily: 'SF Pro Text', fontSize: 14, color: Color(0xFF8E8E93)),
                  ),
                  const SizedBox(height: 14),

                  // ── Role Badge ──
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
                    decoration: BoxDecoration(
                      color: isGuru ? const Color(0xFF498D4A) : const Color(0xFF0071E3),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      isGuru ? 'Guru di Sekolah ini' : 'Siswa di Sekolah ini',
                      style: TextStyle(
                        fontFamily: 'SF Pro Text',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isGuru ? const Color.fromARGB(255, 255, 255, 255) : const Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // ── Section: Informasi ──
                  _sectionLabel('Informasi'),
                  const SizedBox(height: 10),
                  _card(children: [
                    _rowItem(
                      icon: Icons.notifications_none_rounded,
                      label: 'Notifikasi',
                      trailing: Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: _isNotifOn,
                          activeColor: const Color(0xFF34C759),
                          onChanged: (val) => setState(() => _isNotifOn = val),
                        ),
                      ),
                    ),
                    _divider(),
                    _rowItem(
                      icon: Icons.people_outline_rounded,
                      label: 'Anggota di sekolahmu',
                      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFC7C7CC)),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MembersScreen(),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 28),

                  // ── Section: Account Details ──
                  _sectionLabel('Account Details'),
                  const SizedBox(height: 10),
                  _card(children: [

                    // ── Dropdown: Ganti Nama ──
                    _rowItem(
                      icon: Icons.person_outline_rounded,
                      label: 'Ganti Nama',
                      trailing: AnimatedRotation(
                        turns: _expandName ? 0.25 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: const Icon(Icons.chevron_right_rounded, color: Color(0xFFC7C7CC)),
                      ),
                      onTap: () => setState(() {
                        _expandName = !_expandName;
                        if (_expandPassword) _expandPassword = false;
                      }),
                    ),

                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 280),
                      crossFadeState: _expandName ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
                        child: Column(
                          children: [
                            const SizedBox(height: 4),
                            _inlineField(controller: _firstNameCtrl, hint: 'First Name'),
                            const SizedBox(height: 10),
                            _inlineField(controller: _lastNameCtrl, hint: 'Last Name'),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton(
                                onPressed: _isLoadingName ? null : _saveName,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF3E3E3E),
                                  disabledBackgroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  elevation: 0,
                                  overlayColor: const Color(0x80BABABA),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: const BorderSide(
                                      color: Color(0xFF838383),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: _isLoadingName
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF454545),
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Simpan Perubahan',
                                        style: TextStyle(
                                          fontFamily: 'SF Pro Text',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF3E3E3E),
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    _divider(),

                    // ── Dropdown: Ganti Password ──
                    _rowItem(
                      icon: Icons.lock_outline_rounded,
                      label: 'Ubah Password',
                      trailing: AnimatedRotation(
                        turns: _expandPassword ? 0.25 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: const Icon(Icons.chevron_right_rounded, color: Color(0xFFC7C7CC)),
                      ),
                      onTap: () => setState(() {
                        _expandPassword = !_expandPassword;
                        if (_expandName) _expandName = false;
                      }),
                    ),

                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 280),
                      crossFadeState: _expandPassword ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
                        child: Column(
                          children: [
                            const SizedBox(height: 4),
                            _inlineField(controller: _oldPassCtrl, hint: 'Password Lama', obscure: _obscureOld, onToggle: () => setState(() => _obscureOld = !_obscureOld)),
                            const SizedBox(height: 10),
                            _inlineField(controller: _newPassCtrl, hint: 'Password Baru', obscure: _obscureNew, onToggle: () => setState(() => _obscureNew = !_obscureNew)),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton(
                                onPressed: _isLoadingPass ? null : _savePassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF3E3E3E),
                                  disabledBackgroundColor: Colors.white,
                                  disabledForegroundColor: const Color(0xFF3E3E3E),
                                  shadowColor: Colors.transparent,
                                  elevation: 0,
                                  overlayColor: const Color(0x80bababa), 
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: const BorderSide(
                                      color: Color(0xFF838383),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: _isLoadingPass
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF454545),
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Simpan Perubahan',
                                        style: TextStyle(
                                          fontFamily: 'SF Pro Text',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF3E3E3E),
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    _divider(),
                    _rowItem(
                      icon: Icons.school_outlined,
                      label: 'Ganti Sekolah',
                      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFC7C7CC)),
                      onTap: _confirmChangeSchool,
                    ),
                    _divider(),
                    _rowItem(
                      icon: Icons.logout_rounded,
                      label: 'Sign Out',
                      labelColor: const Color(0xFFFF3B30),
                      iconColor: const Color(0xFFFF3B30),
                      trailing: const SizedBox.shrink(),
                      onTap: _confirmSignOut,
                    ),
                  ]),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──

  Widget _sectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(fontFamily: 'SF Pro Display', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF8E8E93), letterSpacing: 0.4),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() => Divider(height: 1, thickness: 1, color: const Color(0xFFF2F2F7), indent: 56);

  Widget _rowItem({
    required IconData icon,
    required String label,
    required Widget trailing,
    VoidCallback? onTap,
    Color labelColor = const Color(0xFF1C1C1E),
    Color iconColor = const Color(0xFF8E8E93),
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: TextStyle(fontFamily: 'SF Pro Text', fontSize: 15, fontWeight: FontWeight.w500, color: labelColor)),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _inlineField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    VoidCallback? onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontFamily: 'SF Pro Text', fontWeight: FontWeight.w500, fontSize: 14, color: Color(0xFF1d1d1f)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: 'SF Pro Text', color: Color(0xFFAEAEB2), fontWeight: FontWeight.w400, fontSize: 14),
        filled: true,
        fillColor: const Color.fromARGB(255, 240, 235, 235),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        suffixIcon: onToggle != null
            ? GestureDetector(
                onTap: onToggle,
                child: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFFAEAEB2), size: 18),
              )
            : null,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color.fromARGB(255, 192, 192, 192), width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color.fromARGB(255, 114, 114, 114), width: 1.5)),
      ),
    );
  }
}

// ✅ Pop up dialog iOS-style
class _IosDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final bool isDestructive;
  final VoidCallback onConfirm;

  const _IosDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.isDestructive,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        // Menambahkan constraints maxWidth agar dialog konsisten ukurannya (tidak memanjang di web/desktop)
        constraints: const BoxConstraints(maxWidth: 420),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'SF Pro Display', fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1D1D1F)),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'SF Pro Text', fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFF1D1D1F), height: 1.4),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, thickness: 1, color: Color(0xFFE5E5EA)),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      // Batal
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20))),
                          ),
                          child: const Text('Batal', style: TextStyle(fontFamily: 'SF Pro Text', fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFF1D1D1F))),
                        ),
                      ),
                      const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE5E5EA)),
                      // Konfirmasi
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onConfirm();
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(bottomRight: Radius.circular(20))),
                          ),
                          child: Text(
                            confirmLabel,
                            style: TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDestructive ? const Color(0xFFFF3B30) : const Color(0xFF1D1D1F),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}