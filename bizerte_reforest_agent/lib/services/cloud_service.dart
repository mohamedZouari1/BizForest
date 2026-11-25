import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models.dart';
import 'storage_service.dart';

class CloudService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final StorageService _local = StorageService();

  // ── Field Surveys ──
  
  Future<void> saveFieldRecord(FieldRecord record) async {
    // 1. Always save locally first (Offline-First approach)
    await _local.saveFieldRecord(record);

    // 2. Try to save to cloud
    try {
      await _db.collection('field_surveys').doc(record.id).set(record.toJson());
    } catch (e) {
      debugPrint('Cloud sync failed, data is saved locally. Error: $e');
      // A more robust app would implement a background sync queue here.
    }
  }

  Stream<List<FieldRecord>> streamFieldRecords() {
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
    try {
      await _db.collection('plantings').doc(record.id).set(record.toJson());
    } catch (e) {
      debugPrint('Cloud sync failed, data is saved locally. Error: $e');
    }
  }

  Stream<List<PlantingRecord>> streamPlantingRecords() {
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
    try {
      await _db.collection('incidents').doc(incident.id).set(incident.toJson());
    } catch (e) {
      debugPrint('Cloud sync failed, data is saved locally. Error: $e');
    }
  }

  Stream<List<Incident>> streamIncidents() {
    return _db
        .collection('incidents')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Incident.fromJson(doc.data()))
            .toList());
  }
}
