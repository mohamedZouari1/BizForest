import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum UserRole {
  field(
      name: 'Field Agent',
      description: 'Log visits, photos, and planting work.',
      icon: Icons.engineering,
      color: Color(0xFF1B5E20)),
  manager(
      name: 'Manager',
      description: 'Monitor progress, review reports, export data.',
      icon: Icons.insights,
      color: Color(0xFF0D47A1)),
  government(
      name: 'Government',
      description: 'View priority maps and regional KPIs.',
      icon: Icons.account_balance,
      color: Color(0xFF880E4F)),
  public(
      name: 'Volunteer',
      description: 'Report incidents, track planting badges.',
      icon: Icons.public,
      color: Color(0xFFE65100));

  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const UserRole({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class FieldRecord {
  final String id;
  final String zoneId;
  final List<LatLng> polygonCoords;
  final DateTime date;
  final String status; // Healthy, Degraded, Replanted, Blocked
  final String notes;
  final String? photoPath;

  FieldRecord({
    required this.id,
    required this.zoneId,
    required this.polygonCoords,
    required this.date,
    required this.status,
    required this.notes,
    this.photoPath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'zoneId': zoneId,
        'polygonCoords': polygonCoords.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
        'date': date.toIso8601String(),
        'status': status,
        'notes': notes,
        'photoPath': photoPath,
      };

  factory FieldRecord.fromJson(Map<String, dynamic> json) => FieldRecord(
        id: json['id'],
        zoneId: json['zoneId'],
        polygonCoords: (json['polygonCoords'] as List<dynamic>?)
            ?.map((p) => LatLng(p['lat'] as double, p['lng'] as double))
            .toList() ?? [],
        date: DateTime.parse(json['date']),
        status: json['status'],
        notes: json['notes'],
        photoPath: json['photoPath'],
      );
}

class PlantingRecord {
  final String id;
  final String species;
  final int count;
  final double latitude;
  final double longitude;
  final DateTime date;
  final String zoneId;
  final String? photoPath;

  PlantingRecord({
    required this.id,
    required this.species,
    required this.count,
    required this.latitude,
    required this.longitude,
    required this.date,
    required this.zoneId,
    this.photoPath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'species': species,
        'count': count,
        'latitude': latitude,
        'longitude': longitude,
        'date': date.toIso8601String(),
        'zoneId': zoneId,
        'photoPath': photoPath,
      };

  factory PlantingRecord.fromJson(Map<String, dynamic> json) => PlantingRecord(
        id: json['id'],
        species: json['species'],
        count: json['count'],
        latitude: json['latitude'],
        longitude: json['longitude'],
        date: DateTime.parse(json['date']),
        zoneId: json['zoneId'],
        photoPath: json['photoPath'],
      );
}

class Incident {
  final String id;
  final String category; // Fire, Illegal Cutting, Erosion, Waste Dumping, Other
  final double latitude;
  final double longitude;
  final DateTime date;
  final String description;
  final String status; // Open, In Review, Resolved
  final String? photoPath;

  Incident({
    required this.id,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.date,
    required this.description,
    required this.status,
    this.photoPath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'latitude': latitude,
        'longitude': longitude,
        'date': date.toIso8601String(),
        'description': description,
        'status': status,
        'photoPath': photoPath,
      };

  factory Incident.fromJson(Map<String, dynamic> json) => Incident(
        id: json['id'],
        category: json['category'],
        latitude: json['latitude'],
        longitude: json['longitude'],
        date: DateTime.parse(json['date']),
        description: json['description'],
        status: json['status'],
        photoPath: json['photoPath'],
      );
}

class ChatMessage {
  final String role;
  final String text;
  final DateTime timestamp;

  const ChatMessage({
    required this.role,
    required this.text,
    required this.timestamp,
  });
}
