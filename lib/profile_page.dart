import 'package:flutter/material.dart';
import 'measure_page.dart' show bmiLabel;
import 'models.dart';
import 'onboarding.dart';
import 'store.dart';
import 'theme.dart';
import 'ui.dart';

// ======================= PROFİLİM =======================
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final p = pal;
        final prof = store.profile;
        if (prof == null) return Scaffold(backgroundColor: p.bg);
        final bmi = store.bmi;
        return Scaffold(
          backgroundColor: p.bg,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text('Profilim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            actions: [
              RoundIcon(Icons.edit_rounded, color: Colors.white, tooltip: 'Düzenle', onTap: () => editProfile(context)),
              const SizedBox(width: 14),
            ],
          ),
          body: ListView(padding: EdgeInsets.zero, children: [
            SizedBox(
              height: 290,
              child: Stack(fit: StackFit.expand, children: [
                const Photo('dumbbell'),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withValues(alpha: 0.55), Colors.black.withValues(alpha: 0.2), p.bg],
                      stops: const [0, 0.45, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 10,
                  child: Row(children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.accent,
                        boxShadow: [BoxShadow(color: p.accent.withValues(alpha: 0.45), blurRadius: 24)],
                      ),
                      alignment: Alignment.center,
                      child: Text(prof.initials,
                          style: TextStyle(color: p.onAccent, fontSize: 32, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(prof.name,
                            style: TextStyle(color: p.text, fontSize: 24, fontWeight: FontWeight.w800, height: 1.15)),
                        Text('${store.totalCount} antrenman · ${store.regions.length} bölge',
                            style: TextStyle(color: p.dim, fontSize: 13.5)),
                      ]),
                    ),
                  ]),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.75,
                  children: [
                    _InfoTile(Icons.cake_rounded, 'Yaş', '${prof.age}'),
                    _InfoTile(Icons.height_rounded, 'Boy', '${fmtNum(prof.height)} cm'),
                    _InfoTile(Icons.monitor_weight_rounded, 'Güncel kilo', '${fmtNum(store.currentWeight)} kg'),
                    _InfoTile(Icons.speed_rounded, 'VKİ', bmi == null ? '—' : fmtNum(bmi),
                        sub: bmi == null ? null : bmiLabel(bmi)),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Kilo, Ölçümlerim sekmesine yeni ölçüm girdiğinde otomatik güncellenir.',
                    style: TextStyle(color: p.dim, fontSize: 12.5)),
                const SizedBox(height: 14),
                AccentButton('Bilgilerimi düzenle', icon: Icons.edit_rounded, onTap: () => editProfile(context)),
                const SectionTitle('Tema'),
                SizedBox(
                  height: 112,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    for (final t in kPalettes) _ThemeCard(t),
                  ]),
                ),
                const SectionTitle('Diğer'),
                Panel(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.restart_alt_rounded, color: kRed),
                    title: Text('Tüm verileri sıfırla', style: TextStyle(color: p.text, fontWeight: FontWeight.w600)),
                    subtitle: Text('Profil, program, takvim ve ölçümler silinir', style: TextStyle(color: p.dim)),
                    onTap: () async {
                      if (await confirm(context, 'Her şey silinsin mi?',
                          'Bu işlem geri alınamaz. Tüm kayıtların silinecek.',
                          ok: 'Sıfırla')) {
                        await store.resetAll();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const OnboardingPage()), (_) => false);
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Center(child: Text('Fit Takip · v1.0', style: TextStyle(color: p.dim, fontSize: 12))),
              ]),
            ),
          ]),
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? sub;
  const _InfoTile(this.icon, this.label, this.value, {this.sub});

  @override
  Widget build(BuildContext context) {
    final p = pal;
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: p.accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: p.accent, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: p.dim, fontSize: 12)),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: TextStyle(color: p.text, fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            if (sub != null) Text(sub!, style: TextStyle(color: p.accent, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final Palette t;
  const _ThemeCard(this.t);

  @override
  Widget build(BuildContext context) {
    final active = store.themeId == t.id;
    return GestureDetector(
      onTap: () => store.setTheme(t.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 96,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: t.bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: active ? t.accent : t.line, width: active ? 2.5 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 22, height: 22, decoration: BoxDecoration(color: t.accent, shape: BoxShape.circle)),
            const Spacer(),
            if (active) Icon(Icons.check_circle_rounded, color: t.accent, size: 20),
          ]),
          const Spacer(),
          Container(height: 6, width: 50, decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 4),
          Container(height: 6, width: 34, decoration: BoxDecoration(color: t.line, borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 8),
          Text(t.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: t.text, fontSize: 12.5, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

/// Profil bilgilerini düzenleme.
Future<void> editProfile(BuildContext context) async {
  await showAppSheet<void>(context, (ctx) => const _ProfileEditor());
}

class _ProfileEditor extends StatefulWidget {
  const _ProfileEditor();
  @override
  State<_ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<_ProfileEditor> {
  final prof = store.profile!;
  late final name = TextEditingController(text: prof.name);
  late final age = TextEditingController(text: '${prof.age}');
  late final height = TextEditingController(text: fmtNum(prof.height));
  late final weight = TextEditingController(text: fmtNum(store.currentWeight));

  @override
  void initState() {
    super.initState();
    for (final c in [name, age, height, weight]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [name, age, height, weight]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get valid =>
      name.text.trim().isNotEmpty &&
      (int.tryParse(age.text.trim()) ?? 0) > 0 &&
      (parseNum(height.text) ?? 0) > 50 &&
      (parseNum(weight.text) ?? 0) > 20;

  @override
  Widget build(BuildContext context) {
    final p = pal;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Bilgilerimi düzenle', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: p.text)),
        const SizedBox(height: 16),
        TextField(
          controller: name,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(color: p.text, fontSize: 17, fontWeight: FontWeight.w600),
          decoration: const InputDecoration(labelText: 'İsim Soyisim'),
        ),
        const SizedBox(height: 12),
        NumField(controller: age, label: 'Yaş', decimal: false),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: NumField(controller: height, label: 'Boy', suffix: 'cm')),
          const SizedBox(width: 12),
          Expanded(child: NumField(controller: weight, label: 'Kilo', suffix: 'kg')),
        ]),
        const SizedBox(height: 6),
        Text('Kiloyu değiştirirsen bugünün ölçümü olarak da kaydedilir.',
            style: TextStyle(color: p.dim, fontSize: 12.5)),
        const SizedBox(height: 20),
        AccentButton('Kaydet',
            icon: Icons.check_rounded,
            onTap: !valid
                ? null
                : () {
                    final newW = parseNum(weight.text)!;
                    final changed = (newW - store.currentWeight).abs() > 0.001;
                    store.updateProfile(
                      name: name.text.trim(),
                      age: int.parse(age.text.trim()),
                      height: parseNum(height.text)!,
                      weight: changed ? newW : prof.weight,
                    );
                    if (changed) store.setWeight(today, newW);
                    Navigator.pop(context);
                  }),
      ]),
    );
  }
}
