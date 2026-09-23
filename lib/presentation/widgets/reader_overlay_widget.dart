import 'dart:async';
import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';

/// Widget overlay terisolasi yang menampilkan jam digital dan indikator baterai.
/// Diletakkan di pojok kanan bawah layar ReaderPage (di atas BottomBar).
///
/// Widget ini SENGAJA dibuat terpisah (bukan bagian dari tree ReaderPage)
/// agar Stream rebuild HANYA mengenai widget ini — tidak mempengaruhi performa
/// render komik di parent.
class ReaderOverlayWidget extends StatefulWidget {
  const ReaderOverlayWidget({super.key});

  @override
  State<ReaderOverlayWidget> createState() => _ReaderOverlayWidgetState();
}

class _ReaderOverlayWidgetState extends State<ReaderOverlayWidget> {
  final Battery _battery = Battery();
  Timer? _clockTimer;
  StreamSubscription<BatteryState>? _batteryStateSub;

  DateTime _currentTime = DateTime.now();
  int _batteryLevel = -1; // -1 = belum terbaca
  BatteryState _batteryState = BatteryState.unknown;

  @override
  void initState() {
    super.initState();

    // Timer jam: perbarui setiap 30 detik untuk format HH:mm
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    // Baca level baterai sekali saat awal
    _fetchBatteryLevel();

    // Listen perubahan status charging (charging/discharging/full)
    _batteryStateSub = _battery.onBatteryStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _batteryState = state;
        });
        // Re-fetch level saat status berubah
        _fetchBatteryLevel();
      }
    });
  }

  Future<void> _fetchBatteryLevel() async {
    try {
      final level = await _battery.batteryLevel;
      if (mounted) {
        setState(() {
          _batteryLevel = level;
        });
      }
    } catch (_) {
      // Platform tidak mendukung — abaikan
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _batteryStateSub?.cancel();
    super.dispose();
  }

  IconData _batteryIcon(int level, BatteryState state) {
    if (state == BatteryState.charging || state == BatteryState.full) {
      return Icons.battery_charging_full_rounded;
    }
    if (level >= 90) return Icons.battery_full_rounded;
    if (level >= 70) return Icons.battery_6_bar_rounded;
    if (level >= 50) return Icons.battery_4_bar_rounded;
    if (level >= 30) return Icons.battery_3_bar_rounded;
    if (level >= 15) return Icons.battery_2_bar_rounded;
    if (level >= 5) return Icons.battery_1_bar_rounded;
    return Icons.battery_0_bar_rounded;
  }

  Color _batteryColor(int level, BatteryState state) {
    if (state == BatteryState.charging || state == BatteryState.full) {
      return const Color(0xFF4CAF50); // hijau saat charging
    }
    if (level <= 15) return const Color(0xFFF44336); // merah saat kritis
    if (level <= 30) return const Color(0xFFFF9800); // oranye saat rendah
    return Colors.white;
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = _formatTime(_currentTime);
    final battIcon = _batteryIcon(_batteryLevel, _batteryState);
    final battColor = _batteryColor(_batteryLevel, _batteryState);
    final battText = _batteryLevel >= 0 ? '$_batteryLevel%' : '--';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Baterai
          Icon(battIcon, size: 14, color: battColor),
          const SizedBox(width: 3),
          Text(
            battText,
            style: TextStyle(
              color: battColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 8),
          // Separator
          Container(
            width: 0.8,
            height: 12,
            color: Colors.white24,
          ),
          const SizedBox(width: 8),
          // Jam
          Text(
            timeStr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              height: 1.0,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
