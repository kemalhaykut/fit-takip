import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'ui.dart';

final navKey = GlobalKey<NavigatorState>();

/// Dinlenme sayacı. Bitiş zamanı tutulur; uygulama arka plana gidip gelse de doğru kalır.
class RestTimer extends ChangeNotifier {
  DateTime? _end;
  int total = 0;
  Timer? _tick;

  bool get running => _end != null;

  int get remaining {
    if (_end == null) return 0;
    final r = _end!.difference(DateTime.now()).inMilliseconds;
    return max(0, (r / 1000).ceil());
  }

  double get progress => total == 0 ? 0 : remaining / total;

  void start(int seconds) {
    total = seconds;
    _end = DateTime.now().add(Duration(seconds: seconds));
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (remaining <= 0) {
        _finish();
      } else {
        notifyListeners();
      }
    });
    HapticFeedback.mediumImpact();
    notifyListeners();
  }

  void addTime(int seconds) {
    if (_end == null) return;
    _end = _end!.add(Duration(seconds: seconds));
    total += seconds;
    notifyListeners();
  }

  void cancel() {
    _tick?.cancel();
    _end = null;
    notifyListeners();
  }

  Future<void> _finish() async {
    _tick?.cancel();
    _end = null;
    notifyListeners();
    for (var i = 0; i < 3; i++) {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
    final ctx = navKey.currentContext;
    if (ctx != null && ctx.mounted) {
      showDialog<void>(
        context: ctx,
        builder: (c) => AlertDialog(
          title: Text('Süre doldu! 💪',
              style: TextStyle(color: pal.text, fontWeight: FontWeight.w800)),
          content: Text('Dinlenme bitti, sıradaki sete geç.', style: TextStyle(color: pal.dim)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text('Tamam',
                    style: TextStyle(color: pal.accent, fontWeight: FontWeight.w700))),
          ],
        ),
      );
    }
  }
}

final restTimer = RestTimer();

String fmtClock(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

/// Üst çubuktaki sayaç düğmesi. Çalışırken geri sayımı gösterir.
class TimerButton extends StatelessWidget {
  const TimerButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: restTimer,
      builder: (context, _) {
        final p = pal;
        if (!restTimer.running) {
          return RoundIcon(Icons.timer_outlined, tooltip: 'Sayaç', onTap: () => openTimerSheet(context));
        }
        return GestureDetector(
          onTap: () => openTimerSheet(context),
          child: Container(
            height: 40,
            padding: const EdgeInsets.only(left: 6, right: 12),
            decoration: BoxDecoration(
              color: p.accent,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(children: [
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  value: restTimer.progress,
                  strokeWidth: 3,
                  color: p.onAccent,
                  backgroundColor: p.onAccent.withValues(alpha: 0.2),
                ),
              ),
              const SizedBox(width: 8),
              Text(fmtClock(restTimer.remaining),
                  style: TextStyle(
                      color: p.onAccent,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ]),
          ),
        );
      },
    );
  }
}

void openTimerSheet(BuildContext context) {
  showAppSheet<void>(context, (ctx) => const _TimerSheet());
}

class _TimerSheet extends StatelessWidget {
  const _TimerSheet();

  static const options = [30, 45, 60, 90, 120];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: restTimer,
      builder: (context, _) {
        final p = pal;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Dinlenme Sayacı',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: p.text)),
            const SizedBox(height: 18),
            SizedBox(
              height: 190,
              child: Center(
                child: SizedBox(
                  width: 180,
                  height: 180,
                  child: Stack(fit: StackFit.expand, children: [
                    CircularProgressIndicator(
                      value: restTimer.running ? restTimer.progress : 1,
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                      color: p.accent,
                      backgroundColor: p.line,
                    ),
                    Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(restTimer.running ? fmtClock(restTimer.remaining) : '0:00',
                            style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w800,
                                color: p.text,
                                fontFeatures: const [FontFeature.tabularFigures()])),
                        Text(restTimer.running ? 'kalan süre' : 'süre seç',
                            style: TextStyle(color: p.dim, fontSize: 13)),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: [
              for (final s in options)
                _OptionChip(
                  label: '$s',
                  unit: 'sn',
                  active: restTimer.running && restTimer.total == s,
                  onTap: () => restTimer.start(s),
                ),
            ]),
            const SizedBox(height: 18),
            if (restTimer.running)
              Row(children: [
                Expanded(child: AccentButton('+15 sn', outlined: true, onTap: () => restTimer.addTime(15))),
                const SizedBox(width: 12),
                Expanded(child: AccentButton('Durdur', icon: Icons.stop_rounded, color: kRed, onTap: restTimer.cancel)),
              ]),
          ]),
        );
      },
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final String unit;
  final bool active;
  final VoidCallback onTap;
  const _OptionChip({required this.label, required this.unit, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = pal;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: active ? p.accent : p.card,
          shape: BoxShape.circle,
          border: Border.all(color: active ? p.accent : p.line, width: 1.5),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label,
              style: TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w800, color: active ? p.onAccent : p.text, height: 1.1)),
          Text(unit, style: TextStyle(fontSize: 11, color: active ? p.onAccent : p.dim, height: 1.1)),
        ]),
      ),
    );
  }
}
