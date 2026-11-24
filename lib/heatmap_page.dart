import 'package:flutter/material.dart';
import 'body_map_data.dart';
import 'models.dart';
import 'store.dart';
import 'theme.dart';
import 'ui.dart';

/// Şekildeki parça → sayılan kas grubu.
String groupOf(String polyKey) => polyKey == 'obliques' ? 'abs' : polyKey;

Color? heatColor(int n) => n <= 0 ? null : (n == 1 ? kYellow : kRed);

// ======================= KAS ISI HARİTASI =======================
class HeatmapPage extends StatefulWidget {
  const HeatmapPage({super.key});
  @override
  State<HeatmapPage> createState() => _HeatmapPageState();
}

class _HeatmapPageState extends State<HeatmapPage> {
  int offset = 0; // 0 = bu hafta, -1 = geçen hafta ...

  @override
  Widget build(BuildContext context) {
    final p = pal;
    final ws = weekStart(today).add(Duration(days: 7 * offset));
    final we = ws.add(const Duration(days: 6));
    final counts = store.muscleCounts(ws);
    final groups = kMuscleGroups.where((g) => g.key != 'cardio').toList()
      ..sort((a, b) => (counts[b.key] ?? 0).compareTo(counts[a.key] ?? 0));
    final worked = groups.where((g) => (counts[g.key] ?? 0) > 0).length;
    final days = [
      for (var i = 0; i < 7; i++) store.dayEntry(ws.add(Duration(days: i))),
    ];
    final weekLabel = ws.month == we.month
        ? '${ws.day}–${we.day} ${kMonths[ws.month - 1]} ${ws.year}'
        : '${fmtShort(ws)} – ${fmtShort(we)} ${we.year}';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
      children: [
        Panel(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(children: [
            RoundIcon(Icons.chevron_left_rounded, onTap: () => setState(() => offset--)),
            Expanded(
              child: Column(children: [
                Text(offset == 0 ? 'BU HAFTA' : offset == -1 ? 'GEÇEN HAFTA' : '${-offset} HAFTA ÖNCE',
                    style: TextStyle(color: p.accent, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                Text(weekLabel, style: TextStyle(color: p.text, fontSize: 15.5, fontWeight: FontWeight.w700)),
              ]),
            ),
            Opacity(
              opacity: offset < 0 ? 1 : 0.3,
              child: RoundIcon(Icons.chevron_right_rounded, onTap: () {
                if (offset < 0) setState(() => offset++);
              }),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        // haftanın günleri şeridi
        Row(children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: days[i] == null
                      ? p.card
                      : regionColor(days[i]!.regionId, rest: days[i]!.rest).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: ws.add(Duration(days: i)) == today ? Border.all(color: p.accent, width: 1.5) : null,
                ),
                child: Column(children: [
                  Text(kWeekdaysShort[i], style: TextStyle(color: p.dim, fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Icon(
                    days[i] == null
                        ? Icons.remove_rounded
                        : days[i]!.rest
                            ? Icons.bedtime_rounded
                            : Icons.check_circle_rounded,
                    size: 18,
                    color: days[i] == null ? p.line : regionColor(days[i]!.regionId, rest: days[i]!.rest),
                  ),
                ]),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        Panel(
          padding: const EdgeInsets.fromLTRB(10, 16, 10, 14),
          child: Column(children: [
            Row(children: [
              Expanded(child: _BodyView(title: 'ÖN', muscles: kFrontMuscles, counts: counts)),
              Expanded(child: _BodyView(title: 'ARKA', muscles: kBackMuscles, counts: counts)),
            ]),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _legend(null, 'Çalışılmadı'),
              const SizedBox(width: 14),
              _legend(kYellow, '1 kez'),
              const SizedBox(width: 14),
              _legend(kRed, '2+ kez'),
            ]),
          ]),
        ),
        SectionTitle('Bu hafta çalışılan kaslar',
            action: Text('$worked / ${groups.length}',
                style: TextStyle(color: p.accent, fontWeight: FontWeight.w800))),
        if ((counts['cardio'] ?? 0) > 0)
          _MuscleRow(name: 'Kardiyo ❤️', count: counts['cardio']!),
        for (final g in groups) _MuscleRow(name: g.name, count: counts[g.key] ?? 0),
      ],
    );
  }

  Widget _legend(Color? c, String t) => Row(children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: c ?? pal.dim, width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(t, style: TextStyle(color: pal.dim, fontSize: 12)),
      ]);
}

class _MuscleRow extends StatelessWidget {
  final String name;
  final int count;
  const _MuscleRow({required this.name, required this.count});

  @override
  Widget build(BuildContext context) {
    final p = pal;
    final c = heatColor(count);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Panel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(color: c ?? p.dim, width: 1.5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: TextStyle(color: p.text, fontSize: 15, fontWeight: FontWeight.w600))),
          Text(count == 0 ? 'hiç' : '$count kez',
              style: TextStyle(color: c ?? p.dim, fontSize: 15, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}

class _BodyView extends StatelessWidget {
  final String title;
  final List<MusclePoly> muscles;
  final Map<String, int> counts;
  const _BodyView({required this.title, required this.muscles, required this.counts});

  @override
  Widget build(BuildContext context) {
    final p = pal;
    return Column(children: [
      Text(title, style: TextStyle(color: p.dim, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 2)),
      const SizedBox(height: 6),
      AspectRatio(
        aspectRatio: 200 / 440,
        child: TweenAnimationBuilder<double>(
          key: ValueKey(counts.toString()),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          builder: (_, t, __) => CustomPaint(painter: BodyPainter(muscles, counts, p, t, front: title == 'ÖN')),
        ),
      ),
    ]);
  }
}

class BodyPainter extends CustomPainter {
  final List<MusclePoly> muscles;
  final Map<String, int> counts;
  final Palette p;
  final double t;
  final bool front;
  BodyPainter(this.muscles, this.counts, this.p, this.t, {required this.front});

  Path _path(List<double> pts, double s) {
    final path = Path()..moveTo(pts[0] * s, pts[1] * s);
    for (var i = 2; i < pts.length; i += 2) {
      path.lineTo(pts[i] * s, pts[i + 1] * s);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 200;
    final body = Paint()..color = p.dark ? const Color(0xFF2A2D35) : const Color(0xFFD9DCE3);
    for (final poly in kSilhouette) {
      canvas.drawPath(_path(poly, s), body);
    }
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = p.dark ? const Color(0xFF6B7180) : const Color(0xFF9AA0AC);
    for (final m in muscles) {
      final path = _path(m.pts, s);
      final c = heatColor(counts[groupOf(m.key)] ?? 0);
      if (c != null) {
        canvas.drawPath(
            path,
            Paint()
              ..color = c.withValues(alpha: 0.55 * t)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
        canvas.drawPath(path, Paint()..color = Color.lerp(body.color, c, t)!);
        canvas.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.1
              ..color = Colors.white.withValues(alpha: 0.35));
      } else {
        canvas.drawPath(path, outline);
      }
    }
    if (front) {
      final lp = Paint()
        ..color = p.dark ? const Color(0xFF14161B) : Colors.white
        ..strokeWidth = 1.2;
      for (final ln in kAbsLines) {
        canvas.drawLine(Offset(ln[0] * s, ln[1] * s), Offset(ln[2] * s, ln[3] * s), lp);
      }
    }
  }

  @override
  bool shouldRepaint(covariant BodyPainter old) => old.t != t || old.counts != counts || old.p != p;
}
