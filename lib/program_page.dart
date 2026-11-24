import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models.dart';
import 'store.dart';
import 'theme.dart';
import 'ui.dart';

// ======================= PROGRAMIM =======================
class ProgramPage extends StatelessWidget {
  const ProgramPage({super.key});

  static const suggestions = ['Göğüs-Ön Kol', 'Sırt-Arka Kol', 'Omuz-Bacak', 'Kardiyo', 'Karın', 'Dinlenme'];

  @override
  Widget build(BuildContext context) {
    final p = pal;
    final regions = store.regions;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
      children: [
        PageHeader(
          photo: 'bench',
          subtitle: '${regions.length} bölge · ${regions.fold<int>(0, (a, r) => a + r.exercises.length)} hareket',
          title: 'Antrenman\nProgramım',
          height: 160,
        ),
        const SizedBox(height: 6),
        SectionTitle('Bölgeler',
            action: TextButton.icon(
              onPressed: () => editRegion(context, null),
              icon: Icon(Icons.add_rounded, color: p.accent),
              label: Text('Bölge ekle', style: TextStyle(color: p.accent, fontWeight: FontWeight.w700)),
            )),
        if (regions.isEmpty)
          Panel(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Henüz bölge yok',
                  style: TextStyle(color: p.text, fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Bölgelerini kendin oluştur. Hızlı başlamak için bir öneriye dokunabilirsin:',
                  style: TextStyle(color: p.dim, height: 1.4)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in suggestions)
                  ActionChip(
                    label: Text(s),
                    avatar: Icon(Icons.add_rounded, size: 18, color: p.accent),
                    onPressed: () => editRegion(context, null, presetName: s),
                  ),
              ]),
              const SizedBox(height: 14),
              AccentButton('Bölge ekle', icon: Icons.add_rounded, onTap: () => editRegion(context, null)),
            ]),
          ),
        if (regions.isNotEmpty)
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            proxyDecorator: (child, _, __) => Material(color: Colors.transparent, child: child),
            onReorderItem: store.moveRegion,
            children: [
              for (var i = 0; i < regions.length; i++)
                Padding(
                  key: ValueKey(regions[i].id),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RegionCard(region: regions[i], index: i),
                ),
            ],
          ),
        if (regions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('İpucu: Sıralamayı değiştirmek için kartın sağındaki tutamaktan basılı tutup sürükle.',
                textAlign: TextAlign.center, style: TextStyle(color: p.dim, fontSize: 12)),
          ),
      ],
    );
  }
}

class _RegionCard extends StatelessWidget {
  final Region region;
  final int index;
  const _RegionCard({required this.region, required this.index});

  @override
  Widget build(BuildContext context) {
    final c = regionColor(region.id, rest: region.rest);
    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => RegionDetailPage(regionId: region.id))),
      child: SizedBox(
        height: 140,
        child: PhotoShade(
          photo: region.photo,
          radius: 24,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 10, 16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(region.rest ? 'DİNLENME' : '${region.exercises.length} HAREKET',
                          style: TextStyle(color: c, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                    ]),
                    const SizedBox(height: 2),
                    Text(region.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800)),
                    if (region.exercises.isNotEmpty)
                      Text(region.exercises.map((e) => e.name).join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12.5)),
                  ],
                ),
              ),
              Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                RoundIcon(Icons.edit_rounded,
                    color: Colors.white, size: 38, tooltip: 'Düzenle', onTap: () => editRegion(context, region)),
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.drag_indicator_rounded, color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

// ======================= BÖLGE DÜZENLE =======================
Future<void> editRegion(BuildContext context, Region? region, {String? presetName}) async {
  await showAppSheet<void>(context, (ctx) => _RegionEditor(region: region, presetName: presetName));
}

class _RegionEditor extends StatefulWidget {
  final Region? region;
  final String? presetName;
  const _RegionEditor({this.region, this.presetName});
  @override
  State<_RegionEditor> createState() => _RegionEditorState();
}

class _RegionEditorState extends State<_RegionEditor> {
  late final TextEditingController name;
  late bool rest;
  late Set<String> muscles;
  late String photo;
  bool musclesTouched = false;
  bool photoTouched = false;

  @override
  void initState() {
    super.initState();
    final r = widget.region;
    name = TextEditingController(text: r?.name ?? widget.presetName ?? '');
    rest = r?.rest ?? guessRest(name.text);
    muscles = (r?.muscles ?? guessMuscles(name.text)).toSet();
    photo = r?.photo ?? guessPhoto(name.text);
    musclesTouched = r != null;
    photoTouched = r != null;
    name.addListener(_onName);
  }

  void _onName() {
    setState(() {
      if (!musclesTouched) {
        muscles = guessMuscles(name.text).toSet();
        rest = guessRest(name.text);
      }
      if (!photoTouched) photo = guessPhoto(name.text);
    });
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  void _save() {
    final r = widget.region;
    store.saveRegion(Region(
      id: r?.id ?? newId(),
      name: name.text.trim(),
      rest: rest,
      photo: photo,
      muscles: rest ? [] : muscles.toList(),
      exercises: r?.exercises ?? [],
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = pal;
    final editing = widget.region != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(editing ? 'Bölgeyi düzenle' : 'Yeni bölge',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: p.text)),
        const SizedBox(height: 16),
        TextField(
          controller: name,
          autofocus: !editing && widget.presetName == null,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(color: p.text, fontSize: 17, fontWeight: FontWeight.w600),
          decoration: const InputDecoration(labelText: 'Bölge adı', hintText: 'ör. Göğüs-Ön Kol'),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: rest,
          activeThumbColor: p.accent,
          title: Text('Dinlenme günü', style: TextStyle(color: p.text, fontWeight: FontWeight.w600)),
          subtitle: Text('Sayaçlara ve kas haritasına sayılmaz', style: TextStyle(color: p.dim, fontSize: 12.5)),
          onChanged: (v) => setState(() {
            rest = v;
            musclesTouched = true;
          }),
        ),
        if (!rest) ...[
          const SizedBox(height: 6),
          Text('Çalışan kaslar (kas haritası için)',
              style: TextStyle(color: p.dim, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final m in kMuscleGroups)
              FilterChip(
                label: Text(m.name),
                selected: muscles.contains(m.key),
                showCheckmark: false,
                labelStyle: TextStyle(
                    color: muscles.contains(m.key) ? p.onAccent : p.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
                onSelected: (v) => setState(() {
                  musclesTouched = true;
                  v ? muscles.add(m.key) : muscles.remove(m.key);
                }),
              ),
          ]),
        ],
        const SizedBox(height: 16),
        Text('Kapak fotoğrafı', style: TextStyle(color: p.dim, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SizedBox(
          height: 86,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (final key in kPhotos.keys)
              GestureDetector(
                onTap: () => setState(() {
                  photo = key;
                  photoTouched = true;
                }),
                child: Container(
                  width: 110,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: photo == key ? p.accent : Colors.transparent, width: 3),
                  ),
                  child: PhotoShade(
                    photo: key,
                    radius: 13,
                    strength: 0.8,
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(kPhotos[key]!,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 22),
        AccentButton(editing ? 'Kaydet' : 'Bölgeyi ekle',
            icon: Icons.check_rounded, onTap: name.text.trim().isEmpty ? null : _save),
        if (editing) ...[
          const SizedBox(height: 10),
          AccentButton('Bölgeyi sil', icon: Icons.delete_outline_rounded, outlined: true, color: kRed,
              onTap: () async {
            final r = widget.region!;
            if (await confirm(context, 'Bölge silinsin mi?',
                '"${r.name}" ve içindeki ${r.exercises.length} hareket silinecek. Takvimdeki geçmiş kayıtlar kalır.')) {
              store.deleteRegion(r);
              if (context.mounted) Navigator.pop(context);
            }
          }),
        ],
      ]),
    );
  }
}

// ======================= BÖLGE DETAYI (hareketler) =======================
class RegionDetailPage extends StatelessWidget {
  final String regionId;
  const RegionDetailPage({super.key, required this.regionId});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final p = pal;
        final region = store.regionById(regionId);
        if (region == null) return Scaffold(backgroundColor: p.bg);
        return Scaffold(
          backgroundColor: p.bg,
          floatingActionButton: region.rest
              ? null
              : FloatingActionButton.extended(
                  backgroundColor: p.accent,
                  foregroundColor: p.onAccent,
                  onPressed: () => editExercise(context, region, null),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Hareket ekle', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
          body: CustomScrollView(slivers: [
            _PhotoAppBar(
              photo: region.photo,
              title: region.name,
              subtitle: region.rest ? 'Dinlenme günü' : '${region.exercises.length} hareket',
              actions: [
                RoundIcon(Icons.edit_rounded, color: Colors.white, onTap: () => editRegion(context, region)),
                const SizedBox(width: 12),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (region.muscles.isNotEmpty)
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      for (final m in region.muscles) Pill(muscleName(m)),
                    ]),
                  const SizedBox(height: 12),
                  if (region.rest)
                    Panel(
                      child: Text('Dinlenme günü. Kaslar dinlenirken büyür 😴',
                          style: TextStyle(color: p.dim, fontSize: 15)),
                    )
                  else if (region.exercises.isEmpty)
                    Panel(
                      child: Column(children: [
                        Icon(Icons.fitness_center_rounded, color: p.accent, size: 40),
                        const SizedBox(height: 8),
                        Text('Henüz hareket yok',
                            style: TextStyle(color: p.text, fontSize: 17, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('Sağ alttaki "Hareket ekle" ile ilk hareketini gir.\nÖrn: Dumbbell Bench Press · 4 x 10',
                            textAlign: TextAlign.center, style: TextStyle(color: p.dim, height: 1.4)),
                      ]),
                    )
                  else
                    for (var i = 0; i < region.exercises.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ExerciseTile(region: region, exercise: region.exercises[i], index: i, date: today),
                      ),
                ]),
              ),
            ),
          ]),
        );
      },
    );
  }
}

class _PhotoAppBar extends StatelessWidget {
  final String photo;
  final String title;
  final String subtitle;
  final List<Widget> actions;
  const _PhotoAppBar({required this.photo, required this.title, required this.subtitle, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    final p = pal;
    return SliverAppBar(
      expandedHeight: 230,
      pinned: true,
      backgroundColor: p.bg,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 14, end: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 19)),
            Text(subtitle,
                style: TextStyle(color: p.accent, fontWeight: FontWeight.w600, fontSize: 10.5)),
          ],
        ),
        background: Stack(fit: StackFit.expand, children: [
          Photo(photo),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: 0.45), Colors.black.withValues(alpha: 0.1), p.bg],
                stops: const [0, 0.4, 1],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Hareket satırı: ad, set x tekrar, son kullanılan ağırlıklar, kalem.
class ExerciseTile extends StatelessWidget {
  final Region region;
  final Exercise exercise;
  final int index;
  final DateTime date;
  final bool showProgress;
  const ExerciseTile(
      {super.key,
      required this.region,
      required this.exercise,
      required this.index,
      required this.date,
      this.showProgress = false});

  @override
  Widget build(BuildContext context) {
    final p = pal;
    final todaySets = store.setsFor(exercise, date);
    final prev = store.previousSession(exercise, date.add(const Duration(days: 1)));
    final shown = todaySets != null && todaySets.any((s) => !s.isEmpty) ? Session(dkey(date), todaySets) : prev;
    final doneCount = todaySets?.where((s) => s.weight != null || s.reps != null).length ?? 0;
    final done = showProgress && doneCount >= exercise.sets;
    return Panel(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      border: done ? p.accent.withValues(alpha: 0.8) : null,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ExerciseLogPage(regionId: region.id, exerciseId: exercise.id, date: date))),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: done ? p.accent : p.accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: done
              ? Icon(Icons.check_rounded, color: p.onAccent)
              : Text('${index + 1}',
                  style: TextStyle(color: p.accent, fontWeight: FontWeight.w800, fontSize: 17)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(exercise.name, style: TextStyle(color: p.text, fontSize: 16.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Row(children: [
              Pill(exercise.scheme),
              if (showProgress) ...[
                const SizedBox(width: 6),
                Text('$doneCount/${exercise.sets} set', style: TextStyle(color: p.dim, fontSize: 12.5)),
              ],
            ]),
            if (shown != null && shown.sets.any((s) => s.weight != null)) ...[
              const SizedBox(height: 5),
              Text(
                '${shown.date == dkey(date) ? (date == today ? "Bugün" : "Bu gün") : "Son (${fmtShort(parseKey(shown.date))})"}: '
                '${shown.sets.where((s) => s.weight != null).map((s) => fmtNum(s.weight!)).join(' · ')} kg',
                style: TextStyle(color: p.dim, fontSize: 12.5),
              ),
            ],
          ]),
        ),
        IconButton(
          icon: Icon(Icons.edit_rounded, color: p.dim, size: 21),
          tooltip: 'Düzenle',
          onPressed: () => editExercise(context, region, exercise),
        ),
      ]),
    );
  }
}

// ======================= HAREKET DÜZENLE =======================
Future<void> editExercise(BuildContext context, Region region, Exercise? ex) async {
  await showAppSheet<void>(context, (ctx) => _ExerciseEditor(region: region, exercise: ex));
}

class _ExerciseEditor extends StatefulWidget {
  final Region region;
  final Exercise? exercise;
  const _ExerciseEditor({required this.region, this.exercise});
  @override
  State<_ExerciseEditor> createState() => _ExerciseEditorState();
}

class _ExerciseEditorState extends State<_ExerciseEditor> {
  late final TextEditingController name = TextEditingController(text: widget.exercise?.name ?? '');
  late final TextEditingController reps = TextEditingController(text: widget.exercise?.reps ?? '10');
  late int sets = widget.exercise?.sets ?? 4;

  @override
  void initState() {
    super.initState();
    name.addListener(() => setState(() {}));
    reps.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    name.dispose();
    reps.dispose();
    super.dispose();
  }

  void _save() {
    store.saveExercise(
        widget.region,
        Exercise(
          id: widget.exercise?.id ?? newId(),
          name: name.text.trim(),
          sets: sets,
          reps: reps.text.trim(),
        ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = pal;
    final editing = widget.exercise != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(editing ? 'Hareketi düzenle' : 'Yeni hareket',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: p.text)),
        Text(widget.region.name, style: TextStyle(color: p.accent, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        TextField(
          controller: name,
          autofocus: !editing,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(color: p.text, fontSize: 17, fontWeight: FontWeight.w600),
          decoration: const InputDecoration(labelText: 'Hareket adı', hintText: 'ör. Dumbbell Bench Press'),
        ),
        const SizedBox(height: 18),
        Text('Kaç set?', style: TextStyle(color: p.dim, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(children: [
          RoundIcon(Icons.remove_rounded, size: 48, onTap: () => setState(() => sets = (sets - 1).clamp(1, 12))),
          Expanded(
            child: Text('$sets set',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.text, fontSize: 26, fontWeight: FontWeight.w800)),
          ),
          RoundIcon(Icons.add_rounded, size: 48, color: p.accent, onTap: () => setState(() => sets = (sets + 1).clamp(1, 12))),
        ]),
        const SizedBox(height: 18),
        TextField(
          controller: reps,
          style: TextStyle(color: p.text, fontSize: 17, fontWeight: FontWeight.w600),
          decoration: const InputDecoration(
              labelText: 'Kaç tekrar?', hintText: 'ör. 10  ·  8-12  ·  30 sn', suffixText: 'tekrar'),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final r in ['6', '8', '10', '12', '15', '8-12'])
            ActionChip(label: Text(r), onPressed: () => reps.text = r),
        ]),
        const SizedBox(height: 22),
        AccentButton(editing ? 'Kaydet' : 'Hareketi ekle',
            icon: Icons.check_rounded,
            onTap: name.text.trim().isEmpty || reps.text.trim().isEmpty ? null : _save),
        if (editing) ...[
          const SizedBox(height: 10),
          AccentButton('Hareketi sil', icon: Icons.delete_outline_rounded, outlined: true, color: kRed,
              onTap: () async {
            if (await confirm(context, 'Hareket silinsin mi?', '"${widget.exercise!.name}" programdan silinecek.')) {
              store.deleteExercise(widget.region, widget.exercise!);
              if (context.mounted) Navigator.pop(context);
            }
          }),
        ],
      ]),
    );
  }
}

// ======================= GÜNÜN İDMANI =======================
class RegionWorkoutPage extends StatelessWidget {
  final Region region;
  final DateTime date;
  const RegionWorkoutPage({super.key, required this.region, required this.date});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final p = pal;
        final r = store.regionById(region.id) ?? region;
        return Scaffold(
          backgroundColor: p.bg,
          body: CustomScrollView(slivers: [
            _PhotoAppBar(
              photo: r.photo,
              title: r.name,
              subtitle: date == today ? 'Bugünün idmanı' : fmtLong(date),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text('Harekete dokun, her setin ağırlığını ve notunu yaz.',
                      style: TextStyle(color: p.dim, fontSize: 13.5)),
                  const SizedBox(height: 12),
                  for (var i = 0; i < r.exercises.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ExerciseTile(
                          region: r, exercise: r.exercises[i], index: i, date: date, showProgress: true),
                    ),
                ]),
              ),
            ),
          ]),
        );
      },
    );
  }
}

// ======================= SET KAYDI (ağırlık + not) =======================
class ExerciseLogPage extends StatefulWidget {
  final String regionId;
  final String exerciseId;
  final DateTime date;
  const ExerciseLogPage({super.key, required this.regionId, required this.exerciseId, required this.date});
  @override
  State<ExerciseLogPage> createState() => _ExerciseLogPageState();
}

class _SetRow {
  final TextEditingController w;
  final TextEditingController r;
  final TextEditingController n;
  bool showNote;
  _SetRow(SetLog? s)
      : w = TextEditingController(text: s?.weight == null ? '' : fmtNum(s!.weight!)),
        r = TextEditingController(text: s?.reps?.toString() ?? ''),
        n = TextEditingController(text: s?.note ?? ''),
        showNote = (s?.note ?? '').isNotEmpty;
  void dispose() {
    w.dispose();
    r.dispose();
    n.dispose();
  }

  SetLog toLog() => SetLog(weight: parseNum(w.text), reps: int.tryParse(r.text.trim()), note: n.text.trim());
}

class _ExerciseLogPageState extends State<ExerciseLogPage> {
  late DateTime date = widget.date;
  final List<_SetRow> rows = [];
  bool dirty = false;

  Region? get region => store.regionById(widget.regionId);
  Exercise? get exercise {
    final r = region;
    if (r == null) return null;
    for (final e in r.exercises) {
      if (e.id == widget.exerciseId) return e;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadRows();
    store.addListener(_onStore);
  }

  void _loadRows() {
    for (final r in rows) {
      r.dispose();
    }
    rows.clear();
    final ex = exercise;
    if (ex == null) return;
    final saved = store.setsFor(ex, date) ?? [];
    final n = saved.length > ex.sets ? saved.length : ex.sets;
    for (var i = 0; i < n; i++) {
      final row = _SetRow(i < saved.length ? saved[i] : null);
      row.w.addListener(_markDirty);
      row.r.addListener(_markDirty);
      row.n.addListener(_markDirty);
      rows.add(row);
    }
    savedSig = _sig();
    dirty = false;
  }

  String savedSig = '';
  String _sig() => rows.map((r) => '${r.w.text.trim()}|${r.r.text.trim()}|${r.n.text.trim()}').join(';');

  void _markDirty() {
    final d = _sig() != savedSig;
    setState(() => dirty = d);
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    store.removeListener(_onStore);
    for (final r in rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _save() {
    final ex = exercise;
    final reg = region;
    if (ex == null || reg == null) return;
    final logs = rows.map((r) => r.toLog()).toList();
    while (logs.length > ex.sets && logs.last.isEmpty) {
      logs.removeLast();
    }
    store.saveSets(ex, date, logs);
    final hasData = logs.any((s) => !s.isEmpty);
    var msg = 'Kaydedildi ✓';
    if (hasData && store.dayEntry(date) == null && !reg.rest) {
      store.setDay(date, reg);
      msg = 'Kaydedildi ✓ · ${fmtShort(date)} takvime "${reg.name}" olarak işlendi';
    }
    HapticFeedback.mediumImpact();
    savedSig = _sig();
    setState(() => dirty = false);
    toast(context, msg);
  }

  Future<void> _changeDate() async {
    final d = await pickDate(context, date);
    if (d == null || d == date) return;
    setState(() {
      date = d;
      _loadRows();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = pal;
    final ex = exercise;
    final reg = region;
    if (ex == null || reg == null) {
      return Scaffold(backgroundColor: p.bg, appBar: AppBar(), body: const SizedBox.shrink());
    }
    final prev = store.previousSession(ex, date);
    final hist = store.history(ex).where((s) => s.date != dkey(date)).toList();
    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await confirm(context, 'Kaydedilmedi', 'Girdiğin ağırlıklar kaydedilmedi. Çıkılsın mı?',
            ok: 'Çık');
        if (leave && context.mounted) {
          setState(() => dirty = false);
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: p.bg,
        appBar: AppBar(
          title: Text(ex.name, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              icon: Icon(Icons.edit_rounded, color: p.dim),
              tooltip: 'Hareketi düzenle',
              onPressed: () async {
                await editExercise(context, reg, ex);
                if (mounted) setState(_loadRows);
              },
            ),
            const SizedBox(width: 6),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: AccentButton(dirty ? 'Kaydet' : 'Kaydedildi', icon: Icons.save_rounded, onTap: dirty ? _save : null),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
          children: [
            Row(children: [
              Pill(ex.scheme),
              const SizedBox(width: 8),
              Pill(reg.name, color: p.card, textColor: p.dim),
              const Spacer(),
              TextButton.icon(
                onPressed: _changeDate,
                icon: Icon(Icons.calendar_today_rounded, size: 16, color: p.accent),
                label: Text(date == today ? 'Bugün' : fmtDate(date),
                    style: TextStyle(color: p.accent, fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 10),
            if (prev != null) _PrevCard(session: prev),
            const SizedBox(height: 6),
            for (var i = 0; i < rows.length; i++)
              _SetCard(
                index: i,
                row: rows[i],
                targetReps: ex.reps,
                prev: prev != null && i < prev.sets.length ? prev.sets[i] : null,
                onToggleNote: () => setState(() => rows[i].showNote = !rows[i].showNote),
                onRemove: i >= ex.sets
                    ? () => setState(() {
                          rows.removeAt(i).dispose();
                          dirty = _sig() != savedSig;
                        })
                    : null,
              ),
            TextButton.icon(
              onPressed: () => setState(() {
                final row = _SetRow(null);
                row.w.addListener(_markDirty);
                row.r.addListener(_markDirty);
                row.n.addListener(_markDirty);
                rows.add(row);
                dirty = _sig() != savedSig;
              }),
              icon: Icon(Icons.add_rounded, color: p.accent),
              label: Text('Ekstra set ekle', style: TextStyle(color: p.accent, fontWeight: FontWeight.w700)),
            ),
            if (hist.isNotEmpty) ...[
              const SectionTitle('Geçmiş idmanlar'),
              for (final s in hist.take(30)) _HistoryCard(exercise: ex, session: s),
            ],
          ],
        ),
      ),
    );
  }
}

class _PrevCard extends StatelessWidget {
  final Session session;
  const _PrevCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final p = pal;
    return Panel(
      color: p.accent.withValues(alpha: 0.08),
      border: p.accent.withValues(alpha: 0.35),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.history_rounded, color: p.accent, size: 20),
          const SizedBox(width: 8),
          Text('Önceki idman · ${fmtShort(parseKey(session.date))}',
              style: TextStyle(color: p.accent, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (var i = 0; i < session.sets.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(12)),
              child: Text(
                  '${i + 1}. set: ${session.sets[i].weight == null ? "—" : "${fmtNum(session.sets[i].weight!)} kg"}'
                  '${session.sets[i].reps == null ? "" : " × ${session.sets[i].reps}"}',
                  style: TextStyle(color: p.text, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
        ]),
        for (var i = 0; i < session.sets.length; i++)
          if (session.sets[i].note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('📝 ${i + 1}. set: ${session.sets[i].note}', style: TextStyle(color: p.dim, fontSize: 13)),
            ),
      ]),
    );
  }
}

class _SetCard extends StatelessWidget {
  final int index;
  final _SetRow row;
  final String targetReps;
  final SetLog? prev;
  final VoidCallback onToggleNote;
  final VoidCallback? onRemove;
  const _SetCard(
      {required this.index,
      required this.row,
      required this.targetReps,
      required this.prev,
      required this.onToggleNote,
      this.onRemove});

  @override
  Widget build(BuildContext context) {
    final p = pal;
    final cur = parseNum(row.w.text);
    Widget? trend;
    if (cur != null && prev?.weight != null) {
      final diff = cur - prev!.weight!;
      if (diff.abs() > 0.001) {
        trend = Text('${diff > 0 ? "▲" : "▼"} ${fmtNum(diff.abs())}',
            style: TextStyle(color: diff > 0 ? kGreen : kRed, fontSize: 12, fontWeight: FontWeight.w700));
      }
    }
    final hasNote = row.n.text.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Panel(
        padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
        child: Column(children: [
          Row(children: [
            SizedBox(
              width: 52,
              child: Column(children: [
                Text('${index + 1}.',
                    style: TextStyle(color: p.accent, fontSize: 22, fontWeight: FontWeight.w800, height: 1.1)),
                Text('SET', style: TextStyle(color: p.dim, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1)),
              ]),
            ),
            Expanded(
              flex: 5,
              child: TextField(
                controller: row.w,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                style: TextStyle(color: p.text, fontSize: 18, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  labelText: 'Ağırlık',
                  suffixText: 'kg',
                  hintText: prev?.weight == null ? null : fmtNum(prev!.weight!),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: TextField(
                controller: row.r,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(color: p.text, fontSize: 18, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  labelText: 'Tekrar',
                  hintText: prev?.reps?.toString() ?? targetReps,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Not al',
              onPressed: onToggleNote,
              icon: Icon(hasNote ? Icons.sticky_note_2_rounded : Icons.note_add_outlined,
                  color: hasNote ? p.accent : p.dim),
            ),
          ]),
          if (trend != null || prev?.weight != null || onRemove != null)
            Padding(
              padding: const EdgeInsets.only(left: 52, top: 6, right: 8),
              child: Row(children: [
                if (prev?.weight != null)
                  Text('Önceki: ${fmtNum(prev!.weight!)} kg${prev!.reps == null ? "" : " × ${prev!.reps}"}',
                      style: TextStyle(color: p.dim, fontSize: 12)),
                const SizedBox(width: 8),
                if (trend != null) trend,
                const Spacer(),
                if (onRemove != null)
                  GestureDetector(
                    onTap: onRemove,
                    child: const Text('Kaldır', style: TextStyle(color: kRed, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
              ]),
            ),
          if (row.showNote)
            Padding(
              padding: const EdgeInsets.only(left: 52, top: 10, right: 8),
              child: TextField(
                controller: row.n,
                maxLines: 2,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(color: p.text, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'ör. Son tekrarlarda çok zorlandım',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Exercise exercise;
  final Session session;
  const _HistoryCard({required this.exercise, required this.session});

  @override
  Widget build(BuildContext context) {
    final p = pal;
    final d = parseKey(session.date);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Panel(
        padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(fmtLong(d), style: TextStyle(color: p.text, fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(width: 8),
                if (session.maxWeight != null) Pill('max ${fmtNum(session.maxWeight!)} kg'),
              ]),
              const SizedBox(height: 4),
              Text(
                  session.sets
                      .map((s) => s.weight == null ? '—' : '${fmtNum(s.weight!)}${s.reps == null ? "" : "×${s.reps}"}')
                      .join('  ·  '),
                  style: TextStyle(color: p.dim, fontSize: 13.5)),
              for (var i = 0; i < session.sets.length; i++)
                if (session.sets[i].note.isNotEmpty)
                  Text('📝 ${i + 1}. set: ${session.sets[i].note}', style: TextStyle(color: p.dim, fontSize: 12.5)),
            ]),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: p.dim, size: 20),
            onPressed: () async {
              if (await confirm(context, 'Kayıt silinsin mi?', '${fmtDate(d)} tarihli set kayıtları silinecek.')) {
                store.deleteSession(exercise, session.date);
              }
            },
          ),
        ]),
      ),
    );
  }
}
