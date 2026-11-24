import 'package:flutter/material.dart';
import 'models.dart';
import 'shell.dart';
import 'store.dart';
import 'theme.dart';
import 'ui.dart';

/// İlk açılış: profil bilgileri.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final name = TextEditingController();
  final age = TextEditingController();
  final height = TextEditingController();
  final weight = TextEditingController();

  bool get valid =>
      name.text.trim().isNotEmpty &&
      (int.tryParse(age.text.trim()) ?? 0) > 0 &&
      (parseNum(height.text) ?? 0) > 50 &&
      (parseNum(weight.text) ?? 0) > 20;

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

  void _start() {
    store.createProfile(Profile(
      name: name.text.trim(),
      age: int.parse(age.text.trim()),
      height: parseNum(height.text)!,
      weight: parseNum(weight.text)!,
    ));
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell(initialTab: 1, firstRun: true)));
  }

  @override
  Widget build(BuildContext context) {
    final p = pal;
    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(children: [
        const Positioned.fill(child: Photo('barbell')),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: 0.25), p.bg.withValues(alpha: 0.92), p.bg],
                stops: const [0, 0.42, 0.62],
              ),
            ),
          ),
        ),
        SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 40, 22, 30),
            children: [
              Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset('assets/icon.png', width: 52, height: 52),
                ),
                const SizedBox(width: 12),
                const Text('Fit Takip',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
              ]),
              const SizedBox(height: 110),
              Text('Hoş geldin!',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: p.text, height: 1.1)),
              const SizedBox(height: 6),
              Text('Başlamadan önce seni tanıyalım. Bu bilgiler profilinde saklanır, istediğin zaman değiştirebilirsin.',
                  style: TextStyle(color: p.dim, fontSize: 15, height: 1.45)),
              const SizedBox(height: 26),
              TextField(
                controller: name,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: p.text, fontSize: 17, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(labelText: 'İsim Soyisim', prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 14),
              NumField(controller: age, label: 'Yaş', decimal: false),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: NumField(controller: height, label: 'Boy', suffix: 'cm')),
                const SizedBox(width: 12),
                Expanded(child: NumField(controller: weight, label: 'Kilo', suffix: 'kg')),
              ]),
              const SizedBox(height: 28),
              AccentButton('Başlayalım', icon: Icons.arrow_forward_rounded, onTap: valid ? _start : null),
            ],
          ),
        ),
      ]),
    );
  }
}
