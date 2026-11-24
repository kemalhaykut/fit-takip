import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models.dart';
import 'theme.dart';

/// Gerçek fotoğraflar (derleme sırasında assets/photos klasörüne indirilir).
const kPhotos = {
  'hero': 'Spor salonu',
  'dumbbell': 'Dambıl',
  'barbell': 'Halter',
  'chest': 'Göğüs',
  'back': 'Sırt',
  'shoulder': 'Omuz',
  'arm': 'Kol',
  'leg': 'Bacak',
  'abs': 'Karın',
  'cardio': 'Kardiyo',
  'rest': 'Dinlenme',
  'scale': 'Tartı',
  'bench': 'Sehpa',
};

/// Fotoğraf; dosya yoksa şık bir renk geçişi gösterir.
class Photo extends StatelessWidget {
  final String name;
  final BoxFit fit;
  final Alignment alignment;
  const Photo(this.name, {super.key, this.fit = BoxFit.cover, this.alignment = Alignment.center});

  @override
  Widget build(BuildContext context) {
    final p = pal;
    return Image.asset(
      'assets/photos/$name.jpg',
      fit: fit,
      alignment: alignment,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [p.accent.withValues(alpha: 0.55), p.card, p.bg],
          ),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.fitness_center_rounded, size: 56, color: p.text.withValues(alpha: 0.25)),
      ),
    );
  }
}

/// Fotoğraf üzerine okunaklı olsun diye koyu geçiş katmanı.
class PhotoShade extends StatelessWidget {
  final String photo;
  final Widget? child;
  final double radius;
  final double strength;
  final Alignment photoAlign;
  const PhotoShade(
      {super.key,
      required this.photo,
      this.child,
      this.radius = 24,
      this.strength = 0.85,
      this.photoAlign = Alignment.center});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(fit: StackFit.expand, children: [
        Photo(photo, alignment: photoAlign),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.10 * strength),
                Colors.black.withValues(alpha: 0.35 * strength),
                Colors.black.withValues(alpha: 0.92 * strength),
              ],
              stops: const [0, 0.45, 1],
            ),
          ),
        ),
        if (child != null) child!,
      ]),
    );
  }
}

/// Sayfa başlığı: büyük fotoğraf + başlık.
class PageHeader extends StatelessWidget {
  final String photo;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final double height;
  final Alignment photoAlign;
  const PageHeader(
      {super.key,
      required this.photo,
      required this.title,
      this.subtitle,
      this.trailing,
      this.height = 170,
      this.photoAlign = Alignment.center});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: PhotoShade(
        photo: photo,
        photoAlign: photoAlign,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subtitle != null)
                    Text(subtitle!.toUpperCase(),
                        style: TextStyle(
                            color: pal.accent,
                            fontSize: 12,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w700)),
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, height: 1.15)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ]),
        ),
      ),
    );
  }
}

/// Yuvarlatılmış kart.
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? border;
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.color, this.border});

  @override
  Widget build(BuildContext context) {
    final p = pal;
    return Material(
      color: color ?? p.card,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: border ?? p.line.withValues(alpha: 0.7)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? action;
  const SectionTitle(this.text, {super.key, this.action});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
        child: Row(children: [
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: pal.text)),
          ),
          if (action != null) action!,
        ]),
      );
}

/// Ana eylem düğmesi.
class AccentButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool outlined;
  final Color? color;
  const AccentButton(this.label, {super.key, this.icon, this.onTap, this.outlined = false, this.color});

  @override
  Widget build(BuildContext context) {
    final p = pal;
    final c = color ?? p.accent;
    final enabled = onTap != null;
    final fg = outlined ? c : (c == p.accent ? p.onAccent : Colors.white);
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: outlined ? Colors.transparent : c,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  onTap!();
                }
              : null,
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: outlined ? Border.all(color: c.withValues(alpha: 0.6), width: 1.5) : null,
            ),
            alignment: Alignment.center,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, color: fg, size: 22), const SizedBox(width: 8)],
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Küçük yuvarlak ikon düğmesi (kalem, sil vb.).
class RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final double size;
  final String? tooltip;
  const RoundIcon(this.icon, {super.key, required this.onTap, this.color, this.size = 40, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final p = pal;
    final w = Material(
      color: (color ?? p.text).withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.5, color: color ?? p.text),
        ),
      ),
    );
    return tooltip == null ? w : Tooltip(message: tooltip!, child: w);
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? textColor;
  const Pill(this.text, {super.key, this.color, this.textColor});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color ?? pal.accent.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: textColor ?? pal.accent)),
      );
}

/// Alt sayfa (bottom sheet) açar; klavye açılınca yukarı kayar.
Future<T?> showAppSheet<T>(BuildContext context, Widget Function(BuildContext) builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: builder(ctx),
    ),
  );
}

Future<bool> confirm(BuildContext context, String title, String message, {String ok = 'Sil'}) async {
  final p = pal;
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: TextStyle(color: p.text, fontWeight: FontWeight.w700)),
      content: Text(message, style: TextStyle(color: p.dim)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Vazgeç', style: TextStyle(color: p.dim))),
        TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ok, style: const TextStyle(color: kRed, fontWeight: FontWeight.w700))),
      ],
    ),
  );
  return r == true;
}

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
}

/// Sayı girişi için alan.
class NumField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? suffix;
  final String? hint;
  final bool decimal;
  final bool autofocus;
  const NumField(
      {super.key,
      required this.controller,
      required this.label,
      this.suffix,
      this.hint,
      this.decimal = true,
      this.autofocus = false});

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        autofocus: autofocus,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(decimal ? r'[0-9.,]' : r'[0-9]')),
        ],
        style: TextStyle(color: pal.text, fontSize: 17, fontWeight: FontWeight.w600),
        decoration: InputDecoration(labelText: label, suffixText: suffix, hintText: hint),
      );
}

// ======================= AY TAKVİMİ =======================
/// Pazartesi ile başlayan ay görünümü. Hem ana sayfada hem tarih seçmede kullanılır.
class MonthCalendar extends StatelessWidget {
  final DateTime month; // ayın herhangi bir günü
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;
  final ValueChanged<DateTime> onMonth;
  final bool allowFuture;
  final Color? Function(DateTime)? dotColor;
  final String? Function(DateTime)? label;
  const MonthCalendar({
    super.key,
    required this.month,
    required this.selected,
    required this.onSelect,
    required this.onMonth,
    this.allowFuture = false,
    this.dotColor,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final p = pal;
    final first = DateTime(month.year, month.month, 1);
    final daysIn = DateTime(month.year, month.month + 1, 0).day;
    final lead = first.weekday - 1;
    final cells = lead + daysIn;
    final rows = (cells / 7).ceil();
    final canNext = allowFuture || DateTime(month.year, month.month + 1, 1).isBefore(today.add(const Duration(days: 1)));
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        RoundIcon(Icons.chevron_left_rounded,
            onTap: () => onMonth(DateTime(month.year, month.month - 1, 1))),
        Expanded(
          child: Text('${kMonths[month.month - 1]} ${month.year}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.text)),
        ),
        Opacity(
          opacity: canNext ? 1 : 0.3,
          child: RoundIcon(Icons.chevron_right_rounded,
              onTap: () {
                if (canNext) onMonth(DateTime(month.year, month.month + 1, 1));
              }),
        ),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        for (final w in kWeekdaysShort)
          Expanded(
            child: Text(w,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: p.dim, fontWeight: FontWeight.w600)),
          ),
      ]),
      const SizedBox(height: 6),
      for (var r = 0; r < rows; r++)
        Row(children: [
          for (var c = 0; c < 7; c++)
            Expanded(child: _cell(context, r * 7 + c - lead + 1, daysIn)),
        ]),
    ]);
  }

  Widget _cell(BuildContext context, int day, int daysIn) {
    if (day < 1 || day > daysIn) return const SizedBox(height: 50);
    final p = pal;
    final d = DateTime(month.year, month.month, day);
    final isSel = dayOnly(selected) == d;
    final isToday = d == today;
    final future = isFuture(d);
    final dot = dotColor?.call(d);
    final lab = label?.call(d);
    final disabled = future && !allowFuture;
    return GestureDetector(
      onTap: () => onSelect(d),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 50,
        margin: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          color: isSel
              ? p.accent
              : dot != null
                  ? dot.withValues(alpha: 0.16)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isToday && !isSel ? Border.all(color: p.accent, width: 1.6) : null,
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('$day',
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSel || isToday ? FontWeight.w800 : FontWeight.w600,
                color: isSel
                    ? p.onAccent
                    : disabled
                        ? p.dim.withValues(alpha: 0.35)
                        : p.text,
              )),
          if (lab != null)
            Text(lab,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: TextStyle(
                    fontSize: 8.5,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: isSel ? p.onAccent : (dot ?? p.accent)))
          else if (dot != null)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(top: 3),
              decoration: BoxDecoration(color: isSel ? p.onAccent : dot, shape: BoxShape.circle),
            ),
        ]),
      ),
    );
  }
}

/// Tarih seçme penceresi (Türkçe takvim). İleri tarih seçilemez.
Future<DateTime?> pickDate(BuildContext context, DateTime initial) {
  return showDialog<DateTime>(
    context: context,
    builder: (ctx) {
      var month = DateTime(initial.year, initial.month, 1);
      var sel = initial;
      return StatefulBuilder(
        builder: (ctx, set) => Dialog(
          insetPadding: const EdgeInsets.all(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              MonthCalendar(
                month: month,
                selected: sel,
                onSelect: (d) {
                  if (isFuture(d)) return;
                  set(() => sel = d);
                },
                onMonth: (m) => set(() => month = m),
              ),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Vazgeç', style: TextStyle(color: pal.dim))),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, sel),
                    child: Text('Seç',
                        style: TextStyle(color: pal.accent, fontWeight: FontWeight.w700))),
              ]),
            ]),
          ),
        ),
      );
    },
  );
}
