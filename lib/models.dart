// Veri modelleri ve tarih/sayı yardımcıları.

String newId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

// ---------------- Tarih ----------------
DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime get today => dayOnly(DateTime.now());

String dkey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseKey(String k) {
  final p = k.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

bool isFuture(DateTime d) => dayOnly(d).isAfter(today);

/// Haftanın pazartesisi.
DateTime weekStart(DateTime d) => dayOnly(d).subtract(Duration(days: d.weekday - 1));

const kMonths = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
];
const kWeekdaysShort = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
const kWeekdays = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

String fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
String fmtLong(DateTime d) => '${d.day} ${kMonths[d.month - 1]} ${d.year}, ${kWeekdays[d.weekday - 1]}';
String fmtShort(DateTime d) => '${d.day} ${kMonths[d.month - 1]}';

// ---------------- Sayı ----------------
double? parseNum(String s) {
  final t = s.trim().replaceAll(',', '.');
  if (t.isEmpty) return null;
  return double.tryParse(t);
}

String fmtNum(double v) {
  final r = (v * 10).roundToDouble() / 10;
  if (r == r.roundToDouble()) return r.toInt().toString();
  return r.toStringAsFixed(1).replaceAll('.', ',');
}

// ---------------- Kas grupları ----------------
class MuscleGroup {
  final String key;
  final String name;
  const MuscleGroup(this.key, this.name);
}

const kMuscleGroups = [
  MuscleGroup('chest', 'Göğüs'),
  MuscleGroup('shoulders', 'Omuz'),
  MuscleGroup('biceps', 'Ön Kol (Biceps)'),
  MuscleGroup('triceps', 'Arka Kol (Triceps)'),
  MuscleGroup('forearms', 'Önkol / Bilek'),
  MuscleGroup('back', 'Sırt (Kanat)'),
  MuscleGroup('traps', 'Trapez'),
  MuscleGroup('lowerback', 'Bel'),
  MuscleGroup('abs', 'Karın'),
  MuscleGroup('quads', 'Ön Bacak'),
  MuscleGroup('hamstrings', 'Arka Bacak'),
  MuscleGroup('glutes', 'Kalça'),
  MuscleGroup('calves', 'Baldır'),
  MuscleGroup('cardio', 'Kardiyo'),
];

String muscleName(String key) =>
    kMuscleGroups.firstWhere((m) => m.key == key, orElse: () => MuscleGroup(key, key)).name;

String _norm(String s) => s
    .replaceAll('İ', 'i')
    .replaceAll('I', 'ı')
    .toLowerCase()
    .replaceAll('ı', 'i')
    .replaceAll('ş', 's')
    .replaceAll('ğ', 'g')
    .replaceAll('ü', 'u')
    .replaceAll('ö', 'o')
    .replaceAll('ç', 'c');

/// Bölge adından kas gruplarını tahmin eder ("Göğüs-Ön Kol" → chest, biceps).
List<String> guessMuscles(String name) {
  final n = _norm(name);
  final res = <String>{};
  if (n.contains('gogus') || n.contains('chest')) res.add('chest');
  if (n.contains('sirt') || n.contains('back') || n.contains('kanat')) res.addAll(['back', 'traps']);
  if (n.contains('omuz') || n.contains('shoulder')) res.add('shoulders');
  if (n.contains('arka kol') || n.contains('triceps') || n.contains('triseps')) res.add('triceps');
  if (RegExp(r'on ?kol').hasMatch(n) || n.contains('biceps') || n.contains('biseps')) res.add('biceps');
  if (n.contains('bilek') || n.contains('forearm')) res.add('forearms');
  if (n.contains('kol') && !res.contains('biceps') && !res.contains('triceps')) {
    res.addAll(['biceps', 'triceps']);
  }
  if (n.contains('bacak') || n.contains('leg')) res.addAll(['quads', 'hamstrings', 'glutes', 'calves']);
  if (n.contains('kalca') || n.contains('glute')) res.add('glutes');
  if (n.contains('baldir') || n.contains('calf')) res.add('calves');
  if (n.contains('karin') || n.contains('abs') || n.contains('core')) res.add('abs');
  if (n.contains('bel')) res.add('lowerback');
  if (n.contains('trapez')) res.add('traps');
  if (n.contains('kardiyo') || n.contains('cardio') || n.contains('kosu')) res.add('cardio');
  return res.toList();
}

bool guessRest(String name) {
  final n = _norm(name);
  return n.contains('dinlen') || n.contains('rest') || n.contains('off');
}

/// Bölge adına göre fotoğraf.
String guessPhoto(String name) {
  final n = _norm(name);
  if (guessRest(name)) return 'rest';
  if (n.contains('kardiyo') || n.contains('cardio') || n.contains('kosu')) return 'cardio';
  if (n.contains('gogus')) return 'chest';
  if (n.contains('sirt')) return 'back';
  if (n.contains('bacak')) return 'leg';
  if (n.contains('omuz')) return 'shoulder';
  if (n.contains('karin')) return 'abs';
  if (n.contains('kol')) return 'arm';
  return 'dumbbell';
}

// ---------------- Modeller ----------------
class Profile {
  String name;
  int age;
  double height;
  double weight;
  Profile({required this.name, required this.age, required this.height, required this.weight});

  Map<String, dynamic> toJson() => {'name': name, 'age': age, 'height': height, 'weight': weight};
  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        name: j['name'] as String? ?? '',
        age: (j['age'] as num?)?.toInt() ?? 0,
        height: (j['height'] as num?)?.toDouble() ?? 0,
        weight: (j['weight'] as num?)?.toDouble() ?? 0,
      );

  String get firstName => name.trim().split(RegExp(r'\s+')).first;
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class Exercise {
  String id;
  String name;
  int sets;
  String reps;
  Exercise({required this.id, required this.name, required this.sets, required this.reps});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'sets': sets, 'reps': reps};
  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        sets: (j['sets'] as num?)?.toInt() ?? 3,
        reps: '${j['reps'] ?? '10'}',
      );
  String get scheme => '$sets x $reps';
}

class Region {
  String id;
  String name;
  bool rest;
  String photo;
  List<String> muscles;
  List<Exercise> exercises;
  Region({
    required this.id,
    required this.name,
    required this.rest,
    required this.photo,
    required this.muscles,
    required this.exercises,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rest': rest,
        'photo': photo,
        'muscles': muscles,
        'exercises': [for (final e in exercises) e.toJson()],
      };
  factory Region.fromJson(Map<String, dynamic> j) => Region(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        rest: j['rest'] as bool? ?? false,
        photo: j['photo'] as String? ?? 'dumbbell',
        muscles: [for (final m in (j['muscles'] as List? ?? const [])) m as String],
        exercises: [
          for (final e in (j['exercises'] as List? ?? const []))
            Exercise.fromJson(e as Map<String, dynamic>)
        ],
      );
}

/// Bir güne işlenen idman. Bölge silinse bile adı görünsün diye anlık kopya tutulur.
class DayEntry {
  String regionId;
  String name;
  bool rest;
  List<String> muscles;
  String photo;
  DayEntry({
    required this.regionId,
    required this.name,
    required this.rest,
    required this.muscles,
    required this.photo,
  });

  factory DayEntry.of(Region r) => DayEntry(
      regionId: r.id, name: r.name, rest: r.rest, muscles: List.of(r.muscles), photo: r.photo);

  Map<String, dynamic> toJson() =>
      {'regionId': regionId, 'name': name, 'rest': rest, 'muscles': muscles, 'photo': photo};
  factory DayEntry.fromJson(Map<String, dynamic> j) => DayEntry(
        regionId: j['regionId'] as String? ?? '',
        name: j['name'] as String? ?? '',
        rest: j['rest'] as bool? ?? false,
        muscles: [for (final m in (j['muscles'] as List? ?? const [])) m as String],
        photo: j['photo'] as String? ?? 'dumbbell',
      );
}

class SetLog {
  double? weight;
  int? reps;
  String note;
  SetLog({this.weight, this.reps, this.note = ''});

  bool get isEmpty => weight == null && reps == null && note.trim().isEmpty;

  Map<String, dynamic> toJson() => {
        if (weight != null) 'w': weight,
        if (reps != null) 'r': reps,
        if (note.isNotEmpty) 'n': note,
      };
  factory SetLog.fromJson(Map<String, dynamic> j) => SetLog(
        weight: (j['w'] as num?)?.toDouble(),
        reps: (j['r'] as num?)?.toInt(),
        note: j['n'] as String? ?? '',
      );
}

class Session {
  final String date; // gün anahtarı
  final List<SetLog> sets;
  Session(this.date, this.sets);

  double? get maxWeight {
    double? m;
    for (final s in sets) {
      if (s.weight != null && (m == null || s.weight! > m)) m = s.weight;
    }
    return m;
  }
}
