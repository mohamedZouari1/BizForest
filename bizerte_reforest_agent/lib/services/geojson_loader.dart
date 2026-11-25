import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';


// ─────────────────────────────────────────────
// LAYER DEFINITION
// ─────────────────────────────────────────────
class GisLayerDef {
  const GisLayerDef({
    required this.id,
    required this.name,
    required this.asset,
    required this.fillColor,
    required this.strokeColor,
    required this.icon,
  });

  final String id;
  final String name;
  final String asset;
  final Color fillColor;
  final Color strokeColor;
  final IconData icon;
}

class GisLayer {
  const GisLayer({
    required this.def,
    required this.polygons,
    required this.featureCount,
  });

  final GisLayerDef def;
  final List<Polygon> polygons;
  final int featureCount;
}

// ─────────────────────────────────────────────
// LAYER CONFIGS
// ─────────────────────────────────────────────
const List<GisLayerDef> kLayerDefs = [
  GisLayerDef(
    id: 'boundary',
    name: 'Boundary',
    asset: 'assets/geojson/bizerte_boundary.geojson',
    fillColor: Color(0x18448AFF),
    strokeColor: Color(0xFF448AFF),
    icon: Icons.crop_square_rounded,
  ),
  GisLayerDef(
    id: 'trees',
    name: 'Tree Cover',
    asset: 'assets/geojson/tree_cover.geojson',
    fillColor: Color(0x662E7D32),
    strokeColor: Color(0xFF4CAF50),
    icon: Icons.park,
  ),
  GisLayerDef(
    id: 'candidate',
    name: 'Candidate Land',
    asset: 'assets/geojson/candidate_land.geojson',
    fillColor: Color(0x44FFD600),
    strokeColor: Color(0xFFFFD600),
    icon: Icons.terrain,
  ),
  GisLayerDef(
    id: 'priority',
    name: 'All Priority',
    asset: 'assets/geojson/priority_zones.geojson',
    fillColor: Color(0x44FF6D00),
    strokeColor: Color(0xFFFF6D00),
    icon: Icons.layers,
  ),
  GisLayerDef(
    id: 'high',
    name: 'High Priority',
    asset: 'assets/geojson/high_priority.geojson',
    fillColor: Color(0x55FF5722),
    strokeColor: Color(0xFFFF5722),
    icon: Icons.priority_high,
  ),
  GisLayerDef(
    id: 'very_high',
    name: 'Very High',
    asset: 'assets/geojson/very_high_priority.geojson',
    fillColor: Color(0x66D50000),
    strokeColor: Color(0xFFFF1744),
    icon: Icons.warning_amber_rounded,
  ),
];

// ─────────────────────────────────────────────
// LOADER
// ─────────────────────────────────────────────
class GeoJsonLayerLoader {
  final Map<String, GisLayer> _cache = {};

  Future<GisLayer> loadLayer(GisLayerDef def) async {
    if (_cache.containsKey(def.id)) return _cache[def.id]!;

    final raw = await rootBundle.loadString(def.asset);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final features = decoded['features'] as List<dynamic>? ?? const [];
    final polygons = <Polygon>[];

    for (final feature in features) {
      final geometry =
          (feature as Map<String, dynamic>)['geometry'] as Map<String, dynamic>?;
      if (geometry == null) continue;
      final type = geometry['type'] as String?;
      final coordinates = geometry['coordinates'];

      if (type == 'Polygon') {
        _addPolygon(coordinates as List<dynamic>, polygons, def);
      } else if (type == 'MultiPolygon') {
        for (final polygon in coordinates as List<dynamic>) {
          _addPolygon(polygon as List<dynamic>, polygons, def);
        }
      }
    }

    final layer = GisLayer(
      def: def,
      polygons: polygons,
      featureCount: features.length,
    );
    _cache[def.id] = layer;
    return layer;
  }

  Future<List<GisLayer>> loadAllLayers({
    void Function(int loaded, int total)? onProgress,
  }) async {
    final layers = <GisLayer>[];
    for (var i = 0; i < kLayerDefs.length; i++) {
      final layer = await loadLayer(kLayerDefs[i]);
      layers.add(layer);
      onProgress?.call(i + 1, kLayerDefs.length);
    }
    return layers;
  }

  void _addPolygon(
    List<dynamic> rings,
    List<Polygon> output,
    GisLayerDef config,
  ) {
    if (rings.isEmpty) return;
    final exterior = rings.first as List<dynamic>;
    final points = exterior.map((coord) {
      final pair = coord as List<dynamic>;
      return LatLng((pair[1] as num).toDouble(), (pair[0] as num).toDouble());
    }).toList();
    if (points.length < 3) return;
    output.add(Polygon(
      points: points,
      color: config.fillColor,
      borderColor: config.strokeColor,
      borderStrokeWidth: 1.5,
    ));
  }
}
