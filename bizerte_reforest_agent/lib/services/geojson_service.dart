import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../theme.dart';

class LayerDef {
  final String id;
  final String name;
  final String assetPath;
  final Color strokeColor;
  final Color fillColor;

  const LayerDef({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.strokeColor,
    required this.fillColor,
  });
}

class GisLayer {
  final LayerDef def;
  final List<Polygon> polygons;
  final List<Map<String, dynamic>> rawFeatures;

  GisLayer({
    required this.def,
    required this.polygons,
    required this.rawFeatures,
  });

  int get featureCount => polygons.length;
}

class GeoJsonService {
  static const List<LayerDef> layers = [
    LayerDef(
      id: 'boundary',
      name: 'Bizerte Boundary',
      assetPath: 'assets/geojson/bizerte_boundary.geojson',
      strokeColor: AppColors.layerBoundary,
      fillColor: Colors.transparent,
    ),
    LayerDef(
      id: 'priority',
      name: 'Priority Zones',
      assetPath: 'assets/geojson/bizerte_priority_zones.geojson',
      strokeColor: AppColors.layerPriorityZones,
      fillColor: AppColors.layerPriorityZones,
    ),
    LayerDef(
      id: 'candidates',
      name: 'Reforestation Candidates',
      assetPath: 'assets/geojson/bizerte_reforestation_candidates.geojson',
      strokeColor: AppColors.layerCandidate,
      fillColor: AppColors.layerCandidate,
    ),
    LayerDef(
      id: 'trees',
      name: 'Existing Tree Cover',
      assetPath: 'assets/geojson/bizerte_tree_cover.geojson',
      strokeColor: AppColors.layerTreeCover,
      fillColor: AppColors.layerTreeCover,
    ),
    LayerDef(
      id: 'deforested',
      name: 'Deforested (Hansen)',
      assetPath: 'assets/geojson/bizerte_deforested_areas_hansen.geojson',
      strokeColor: AppColors.layerDeforested,
      fillColor: AppColors.layerDeforested,
    ),
  ];

  Future<List<GisLayer>> loadAllLayers({
    void Function(int loaded, int total)? onProgress,
  }) async {
    final results = <GisLayer>[];
    int count = 0;
    for (final def in layers) {
      try {
        final content = await rootBundle.loadString(def.assetPath);
        final decoded = jsonDecode(content);
        final features = decoded['features'] as List<dynamic>;

        final polygons = <Polygon>[];
        final rawList = <Map<String, dynamic>>[];

        for (final feature in features) {
          final geom = feature['geometry'];
          if (geom == null) continue;
          final type = geom['type'];
          final props = feature['properties'] as Map<String, dynamic>? ?? {};

          Color polyColor = def.fillColor.withAlpha(100);
          Color polyStroke = def.strokeColor;

          if (def.id == 'priority') {
            final lv = props['priority_level'] ?? props['priority'] ?? props['label'] ?? 1;
            String labelStr = lv.toString().toLowerCase();
            if (labelStr.contains('very') || labelStr == '4') {
              polyColor = AppColors.priorityVeryHigh.withAlpha(120);
              polyStroke = AppColors.priorityVeryHigh;
            } else if (labelStr.contains('high') || labelStr == '3') {
              polyColor = AppColors.priorityHigh.withAlpha(120);
              polyStroke = AppColors.priorityHigh;
            } else if (labelStr.contains('mod') || labelStr == '2') {
              polyColor = AppColors.priorityModerate.withAlpha(120);
              polyStroke = AppColors.priorityModerate;
            } else {
              polyColor = AppColors.priorityLow.withAlpha(120);
              polyStroke = AppColors.priorityLow;
            }
          } else if (def.id == 'boundary') {
            polyColor = Colors.transparent;
          }

          if (type == 'Polygon') {
            final coords = geom['coordinates'][0] as List<dynamic>;
            final points = coords
                .map((p) => LatLng(p[1] as double, p[0] as double))
                .toList();
            polygons.add(Polygon(
              points: points,
              color: polyColor,
              borderColor: polyStroke,
              borderStrokeWidth: def.id == 'boundary' ? 2 : 1,
            ));
            rawList.add(props);
          } else if (type == 'MultiPolygon') {
            final parts = geom['coordinates'] as List<dynamic>;
            for (final part in parts) {
              final coords = part[0] as List<dynamic>;
              final points = coords
                  .map((p) => LatLng(p[1] as double, p[0] as double))
                  .toList();
              polygons.add(Polygon(
                points: points,
                color: polyColor,
                borderColor: polyStroke,
                borderStrokeWidth: def.id == 'boundary' ? 2 : 1,
              ));
              rawList.add(props);
            }
          }
        }
        results.add(GisLayer(def: def, polygons: polygons, rawFeatures: rawList));
      } catch (e) {
        debugPrint('Failed to load layer ${def.id}: $e');
      }
      count++;
      onProgress?.call(count, layers.length);
    }
    return results;
  }
}
