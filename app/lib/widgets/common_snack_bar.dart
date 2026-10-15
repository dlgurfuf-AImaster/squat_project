
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 공통 SnackBar 유형
enum SnackBarType {
  success,
  error,
  info,
}

/// SquatMate 공통 SnackBar
class CommonSnackBar {
  CommonSnackBar._();

  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  /// 공통 SnackBar 표시
  static void show(
      BuildContext context, {
        required String message,
        required SnackBarType type,
      }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);

    if (overlay == null) return;

    // 기존 SnackBar가 있다면 정리
    _dismissTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;

    final entry = OverlayEntry(
      builder: (overlayContext) => _CommonSnackBarOverlay(
        message: message,
        type: type,
        onDismiss: () => _dismiss(animate: true),
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(
      const Duration(milliseconds: 3200),
          () => _dismiss(animate: true),
    );
  }

  static void _dismiss({required bool animate}) {
    _dismissTimer?.cancel();
    _dismissTimer = null;

    final entry = _currentEntry;
    if (entry == null) return;

    if (!animate) {
      entry.remove();
      _currentEntry = null;
      return;
    }

    // 애니메이션 종료 후 OverlayEntry 제거
    entry.markNeedsBuild();

    final state = _CommonSnackBarOverlay.activeState;
    if (state != null && identical(state.entry, entry)) {
      state.dismiss();
    } else {
      entry.remove();
      _currentEntry = null;
    }
  }
}

class _SnackConfig {
  const _SnackConfig({
    required this.colors,
    required this.shadowColor,
    required this.icon,
  });

  final List<Color> colors;
  final Color shadowColor;
  final IconData icon;

  static const success = _SnackConfig(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    shadowColor: Color(0x5C10B981),
    icon: Icons.check_circle_outline_rounded,
  );

  static const error = _SnackConfig(
    colors: [Color(0xFFF87171), Color(0xFFEF4444)],
    shadowColor: Color(0x5CEF4444),
    icon: Icons.error_outline_rounded,
  );

  static const info = _SnackConfig(
    colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
    shadowColor: Color(0x5C0284C7),
    icon: Icons.info_outline_rounded,
  );

  static _SnackConfig forType(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return success;
      case SnackBarType.error:
        return error;
      case SnackBarType.info:
        return info;
    }
  }
}

class _CommonSnackBarOverlay extends StatefulWidget {
  const _CommonSnackBarOverlay({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  final String message;
  final SnackBarType type;
  final VoidCallback onDismiss;

  static _CommonSnackBarOverlayState? activeState;

  @override
  State<_CommonSnackBarOverlay> createState() =>
      _CommonSnackBarOverlayState();
}

class _CommonSnackBarOverlayState
    extends State<_CommonSnackBarOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  OverlayEntry? get entry => CommonSnackBar._currentEntry;

  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();

    _CommonSnackBarOverlay.activeState = this;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 220),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Cubic(0.22, 1, 0.36, 1),
        reverseCurve: Curves.easeIn,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Duration(milliseconds: 250).inMilliseconds == 250
          ? Curves.easeOut
          : Curves.linear,
      reverseCurve: Curves.easeIn,
    );

    _controller.forward();
  }

  void dismiss() {
    if (_isDismissing) return;
    _isDismissing = true;

    _controller.reverse().then((_) {
      if (!mounted) return;

      final currentEntry = CommonSnackBar._currentEntry;
      currentEntry?.remove();
      CommonSnackBar._currentEntry = null;
    });
  }

  @override
  void dispose() {
    if (identical(_CommonSnackBarOverlay.activeState, this)) {
      _CommonSnackBarOverlay.activeState = null;
    }

    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _SnackConfig.forType(widget.type);

    return Positioned(
      left: 18,
      right: 18,
      bottom: 12,
      child: IgnorePointer(
        ignoring: _isDismissing,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: config.colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: config.shadowColor,
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      config.icon,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.35,
                          letterSpacing: 0.13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 26,
                      height: 26,
                      child: Material(
                        color: const Color(0x2EFFFFFF),
                        borderRadius: BorderRadius.circular(9),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(9),
                          onTap: widget.onDismiss,
                          child: const Center(
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
