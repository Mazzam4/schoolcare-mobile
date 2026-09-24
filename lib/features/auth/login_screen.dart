import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'register_screen.dart';
import 'join_school_screen.dart';
import '../main/main_screen.dart';
import '../../core/api_config.dart'; // Sesuaikan titik-titiknya dengan posisi foldermu

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true; // Untuk toggle show/hide password

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Custom snackbar iOS-style (Sama seperti Register)
  void _showToast({required String message, required bool isSuccess, IconData? icon}) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        isSuccess: isSuccess,
        icon: icon,
      ),
    );
    overlay.insert(overlayEntry);
    Future.delayed(const Duration(milliseconds: 2800), () {
      overlayEntry.remove();
    });
  }

  // Fungsi Tembak API Login & Simpan Token
  Future<void> _loginAndSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dio = Dio();
      
      final String apiUrl = "${ApiConfig.baseUrl}/api/auth/login";

      final response = await dio.post(apiUrl, data: {
        "email": _emailController.text,
        "password": _passwordController.text,
      });

      if (response.statusCode == 200) {
        // Ambil token dan data user dari respons Node.js
        final token = response.data['token'];
        final user = response.data['user'];

        // Simpan ke Shared Preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('jwt_token', token); // SIMPAN TOKEN
        await prefs.setString('userEmail', user['email']);
        await prefs.setString('userRole', user['role']);
        await prefs.setString('userFirstName', user['firstName']);
        await prefs.setString('userLastName', user['lastName']);
        
        // Simpan ID organisasi jika ada (0 berarti belum masuk organisasi)
        await prefs.setInt('organizationId', user['organizationId'] ?? 0);

        if (!mounted) return;
        _showToast(
          message: 'Login berhasil!',
          isSuccess: true,
          icon: Icons.check_circle_outline_rounded,
        );

        // Tunggu animasi toast selesai sebelum pindah halaman
        await Future.delayed(const Duration(milliseconds: 1200));

        if (!mounted) return;

        if (user['organizationId'] == null) {
          // Kalau belum punya sekolah, arahkan ke halaman Join School
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const JoinSchoolScreen()),
          );
        } else {
          // Kalau SUDAH punya sekolah, langsung ke BERANDA (MainScreen)
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false, // Hapus riwayat halaman sebelumnya agar tidak bisa di-back
          );
        }
      }
    } on DioException catch (e) {
      String errorMsg = 'Terjadi kesalahan jaringan';
      if (e.response != null && e.response?.data != null) {
        errorMsg = e.response?.data['message'] ?? errorMsg;
      }
      if (!mounted) return;
      _showToast(
        message: errorMsg,
        isSuccess: false,
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FE),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 30.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children:[
                    const SizedBox(height: 20),

                    // Logo SVG
                    Container(
                      width: 80,
                      height: 80,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                        boxShadow:[
                          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: SvgPicture.asset('assets/svg/LOGO.svg'),
                    ),
                    const SizedBox(height: 28),

                    const Text(
                      'Sign in dengan email',
                      style: TextStyle(fontFamily: 'SF Pro Display', fontSize: 26, fontWeight: FontWeight.w700, color: Colors.black87, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 10),

                    const Text(
                      'Masukkan email Anda untuk masuk\ndengan akun yang sudah ada atau\nbuat akun baru.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'SF Pro Text', fontSize: 14, fontWeight: FontWeight.w400, color: Colors.black54, height: 1.5),
                    ),
                    const SizedBox(height: 36),

                    // Input E-mail
                    _buildTextField(
                      controller: _emailController,
                      hintText: 'E-mail',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'E-mail tidak boleh kosong!';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Masukkan format E-mail yang valid!';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Input Password dengan Toggle
                    _buildPasswordField(),
                    const SizedBox(height: 6),

                    // Buat Akun Baru
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                        },
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const[
                            Text('Buat Akun Baru', style: TextStyle(fontFamily: 'SF Pro Text', color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward, size: 14, color: Colors.black87),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Ilustrasi
                    SvgPicture.asset('assets/svg/peoplehugging.svg', width: 90, height: 90),
                    const SizedBox(height: 16),

                    const Text(
                      'Aplikasi ini bertujuan untuk membantu sekolah menjadi\nlingkungan yang bersih, dengan sistem lapor fasilitas\ndan kebersihan sekolah',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'SF Pro Text', fontSize: 12, fontWeight: FontWeight.w400, color: Colors.black45, height: 1.6),
                    ),
                    const SizedBox(height: 32),

                    // Tombol Continue
                    ElevatedButton(
                      onPressed: _isLoading ? null : _loginAndSave,
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

                    // Tombol Google
                    OutlinedButton(
                      onPressed: _isLoading ? null : () {},
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        minimumSize: const Size(double.infinity, 52),
                        side: BorderSide(color: Colors.grey.shade300, width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:[
                          SvgPicture.asset('assets/svg/google.svg', width: 20, height: 20),
                          const SizedBox(width: 10),
                          const Text('Dengan Google', style: TextStyle(fontFamily: 'SF Pro Display', fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontFamily: 'SF Pro Text', fontWeight: FontWeight.w500, fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(fontFamily: 'SF Pro Text', color: Colors.grey.shade500, fontWeight: FontWeight.w400, fontSize: 15),
        filled: true,
        fillColor: const Color(0xFFC4C4C4).withOpacity(0.25),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade400, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF0D6EFD), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
      ),
    );
  }

  // TextField khusus Password dengan Toggle Visibility
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Password tidak boleh kosong!';
        return null;
      },
      style: const TextStyle(fontFamily: 'SF Pro Text', fontWeight: FontWeight.w500, fontSize: 15),
      decoration: InputDecoration(
        hintText: 'Password',
        hintStyle: TextStyle(fontFamily: 'SF Pro Text', color: Colors.grey.shade500, fontWeight: FontWeight.w400, fontSize: 15),
        filled: true,
        fillColor: const Color(0xFFC4C4C4).withOpacity(0.25),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscurePassword = !_obscurePassword),
          child: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey.shade500,
            size: 20,
          ),
        ),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade400, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF0D6EFD), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
      ),
    );
  }
}

// Widget Toast Animasi
class _ToastWidget extends StatefulWidget {
  final String message;
  final bool isSuccess;
  final IconData? icon;

  const _ToastWidget({required this.message, required this.isSuccess, this.icon});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _slideAnim = Tween<double>(begin: 80, end: 0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2100), () {
      if (mounted) _ctrl.reverse();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor = const Color(0xFF1C1C1E);
    final Color accentColor = widget.isSuccess ? const Color(0xFF34C759) : const Color(0xFFFF453A);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Positioned(
          bottom: 48 + MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          child: Opacity(
            opacity: _fadeAnim.value,
            child: Transform.translate(offset: Offset(0, _slideAnim.value), child: child),
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 6))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children:[
                Icon(widget.icon ?? Icons.info_outline_rounded, color: accentColor, size: 20),
                const SizedBox(width: 10),
                Flexible(child: Text(widget.message, style: const TextStyle(fontFamily: 'SF Pro Text', fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white, height: 1.3))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}