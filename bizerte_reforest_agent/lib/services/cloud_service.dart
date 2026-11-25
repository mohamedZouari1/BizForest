import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models.dart';
import 'storage_service.dart';

class CloudService {
  final StorageService _local = StorageService();

  /// Firestore is only available when Firebase was initialized with a config
  /// (see firebase_config.example.json). Otherwise the app works local-only.
  static bool get isAvailable => Firebase.apps.isNotEmpty;

  FirebaseFirestore? get _dbOrNull =>
      isAvailable ? FirebaseFirestore.instance : null;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ── Field Surveys ──
  
  Future<void> saveFieldRecord(FieldRecord record) async {
    // 1. Always save locally first (Offline-First approach)
    await _local.saveFieldRecord(record);

    // 2. Try to save to cloud
    if (!isAvailable) return;
    try {
      await _db.collection('field_surveys').doc(record.id).set(record.toJson());
    } catch (e) {
      debugPrint('Cloud sync failed, data is saved locally. Error: $e');
      // A more robust app would implement a background sync queue here.
    }
  }

  Stream<List<FieldRecord>> streamFieldRecords() {
    if (_dbOrNull == null) return Stream.fromFuture(_local.getFieldRecords());
    return _db
        .collection('field_surveys')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FieldRecord.fromJson(doc.data()))
            .toList());
  }

  // ── Planting Records ──

  Future<void> savePlantingRecord(PlantingRecord record) async {
    await _local.savePlantingRecord(record);
    if (!isAvailable) return;
    try {
      await _db.collection('plantings').doc(record.id).set(record.toJson());
    } catch (e) {
      debugPrint('Cloud sync failed, data is saved locally. Error: $e');
    }
  }

  Stream<List<PlantingRecord>> streamPlantingRecords() {
    if (_dbOrNull == null) return Stream.fromFuture(_local.getPlantingRecords());
    return _db
        .collection('plantings')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PlantingRecord.fromJson(doc.data()))
            .toList());
  }

  // ── Incidents ──

  Future<void> saveIncident(Incident incident) async {
    await _local.saveIncident(incident);
    if (!isAvailable) return;
    try {
      await _db.collection('incidents').doc(incident.id).set(incident.toJson());
    } catch (e) {
      debugPrint('Cloud sync failed, data is saved locally. Error: $e');
    }
  }

  Stream<List<Incident>> streamIncidents() {
    if (_dbOrNull == null) return Stream.fromFuture(_local.getIncidents());
    return _db
        .collection('incidents')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Incident.fromJson(doc.data()))
            .toList());
  }
}
