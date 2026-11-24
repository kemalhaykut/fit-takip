import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// Uygulamanın tüm verisi. Tek bir JSON olarak telefona kaydedilir.
class AppStore extends ChangeNotifier {
  SharedPreferences? _prefs;
  static const _key = 'fit_takip_data_v1';

  Profile? profile;
  final List<Region> regions = [];
  final Map<String, DayEntry> days = {}; // tarih → idman
  final Map<String, double> weights = {}; // tarih → kg
  // hareket id → (tarih → setler)
  final Map<String, Map<String, List<SetLog>>> logs = {};
  String themeId = 'volt';

  bool get hasProfile => profile != null;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      if (j['profile'] != null) profile = Profile.fromJson(j['profile'] as Map<String, dynamic>);
      regions
        ..clear()
        ..addAll([for (final r in (j['regions'] as List? ?? const [])) Region.fromJson(r as Map<String, dynamic>)]);
      days.clear();
      (j['days'] as Map<String, dynamic>? ?? const {}).forEach((k, v) {
        days[k] = DayEntry.fromJson(v as Map<String, dynamic>);
      });
      weights.clear();
      (j['weights'] as Map<String, dynamic>? ?? const {}).forEach((k, v) {
        weights[k] = (v as num).toDouble();
      });
      logs.clear();
      (j['logs'] as Map<String, dynamic>? ?? const {}).forEach((exId, m) {
        final inner = <String, List<SetLog>>{};
        (m as Map<String, dynamic>).forEach((date, list) {
          inner[date] = [for (final s in (list as List)) SetLog.fromJson(s as Map<String, dynamic>)];
        });
        logs[exId] = inner;
      });
      themeId = j['theme'] as String? ?? 'volt';
    } catch (e) {
      debugPrint('Veri okunamadı: $e');
    }
  }

  Future<void> _save() async {
    final j = {
      'profile': profile?.toJson(),
      'regions': [for (final r in regions) r.toJson()],
      'days': {for (final e in days.entries) e.key: e.value.toJson()},
      'weights': weights,
      'logs': {
        for (final e in logs.entries)
          e.key: {
            for (final d in e.value.entries) d.key: [for (final s in d.value) s.toJson()]
          }
      },
      'theme': themeId,
    };
    await _prefs?.setString(_key, jsonEncode(j));
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  // ---------------- Profil ----------------
  void createProfile(Profile p) {
    profile = p;
    weights[dkey(today)] = p.weight;
    _changed();
  }

  /// Profil elle güncellenir. Kilo değiştiyse bugünün ölçümü olarak da kaydedilir.
  void updateProfile({required String name, required int age, required double height, required double weight}) {
    final p = profile!;
    final weightChanged = (p.weight - weight).abs() > 0.001;
    p
      ..name = name
      ..age = age
      ..height = height
      ..weight = weight;
    if (weightChanged) weights[dkey(today)] = weight;
    _changed();
  }

  /// Profilde görünen güncel kilo: en son tarihli ölçüm.
  double get currentWeight {
    if (weights.isEmpty) return profile?.weight ?? 0;
    final keys = weights.keys.toList()..sort();
    return weights[keys.last]!;
  }

  double? get bmi {
    final h = profile?.height ?? 0;
    if (h <= 0) return null;
    final m = h / 100;
    return currentWeight / (m * m);
  }

  void _syncProfileWeight() {
    if (profile != null && weights.isNotEmpty) profile!.weight = currentWeight;
  }

  // ---------------- Ölçümler ----------------
  List<MapEntry<DateTime, double>> get weightSeries {
    final keys = weights.keys.toList()..sort();
    return [for (final k in keys) MapEntry(parseKey(k), weights[k]!)];
  }

  void setWeight(DateTime d, double kg, {DateTime? replaces}) {
    if (replaces != null) weights.remove(dkey(replaces));
    weights[dkey(d)] = kg;
    _syncProfileWeight();
    _changed();
  }

  void deleteWeight(DateTime d) {
    weights.remove(dkey(d));
    _syncProfileWeight();
    _changed();
  }

  // ---------------- Program ----------------
  Region? regionById(String id) {
    for (final r in regions) {
      if (r.id == id) return r;
    }
    return null;
  }

  void saveRegion(Region r) {
    final i = regions.indexWhere((x) => x.id == r.id);
    if (i >= 0) {
      regions[i] = r;
    } else {
      regions.add(r);
    }
    // Bu bölgenin işlendiği günlerdeki ad/fotoğraf kopyasını da güncelle.
    for (final d in days.values) {
      if (d.regionId == r.id) {
        d
          ..name = r.name
          ..rest = r.rest
          ..muscles = List.of(r.muscles)
          ..photo = r.photo;
      }
    }
    _changed();
  }

  void deleteRegion(Region r) {
    regions.removeWhere((x) => x.id == r.id);
    _changed();
  }

  void moveRegion(int oldIndex, int newIndex) {
    final r = regions.removeAt(oldIndex);
    regions.insert(newIndex, r);
    _changed();
  }

  void saveExercise(Region r, Exercise e) {
    final i = r.exercises.indexWhere((x) => x.id == e.id);
    if (i >= 0) {
      r.exercises[i] = e;
    } else {
      r.exercises.add(e);
    }
    _changed();
  }

  void deleteExercise(Region r, Exercise e) {
    r.exercises.removeWhere((x) => x.id == e.id);
    _changed();
  }

  // ---------------- Takvim ----------------
  DayEntry? dayEntry(DateTime d) => days[dkey(d)];

  void setDay(DateTime d, Region r) {
    days[dkey(d)] = DayEntry.of(r);
    _changed();
  }

  void clearDay(DateTime d) {
    days.remove(dkey(d));
    _changed();
  }

  /// Spor salonuna gelinen günler (dinlenme günleri sayılmaz).
  Iterable<String> get _gymDays => days.entries.where((e) => !e.value.rest).map((e) => e.key);

  int get totalCount => _gymDays.length;

  int get monthCount {
    final n = today;
    final prefix = '${n.year}-${n.month.toString().padLeft(2, '0')}-';
    return _gymDays.where((k) => k.startsWith(prefix)).length;
  }

  int get weekCount {
    final ws = weekStart(today);
    return _gymDays.where((k) {
      final d = parseKey(k);
      return !d.isBefore(ws) && d.isBefore(ws.add(const Duration(days: 7)));
    }).length;
  }

  /// Bir haftada her kas grubunun kaç kez çalışıldığı.
  Map<String, int> muscleCounts(DateTime weekMonday) {
    final res = <String, int>{};
    for (var i = 0; i < 7; i++) {
      final e = days[dkey(weekMonday.add(Duration(days: i)))];
      if (e == null || e.rest) continue;
      final muscles = regionById(e.regionId)?.muscles ?? e.muscles;
      for (final m in muscles) {
        res[m] = (res[m] ?? 0) + 1;
      }
    }
    return res;
  }

  // ---------------- Set kayıtları ----------------
  List<SetLog>? setsFor(Exercise e, DateTime d) => logs[e.id]?[dkey(d)];

  /// Verilen tarihten ÖNCEKİ son idman.
  Session? previousSession(Exercise e, DateTime before) {
    final m = logs[e.id];
    if (m == null) return null;
    final bk = dkey(before);
    final keys = m.keys.where((k) => k.compareTo(bk) < 0).toList()..sort();
    for (final k in keys.reversed) {
      if (m[k]!.any((s) => !s.isEmpty)) return Session(k, m[k]!);
    }
    return null;
  }

  List<Session> history(Exercise e) {
    final m = logs[e.id];
    if (m == null) return [];
    final keys = m.keys.toList()..sort((a, b) => b.compareTo(a));
    return [for (final k in keys) if (m[k]!.any((s) => !s.isEmpty)) Session(k, m[k]!)];
  }

  void saveSets(Exercise e, DateTime d, List<SetLog> sets) {
    final m = logs.putIfAbsent(e.id, () => {});
    if (sets.every((s) => s.isEmpty)) {
      m.remove(dkey(d));
    } else {
      m[dkey(d)] = sets;
    }
    _changed();
  }

  void deleteSession(Exercise e, String dateKey) {
    logs[e.id]?.remove(dateKey);
    _changed();
  }

  // ---------------- Ayarlar ----------------
  void setTheme(String id) {
    themeId = id;
    _changed();
  }

  Future<void> resetAll() async {
    profile = null;
    regions.clear();
    days.clear();
    weights.clear();
    logs.clear();
    await _prefs?.remove(_key);
    notifyListeners();
  }
}

final store = AppStore();
