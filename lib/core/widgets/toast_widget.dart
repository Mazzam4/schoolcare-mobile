import 'package:flutter/material.dart';

class AppToast extends StatefulWidget {
  final String message;
  final bool isSuccess;
  final IconData? icon;

  const AppToast({
    super.key,
    required this.message,
    required this.isSuccess,
    this.icon,
  });

  @override
  State<AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<AppToast> with SingleTickerProviderStateMixin {
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
    final accentColor = widget.isSuccess ? const Color(0xFF34C759) : const Color(0xFFFF453A);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Positioned(
        bottom: 48 + MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        child: Opacity(
          opacity: _fadeAnim.value,
          child: Transform.translate(offset: Offset(0, _slideAnim.value), child: child),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 6)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon ?? Icons.info_outline_rounded, color: accentColor, size: 20),
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

// Helper function — panggil ini dari screen manapun
void showAppToast(
  BuildContext context, {
  required String message,
  required bool isSuccess,
  IconData? icon,
}) {
  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
    builder: (context) => AppToast(message: message, isSuccess: isSuccess, icon: icon),
  );
  overlay.insert(entry);
  Future.delayed(const Duration(milliseconds: 2800), () => entry.remove());
}