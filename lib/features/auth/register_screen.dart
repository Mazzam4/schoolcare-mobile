import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'join_school_screen.dart';
import '../../core/api_config.dart'; 


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // State validasi password real-time
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _passwordTouched = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
  }

  void _validatePassword() {
    final val = _passwordController.text;
    setState(() {
      _passwordTouched = val.isNotEmpty;
      _hasMinLength = val.length >= 8;
      _hasUppercase = val.contains(RegExp(r'[A-Z]'));
      _hasLowercase = val.contains(RegExp(r'[a-z]'));
      _hasNumber = val.contains(RegExp(r'[0-9]'));
    });
  }

  bool get _isPasswordValid =>
      _hasMinLength && _hasUppercase && _hasLowercase && _hasNumber;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  // Custom snackbar iOS-style dari bawah
  void _showToast({
    required String message,
    required bool isSuccess,
    IconData? icon,
  }) {
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

  Future<void> _registerUser() async {
    // Validasi semua field
    if (_firstNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showToast(
        message: 'Harap isi semua data yang diperlukan',
        isSuccess: false,
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    if (!_isPasswordValid) {
      _showToast(
        message: 'Kata sandi belum memenuhi semua syarat',
        isSuccess: false,
        icon: Icons.lock_outline_rounded,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dio = Dio();
      final String apiUrl = "${ApiConfig.baseUrl}/api/auth/register";

      final response = await dio.post(apiUrl, data: {
        "firstName": _firstNameController.text,
        "lastName": _lastNameController.text,
        "email": _emailController.text,
        "password": _passwordController.text,
      });

      if (response.statusCode == 201) {
        if (!mounted) return;
        _showToast(
          message: 'Akun berhasil dibuat! Silakan login.',
          isSuccess: true,
          icon: Icons.check_circle_outline_rounded,
        );
        await Future.delayed(const Duration(milliseconds: 1200));
        if (!mounted) return;
        Navigator.pop(context);
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
              padding: const EdgeInsets.symmetric(
                horizontal: 28.0,
                vertical: 30.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  const Text(
                    'Membuat Akun',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    'Masukkan data diri dan email anda,\natau masuk langsung jika sudah ada akun.',
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

                  // Email
                  _buildTextField(
                    controller: _emailController,
                    hintText: 'E-mail',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),

                  // Password dengan toggle show/hide
                  _buildPasswordField(),
                  const SizedBox(height: 10),

                  // Indikator validasi password real-time
                  if (_passwordTouched) _buildPasswordRules(),
                  if (!_passwordTouched)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        'Minimal 8 karakter, huruf besar & kecil, dan satu angka.',
                        style: TextStyle(
                          fontFamily: 'SF Pro Text',
                          fontSize: 11,
                          color: Colors.black.withOpacity(0.45),
                          height: 1.4,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // First Name
                  _buildTextField(
                    controller: _firstNameController,
                    hintText: 'First Name',
                  ),
                  const SizedBox(height: 14),

                  // Last Name
                  _buildTextField(
                    controller: _lastNameController,
                    hintText: 'Last Name',
                  ),
                  const SizedBox(height: 8),

                  // Sudah Ada Akun?
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Sudah Ada Akun?',
                            style: TextStyle(
                              fontFamily: 'SF Pro Text',
                              color: Colors.black87,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 14, color: Colors.black87),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Ilustrasi
                  SvgPicture.asset(
                    'assets/svg/peoplehugging.svg',
                    width: 90,
                    height: 90,
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Aplikasi ini bertujuan untuk membantu sekolah menjadi\nlingkungan yang bersih, dengan sistem lapor fasilitas\ndan kebersihan sekolah',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.black45,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tombol Continue
                  ElevatedButton(
                    onPressed: _isLoading ? null : _registerUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6EFD),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          const Color(0xFF0D6EFD).withOpacity(0.6),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Continue',
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/svg/google.svg',
                          width: 20,
                          height: 20,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Dengan Google',
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
    );
  }

  // Password field dengan toggle show/hide
  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(
        fontFamily: 'SF Pro Text',
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: 'Password',
        hintStyle: TextStyle(
          fontFamily: 'SF Pro Text',
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w400,
          fontSize: 15,
        ),
        filled: true,
        fillColor: const Color(0xFFC4C4C4).withOpacity(0.25),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscurePassword = !_obscurePassword),
          child: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.grey.shade500,
            size: 20,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            // Border merah jika password sudah diketik tapi belum valid
            color: _passwordTouched && !_isPasswordValid
                ? Colors.red.shade300
                : Colors.grey.shade400,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: _passwordTouched && !_isPasswordValid
                ? Colors.red.shade400
                : const Color(0xFF0D6EFD),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // Indikator aturan password real-time (iOS-style checklist)
  Widget _buildPasswordRules() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
      child: Column(
        children: [
          Row(
            children: [
              _ruleItem(_hasMinLength, '8 karakter atau lebih'),
              const SizedBox(width: 12),
              _ruleItem(_hasNumber, 'Mengandung angka'),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _ruleItem(_hasUppercase, 'Huruf kapital (A-Z)'),
              const SizedBox(width: 12),
              _ruleItem(_hasLowercase, 'Huruf kecil (a-z)'),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _ruleItem(bool passed, String label) {
    return Expanded(
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              passed
                  ? Icons.check_circle_rounded
                  : Icons.circle_outlined,
              key: ValueKey(passed),
              size: 14,
              color: passed
                  ? const Color(0xFF34C759) // iOS green
                  : Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: passed ? const Color(0xFF34C759) : Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontFamily: 'SF Pro Text',
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontFamily: 'SF Pro Text',
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w400,
          fontSize: 15,
        ),
        filled: true,
        fillColor: const Color(0xFFC4C4C4).withOpacity(0.25),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF0D6EFD), width: 1.5),
        ),
      ),
    );
  }
}

// ✅ Custom Toast Widget — iOS-style dari bawah
class _ToastWidget extends StatefulWidget {
  final String message;
  final bool isSuccess;
  final IconData? icon;

  const _ToastWidget({
    required this.message,
    required this.isSuccess,
    this.icon,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideAnim = Tween<double>(begin: 80, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();

    // Mulai fade out sebelum dihapus
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
    final Color bgColor = widget.isSuccess
        ? const Color(0xFF1C1C1E)   // Dark pill — iOS style
        : const Color(0xFF1C1C1E);

    final Color accentColor = widget.isSuccess
        ? const Color(0xFF34C759)   // iOS green
        : const Color(0xFFFF453A); // iOS red

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Positioned(
          bottom: 48 + MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          child: Opacity(
            opacity: _fadeAnim.value,
            child: Transform.translate(
              offset: Offset(0, _slideAnim.value),
              child: child,
            ),
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon ?? Icons.info_outline_rounded,
                  color: accentColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.3,
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
}