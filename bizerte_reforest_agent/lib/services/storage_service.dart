import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';

class StorageService {
  static const _roleKey = 'bizforest_user_role';
  static const _fieldKey = 'bizforest_field_records';
  static const _plantingKey = 'bizforest_planting_records';
  static const _incidentKey = 'bizforest_incidents';

  Future<void> saveRole(UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role.name);
  }

  Future<UserRole?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    final roleName = prefs.getString(_roleKey);
    if (roleName == null) return null;
    try {
      return UserRole.values.firstWhere((r) => r.name == roleName);
    } catch (_) {
      return null;
    }
  }

  // Generic loader
  Future<List<T>> _load<T>(
      String key, T Function(Map<String, dynamic>) fromJson) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  // Generic saver
  Future<void> _save<T>(String key, List<T> items, Map<String, dynamic> Function(T) toJson) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map(toJson).toList());
    await prefs.setString(key, encoded);
  }

  Future<List<FieldRecord>> getFieldRecords() =>
      _load(_fieldKey, FieldRecord.fromJson);

  Future<void> saveFieldRecord(FieldRecord record) async {
    final existing = await getFieldRecords();
    existing.insert(0, record);
    await _save(_fieldKey, existing, (r) => r.toJson());
  }

  Future<List<PlantingRecord>> getPlantingRecords() =>
      _load(_plantingKey, PlantingRecord.fromJson);

  Future<void> savePlantingRecord(PlantingRecord record) async {
    final existing = await getPlantingRecords();
    existing.insert(0, record);
    await _save(_plantingKey, existing, (r) => r.toJson());
  }

  Future<List<Incident>> getIncidents() =>
      _load(_incidentKey, Incident.fromJson);

  Future<void> saveIncident(Incident incident) async {
    final existing = await getIncidents();
    existing.insert(0, incident);
    await _save(_incidentKey, existing, (r) => r.toJson());
  }
}
