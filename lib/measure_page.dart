import 'dart:math';
import 'package:flutter/material.dart';
import 'models.dart';
import 'store.dart';
import 'theme.dart';
import 'ui.dart';

// ======================= ÖLÇÜMLERİM =======================
class MeasurePage extends StatefulWidget {
  const MeasurePage({super.key});
  @override
  State<MeasurePage> createState() => _MeasurePageState();
}

class _MeasurePageState extends State<MeasurePage> {
  int range = 0; // 0: tümü, 1: 3 ay, 2: 1 ay

  @override
  Widget build(BuildContext context) {
    final p = pal;
    final all = store.weightSeries;
    final cutoff = range == 1
        ? today.subtract(const Duration(days: 90))
        : range == 2
            ? today.subtract(const Duration(days: 30))
            : null;
    final series = cutoff == null ? all : all.where((e) => !e.key.isBefore(cutoff)).toList();
    final cur = store.currentWeight;
    final first = all.isEmpty ? cur : all.first.value;
    final diff = cur - first;
    final bmi = store.bmi;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
      children: [
        PageHeader(
          photo: 'scale',
          subtitle: 'Güncel kilo',
          title: '${fmtNum(cur)} kg',
          height: 160,
          trailing: all.length > 1
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (diff <= 0 ? kGreen : kRed).withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('${diff > 0 ? "+" : diff < 0 ? "−" : ""}${fmtNum(diff.abs())} kg',
                        style: TextStyle(
                            color: diff <= 0 ? kGreen : kRed, fontWeight: FontWeight.w800, fontSize: 18)),
                    const Text('başlangıçtan', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ]),
                )
              : null,
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _Stat('Başlangıç', '${fmtNum(first)} kg')),
          const SizedBox(width: 10),
          Expanded(child: _Stat('Ölçüm', '${all.length}')),
          const SizedBox(width: 10),
          Expanded(child: _Stat('VKİ', bmi == null ? '—' : fmtNum(bmi), sub: bmi == null ? null : bmiLabel(bmi))),
        ]),
        const SizedBox(height: 14),
        Panel(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Kilo grafiği', style: TextStyle(color: p.text, fontSize: 17, fontWeight: FontWeight.w700)),
              const Spacer(),
              for (final (i, t) in [(0, 'Tümü'), (1, '3 Ay'), (2, '1 Ay')])
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => range = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: range == i ? p.accent : p.bg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(t,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: range == i ? p.onAccent : p.dim)),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 14),
            SizedBox(
              height: 230,
              child: series.isEmpty
                  ? Center(child: Text('Bu aralıkta ölçüm yok', style: TextStyle(color: p.dim)))
                  : TweenAnimationBuilder<double>(
                      key: ValueKey('${series.length}-$range-${series.isEmpty ? 0 : series.last.value}'),
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (_, t, __) => CustomPaint(
                        size: Size.infinite,
                        painter: WeightChartPainter(series, p, t),
                      ),
                    ),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        AccentButton('Ölçüm ekle', icon: Icons.add_rounded, onTap: () => editWeight(context, null, null)),
        SectionTitle('Tüm ölçümler'),
        for (var i = all.length - 1; i >= 0; i--)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Panel(
              padding: const EdgeInsets.fromLTRB(16, 10, 6, 10),
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: p.accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
                  alignment: Alignment.center,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('${all[i].key.day}',
                        style: TextStyle(color: p.accent, fontWeight: FontWeight.w800, fontSize: 16, height: 1.1)),
                    Text(kMonths[all[i].key.month - 1].substring(0, 3),
                        style: TextStyle(color: p.accent, fontSize: 10, height: 1.1)),
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${fmtNum(all[i].value)} kg',
                        style: TextStyle(color: p.text, fontSize: 17, fontWeight: FontWeight.w700)),
                    Text(fmtDate(all[i].key), style: TextStyle(color: p.dim, fontSize: 12.5)),
                  ]),
                ),
                if (i > 0) _delta(all[i].value - all[i - 1].value),
                IconButton(
                  icon: Icon(Icons.edit_rounded, color: p.dim, size: 20),
                  onPressed: () => editWeight(context, all[i].key, all[i].value),
                ),
              ]),
            ),
          ),
      ],
    );
  }

  Widget _delta(double d) {
    if (d.abs() < 0.05) return Text('=', style: TextStyle(color: pal.dim));
    return Text('${d > 0 ? "▲" : "▼"} ${fmtNum(d.abs())}',
        style: TextStyle(color: d > 0 ? kRed : kGreen, fontWeight: FontWeight.w700, fontSize: 13));
  }
}

String bmiLabel(double b) {
  if (b < 18.5) return 'zayıf';
  if (b < 25) return 'normal';
  if (b < 30) return 'fazla kilolu';
  return 'obez';
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  const _Stat(this.label, this.value, {this.sub});
  @override
  Widget build(BuildContext context) {
    final p = pal;
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(),
            style: TextStyle(color: p.dim, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: TextStyle(color: p.text, fontSize: 19, fontWeight: FontWeight.w800)),
        ),
        if (sub != null) Text(sub!, style: TextStyle(color: p.accent, fontSize: 11.5, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// Ölçüm ekle / düzenle / sil.
Future<void> editWeight(BuildContext context, DateTime? date, double? kg) async {
  await showAppSheet<void>(context, (ctx) => _WeightEditor(date: date, kg: kg));
}

class _WeightEditor extends StatefulWidget {
  final DateTime? date;
  final double? kg;
  const _WeightEditor({this.date, this.kg});
  @override
  State<_WeightEditor> createState() => _WeightEditorState();
}

class _WeightEditorState extends State<_WeightEditor> {
  late DateTime date = widget.date ?? today;
  late final TextEditingController kg =
      TextEditingController(text: widget.kg == null ? '' : fmtNum(widget.kg!));

  @override
  void initState() {
    super.initState();
    kg.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    kg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = pal;
    final editing = widget.date != null;
    final v = parseNum(kg.text);
    final exists = !editing && store.weights.containsKey(dkey(date));
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(editing ? 'Ölçümü düzenle' : 'Yeni ölçüm',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: p.text)),
        const SizedBox(height: 16),
        Panel(
          onTap: () async {
            final d = await pickDate(context, date);
            if (d != null) setState(() => date = d);
          },
          child: Row(children: [
            Icon(Icons.calendar_today_rounded, color: p.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(fmtLong(date), style: TextStyle(color: p.text, fontSize: 15.5, fontWeight: FontWeight.w600)),
            ),
            Text('Değiştir', style: TextStyle(color: p.accent, fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(height: 14),
        NumField(controller: kg, label: 'Kilo', suffix: 'kg', autofocus: !editing),
        if (exists)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Bu tarihte zaten ölçüm var; yenisiyle değiştirilecek.',
                style: TextStyle(color: kYellow, fontSize: 12.5)),
          ),
        const SizedBox(height: 20),
        AccentButton('Kaydet',
            icon: Icons.check_rounded,
            onTap: v == null || v < 20 || v > 400
                ? null
                : () {
                    store.setWeight(date, v, replaces: widget.date);
                    Navigator.pop(context);
                  }),
        if (editing) ...[
          const SizedBox(height: 10),
          AccentButton('Ölçümü sil', icon: Icons.delete_outline_rounded, outlined: true, color: kRed, onTap: () async {
            if (await confirm(context, 'Ölçüm silinsin mi?', '${fmtDate(widget.date!)} tarihli ölçüm silinecek.')) {
              store.deleteWeight(widget.date!);
              if (context.mounted) Navigator.pop(context);
            }
          }),
        ],
      ]),
    );
  }
}

// ======================= GRAFİK =======================
class WeightChartPainter extends CustomPainter {
  final List<MapEntry<DateTime, double>> data;
  final Palette p;
  final double t; // animasyon 0..1
  WeightChartPainter(this.data, this.p, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    const left = 40.0, right = 12.0, top = 14.0, bottom = 26.0;
    final w = size.width - left - right;
    final h = size.height - top - bottom;
    var minV = data.map((e) => e.value).reduce(min);
    var maxV = data.map((e) => e.value).reduce(max);
    if (maxV - minV < 2) {
      final mid = (maxV + minV) / 2;
      minV = mid - 1;
      maxV = mid + 1;
    }
    final pad = (maxV - minV) * 0.18;
    minV -= pad;
    maxV += pad;
    final t0 = data.first.key.millisecondsSinceEpoch.toDouble();
    final t1 = data.last.key.millisecondsSinceEpoch.toDouble();
    final span = max(1.0, t1 - t0);

    Offset pt(int i) {
      final x = data.length == 1 ? left + w / 2 : left + (data[i].key.millisecondsSinceEpoch - t0) / span * w;
      final y = top + (1 - (data[i].value - minV) / (maxV - minV)) * h;
      return Offset(x, y);
    }

    // yatay çizgiler + etiketler
    final grid = Paint()
      ..color = p.line.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    for (var k = 0; k <= 4; k++) {
      final y = top + h * k / 4;
      canvas.drawLine(Offset(left, y), Offset(left + w, y), grid);
      final v = maxV - (maxV - minV) * k / 4;
      _text(canvas, fmtNum(v), Offset(0, y - 7), p.dim, 10.5, width: left - 6, align: TextAlign.right);
    }

    final pts = [for (var i = 0; i < data.length; i++) pt(i)];
    // tarih etiketleri (en fazla 5)
    final step = max(1, (data.length / 5).ceil());
    for (var i = 0; i < data.length; i += step) {
      _text(canvas, '${data[i].key.day}.${data[i].key.month.toString().padLeft(2, '0')}',
          Offset(pts[i].dx - 20, size.height - 18), p.dim, 10.5, width: 40, align: TextAlign.center);
    }
    if (data.length > 1 && (data.length - 1) % step != 0) {
      final i = data.length - 1;
      _text(canvas, '${data[i].key.day}.${data[i].key.month.toString().padLeft(2, '0')}',
          Offset(pts[i].dx - 34, size.height - 18), p.dim, 10.5, width: 40, align: TextAlign.right);
    }

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, left + w * t + 6, size.height));
    if (pts.length > 1) {
      final line = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        final a = pts[i - 1], b = pts[i];
        final mx = (a.dx + b.dx) / 2;
        line.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
      }
      final fill = Path.from(line)
        ..lineTo(pts.last.dx, top + h)
        ..lineTo(pts.first.dx, top + h)
        ..close();
      canvas.drawPath(
          fill,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [p.accent.withValues(alpha: 0.35), p.accent.withValues(alpha: 0.0)],
            ).createShader(Rect.fromLTWH(0, top, size.width, h)));
      canvas.drawPath(
          line,
          Paint()
            ..color = p.accent
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round);
    }
    for (var i = 0; i < pts.length; i++) {
      final last = i == pts.length - 1;
      canvas.drawCircle(pts[i], last ? 7 : 4.5, Paint()..color = p.accent);
      canvas.drawCircle(pts[i], last ? 3.5 : 2, Paint()..color = p.card);
      if (last || data.length <= 8) {
        _text(canvas, fmtNum(data[i].value), pts[i] + const Offset(-24, -24), p.text, 11.5,
            width: 48, align: TextAlign.center, bold: true);
      }
    }
    canvas.restore();
  }

  void _text(Canvas c, String s, Offset o, Color color, double size,
      {double width = 60, TextAlign align = TextAlign.left, bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
          text: s,
          style: TextStyle(
              color: color, fontSize: size, fontFamily: 'Poppins', fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: width, maxWidth: width);
    tp.paint(c, o);
  }

  @override
  bool shouldRepaint(covariant WeightChartPainter old) => old.data != data || old.t != t || old.p != p;
}
