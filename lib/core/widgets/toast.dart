import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/wgn_colors.dart';
import '../theme/wgn_theme.dart';

/// Transient toast matching the design: plum card w/ gold border above nav.
class ToastController extends Notifier<String?> {
  Timer? _timer;

  @override
  String? build() => null;

  void show(String message) {
    _timer?.cancel();
    state = message;
    _timer = Timer(const Duration(milliseconds: 1900), () => state = null);
  }
}

final toastProvider = NotifierProvider<ToastController, String?>(
  ToastController.new,
);

class ToastHost extends ConsumerWidget {
  const ToastHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(toastProvider);
    final c = context.wgn;
    return IgnorePointer(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: message == null ? 0 : 1,
        child: message == null
            ? const SizedBox.shrink()
            : Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: c.plum,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFFD4AF54).withValues(alpha: .45)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 30,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Text(
                  message,
                  style: WgnText.ui(12.5,
                      weight: FontWeight.w700,
                      color: const Color(0xFFF5F1F7)),
                ),
              ),
      ),
    );
  }
}
