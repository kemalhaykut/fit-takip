import 'package:flutter/material.dart';
import 'calendar_page.dart';
import 'heatmap_page.dart';
import 'measure_page.dart';
import 'profile_page.dart';
import 'program_page.dart';
import 'rest_timer.dart';
import 'store.dart';
import 'theme.dart';

class HomeShell extends StatefulWidget {
  final int initialTab;
  final bool firstRun;
  const HomeShell({super.key, this.initialTab = 0, this.firstRun = false});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int tab = widget.initialTab;

  static const titles = ['Fit Takip', 'Programım', 'Ölçümlerim', 'Kas Haritası'];

  @override
  void initState() {
    super.initState();
    if (widget.firstRun) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Programını oluşturalım 🏋️',
                style: TextStyle(color: pal.text, fontWeight: FontWeight.w800)),
            content: Text(
              'Önce çalışma bölgelerini ekle (ör. Göğüs-Ön Kol, Sırt-Arka Kol, Omuz-Bacak, Kardiyo, Karın, Dinlenme).\n\n'
              'Sonra her bölgeye hareketlerini, set ve tekrar sayılarıyla gir.',
              style: TextStyle(color: pal.dim, height: 1.45),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Tamam', style: TextStyle(color: pal.accent, fontWeight: FontWeight.w700))),
            ],
          ),
        );
      });
    }
  }

  void goTab(int i) => setState(() => tab = i);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final p = pal;
        if (!store.hasProfile) return const SizedBox.shrink();
        return Scaffold(
          backgroundColor: p.bg,
          appBar: AppBar(
            titleSpacing: 18,
            title: Row(children: [
              if (tab == 0) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.asset('assets/icon.png', width: 32, height: 32),
                ),
                const SizedBox(width: 10),
              ],
              Text(titles[tab],
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: p.text)),
            ]),
            actions: [
              const TimerButton(),
              const SizedBox(width: 10),
              _ProfileButton(),
              const SizedBox(width: 14),
            ],
          ),
          body: IndexedStack(index: tab, children: [
            CalendarPage(onGoProgram: () => goTab(1)),
            // ignore: prefer_const_constructors
            ProgramPage(),
            // ignore: prefer_const_constructors
            MeasurePage(),
            // ignore: prefer_const_constructors
            HeatmapPage(),
          ]),
          bottomNavigationBar: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: goTab,
            height: 68,
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month_rounded),
                  label: 'Takvim'),
              NavigationDestination(
                  icon: Icon(Icons.fitness_center_outlined),
                  selectedIcon: Icon(Icons.fitness_center_rounded),
                  label: 'Programım'),
              NavigationDestination(
                  icon: Icon(Icons.monitor_weight_outlined),
                  selectedIcon: Icon(Icons.monitor_weight_rounded),
                  label: 'Ölçümlerim'),
              NavigationDestination(
                  icon: Icon(Icons.accessibility_new_outlined),
                  selectedIcon: Icon(Icons.accessibility_new_rounded),
                  label: 'Kas Haritası'),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = pal;
    return Tooltip(
      message: 'Profilim',
      child: Material(
        color: p.accent.withValues(alpha: 0.15),
        shape: CircleBorder(side: BorderSide(color: p.accent.withValues(alpha: 0.6), width: 1.5)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfilePage())),
          child: SizedBox(width: 40, height: 40, child: Icon(Icons.person_rounded, color: p.accent, size: 24)),
        ),
      ),
    );
  }
}
