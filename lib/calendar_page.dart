import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models.dart';
import 'program_page.dart';
import 'store.dart';
import 'theme.dart';
import 'ui.dart';

/// Ana sayfa: sayaçlar + takvim + seçili günün idmanı.
class CalendarPage extends StatefulWidget {
  final VoidCallback onGoProgram;
  const CalendarPage({super.key, required this.onGoProgram});
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime selected = today;
  DateTime month = DateTime(today.year, today.month, 1);

  String _short(String name) {
    final first = name.split(RegExp(r'[-/,+& ]')).firstWhere((s) => s.isNotEmpty, orElse: () => name);
    return first.length > 6 ? first.substring(0, 6) : first;
  }

  void _tapDay(DateTime d) {
    if (isFuture(d)) {
      toast(context, 'İleri bir tarihe idman işlenemez 📅');
      return;
    }
    setState(() => selected = d);
    if (store.dayEntry(d) == null) chooseRegion(context, d);
  }

  @override
  Widget build(BuildContext context) {
    final p = pal;
    final prof = store.profile!;
    final entry = store.dayEntry(selected);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
      children: [
        SizedBox(
          height: 150,
          child: PhotoShade(
            photo: 'hero',
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(fmtLong(today).toUpperCase(),
                      style: TextStyle(
                          color: p.accent, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                  const SizedBox(height: 2),
                  Text('Merhaba, ${prof.firstName} 👋',
                      style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800)),
                  Text(
                      store.dayEntry(today) == null
                          ? 'Bugün ne çalışacaksın?'
                          : 'Bugün: ${store.dayEntry(today)!.name}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: _Counter(
              label: 'Bu Ay',
              value: store.monthCount,
              sub: kMonths[today.month - 1],
              icon: Icons.local_fire_department_rounded,
              highlight: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Counter(
              label: 'Toplam',
              value: store.totalCount,
              sub: 'antrenman',
              icon: Icons.emoji_events_rounded,
            ),
          ),
        ]),
        const SizedBox(height: 14),
        Panel(
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
          child: MonthCalendar(
            month: month,
            selected: selected,
            onMonth: (m) => setState(() => month = m),
            onSelect: _tapDay,
            dotColor: (d) {
              final e = store.dayEntry(d);
              return e == null ? null : regionColor(e.regionId, rest: e.rest);
            },
            label: (d) {
              final e = store.dayEntry(d);
              return e == null ? null : _short(e.name);
            },
          ),
        ),
        SectionTitle(selected == today ? 'Bugün' : fmtLong(selected)),
        if (entry != null)
          _DayCard(date: selected, entry: entry)
        else
          Panel(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Icon(Icons.event_available_rounded, color: p.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(selected == today ? 'Bugün ne çalıştın / çalışacaksın?' : 'Bu gün ne çalıştın?',
                      style: TextStyle(color: p.text, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 14),
              store.regions.isEmpty
                  ? AccentButton('Önce programını oluştur', icon: Icons.add_rounded, onTap: widget.onGoProgram)
                  : AccentButton('Bölge seç', icon: Icons.touch_app_rounded,
                      onTap: () => chooseRegion(context, selected)),
            ]),
          ),
      ],
    );
  }
}

class _Counter extends StatelessWidget {
  final String label;
  final int value;
  final String sub;
  final IconData icon;
  final bool highlight;
  const _Counter({required this.label, required this.value, required this.sub, required this.icon, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final p = pal;
    final fg = highlight ? p.onAccent : p.text;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        color: highlight ? p.accent : p.card,
        borderRadius: BorderRadius.circular(22),
        border: highlight ? null : Border.all(color: p.line.withValues(alpha: 0.7)),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label.toUpperCase(),
                style: TextStyle(
                    color: fg.withValues(alpha: 0.75), fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.toDouble()),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Text('${v.round()}',
                  style: TextStyle(color: fg, fontSize: 38, fontWeight: FontWeight.w800, height: 1.15)),
            ),
            Text(sub, style: TextStyle(color: fg.withValues(alpha: 0.7), fontSize: 12.5)),
          ]),
        ),
        Icon(icon, color: fg.withValues(alpha: highlight ? 0.85 : 0.35), size: 34),
      ]),
    );
  }
}

class _DayCard extends StatelessWidget {
  final DateTime date;
  final DayEntry entry;
  const _DayCard({required this.date, required this.entry});

  @override
  Widget build(BuildContext context) {
    final region = store.regionById(entry.regionId);
    final muscles = region?.muscles ?? entry.muscles;
    return Panel(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          height: 150,
          child: PhotoShade(
            photo: region?.photo ?? entry.photo,
            radius: 22,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Pill(entry.rest ? 'DİNLENME' : (date == today ? 'BUGÜNÜN İDMANI' : 'ÇALIŞILDI ✓'),
                      color: regionColor(entry.regionId, rest: entry.rest).withValues(alpha: 0.25),
                      textColor: regionColor(entry.regionId, rest: entry.rest)),
                  const SizedBox(height: 6),
                  Text(entry.name,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                  if (region != null && !entry.rest)
                    Text('${region.exercises.length} hareket',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13.5)),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (muscles.isNotEmpty)
              Wrap(spacing: 6, runSpacing: 6, children: [for (final m in muscles) Pill(muscleName(m))]),
            if (muscles.isNotEmpty) const SizedBox(height: 12),
            if (region != null && !entry.rest && region.exercises.isNotEmpty) ...[
              AccentButton(date == today ? 'İdmana başla · ağırlıkları gir' : 'Ağırlıkları gör / düzenle',
                  icon: Icons.play_arrow_rounded,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => RegionWorkoutPage(region: region, date: date)))),
              const SizedBox(height: 10),
            ],
            Row(children: [
              Expanded(
                child: AccentButton('Düzenle', icon: Icons.edit_rounded, outlined: true,
                    onTap: () => chooseRegion(context, date)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AccentButton('Sil', icon: Icons.delete_outline_rounded, outlined: true, color: kRed,
                    onTap: () async {
                  if (await confirm(context, 'Kayıt silinsin mi?',
                      '${fmtDate(date)} tarihindeki "${entry.name}" kaydı silinecek.')) {
                    store.clearDay(date);
                  }
                }),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

/// "Bugün ne çalıştın/çalışacaksın?" — bölge seçimi.
Future<void> chooseRegion(BuildContext context, DateTime date) async {
  if (isFuture(date)) return;
  if (store.regions.isEmpty) {
    toast(context, 'Önce Programım sekmesinden bölge ekle');
    return;
  }
  final current = store.dayEntry(date);
  final picked = await showAppSheet<Region>(context, (ctx) {
    final p = pal;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        children: [
          Text(date == today ? 'Bugün ne çalıştın / çalışacaksın?' : 'Bu gün ne çalıştın?',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: p.text)),
          const SizedBox(height: 2),
          Text(fmtLong(date), style: TextStyle(color: p.dim, fontSize: 14)),
          const SizedBox(height: 16),
          for (final r in store.regions)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx, r),
                child: SizedBox(
                  height: 84,
                  child: Stack(children: [
                    Positioned.fill(
                      child: PhotoShade(
                        photo: r.photo,
                        radius: 18,
                        strength: 1.1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: LinearGradient(colors: [
                              Colors.black.withValues(alpha: 0.75),
                              Colors.black.withValues(alpha: 0.05),
                            ]),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: current?.regionId == r.id ? p.accent : Colors.transparent, width: 2.5),
                        ),
                        child: Row(children: [
                          Container(
                            width: 10,
                            height: 40,
                            decoration: BoxDecoration(
                                color: regionColor(r.id, rest: r.rest), borderRadius: BorderRadius.circular(6)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.name,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                                Text(r.rest ? 'Dinlenme günü' : '${r.exercises.length} hareket',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
                              ],
                            ),
                          ),
                          if (current?.regionId == r.id) Icon(Icons.check_circle_rounded, color: p.accent),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  });
  if (picked != null) {
    store.setDay(date, picked);
    HapticFeedback.mediumImpact();
    if (context.mounted) toast(context, '${fmtDate(date)} → ${picked.name} işlendi ✓');
  }
}
