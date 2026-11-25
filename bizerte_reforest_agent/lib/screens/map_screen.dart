import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models.dart';
import '../services/cloud_service.dart';
import '../services/geojson_service.dart';
import '../theme.dart';

const _bizerteCenter = LatLng(37.2746, 9.8739);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();
  final _loader = GeoJsonService();
  List<GisLayer>? _layers;
  bool _isLoading = true;
  int _loaded = 0;
  int _total = 5;
  final Set<String> _visibleLayers = {'boundary', 'priority'};
  LatLng? _position;
  bool _useSatellite = false;
  bool _showPanel = true;

  List<PlantingRecord> _plantings = [];
  List<FieldRecord> _surveys = [];
  StreamSubscription? _plantingsSub;
  StreamSubscription? _surveysSub;

  @override
  void initState() {
    super.initState();
    _loadLayers();
    _plantingsSub = CloudService().streamPlantingRecords().listen((data) {
      if (mounted) setState(() => _plantings = data);
    });
    _surveysSub = CloudService().streamFieldRecords().listen((data) {
      if (mounted) setState(() => _surveys = data);
    });
  }

  @override
  void dispose() {
    _plantingsSub?.cancel();
    _surveysSub?.cancel();
    super.dispose();
  }

  Future<void> _loadLayers() async {
    final layers = await _loader.loadAllLayers(
      onProgress: (loaded, total) {
        if (mounted) {
          setState(() {
            _loaded = loaded;
            _total = total;
          });
        }
      },
    );
    if (mounted) {
      setState(() {
        _layers = layers;
        _isLoading = false;
      });
    }
  }

  Future<void> _locate() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')));
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final next = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() => _position = next);
      _mapController.move(next, 14);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('GPS Error: $e')));
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    // 1. Check Plantings (Distance check, roughly 50-100 meters depending on zoom, let's use 100 meters)
    const double distanceThreshold = 100.0; 
    const distance = Distance();
    for (final planting in _plantings) {
      final pPoint = LatLng(planting.latitude, planting.longitude);
      if (distance(point, pPoint) < distanceThreshold) {
        _showPlantingDetails(planting);
        return;
      }
    }

    // 2. Check Custom Survey Polygons
    for (final survey in _surveys) {
      if (survey.polygonCoords.isNotEmpty && _isPointInPolygon(point, survey.polygonCoords)) {
        _showSurveyDetails(survey);
        return;
      }
    }

    // 3. Check GeoJSON layers
    if (_layers == null) return;
    
    Map<String, dynamic>? tappedProps;
    String? tappedLayerName;

    for (final layer in _layers!.reversed) {
      if (!_visibleLayers.contains(layer.def.id)) continue;
      
      for (int i = 0; i < layer.polygons.length; i++) {
        final poly = layer.polygons[i];
        if (_isPointInPolygon(point, poly.points)) {
          tappedProps = layer.rawFeatures[i];
          tappedLayerName = layer.def.name;
          break;
        }
      }
      if (tappedProps != null) break;
    }

    if (tappedProps != null) {
      _showZoneDetails(tappedProps, tappedLayerName!);
    }
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    bool isInside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      if ((polygon[i].longitude > point.longitude) !=
              (polygon[j].longitude > point.longitude) &&
          (point.latitude <
              (polygon[j].latitude - polygon[i].latitude) *
                      (point.longitude - polygon[i].longitude) /
                      (polygon[j].longitude - polygon[i].longitude) +
                  polygon[i].latitude)) {
        isInside = !isInside;
      }
      j = i;
    }
    return isInside;
  }

  void _showPlantingDetails(PlantingRecord record) {
    _showCustomModal(
      title: 'Planted Trees',
      icon: Icons.park,
      iconColor: Colors.green,
      rows: [
        _DetailRow(icon: Icons.eco, label: 'Species', value: record.species),
        _DetailRow(icon: Icons.numbers, label: 'Count', value: '${record.count}'),
        _DetailRow(icon: Icons.calendar_today, label: 'Date', value: record.date.toString().split(' ')[0]),
        if (record.photoPath != null)
          const _DetailRow(icon: Icons.photo, label: 'Photo Attached', value: 'Yes'),
      ],
    );
  }

  void _showSurveyDetails(FieldRecord record) {
    Color statusColor = record.status == 'Healthy' ? Colors.teal : record.status == 'Blocked' ? Colors.red : Colors.orange;
    _showCustomModal(
      title: 'Field Survey',
      icon: Icons.assignment,
      iconColor: statusColor,
      rows: [
        _DetailRow(icon: Icons.map, label: 'Zone', value: record.zoneId),
        _DetailRow(icon: Icons.health_and_safety, label: 'Status', value: record.status, isAlert: record.status != 'Healthy'),
        _DetailRow(icon: Icons.notes, label: 'Notes', value: record.notes.isEmpty ? 'No notes provided' : record.notes),
        _DetailRow(icon: Icons.calendar_today, label: 'Date', value: record.date.toString().split(' ')[0]),
      ],
    );
  }

  void _showZoneDetails(Map<String, dynamic> props, String layerName) {
    final rows = <Widget>[];
    if (props.containsKey('area_ha')) {
      rows.add(_DetailRow(icon: Icons.square_foot, label: 'Area', value: '${(props['area_ha'] as num).toStringAsFixed(2)} ha'));
    }
    if (props.containsKey('priority') || props.containsKey('priority_level') || props.containsKey('label')) {
      rows.add(_DetailRow(icon: Icons.bolt, label: 'Priority', value: '${props['priority'] ?? props['priority_level'] ?? props['label']}', isAlert: true));
    }
    if (props.containsKey('layer')) {
      rows.add(_DetailRow(icon: Icons.category, label: 'Class', value: '${props['layer']}'));
    }

    _showCustomModal(
      title: layerName,
      icon: Icons.info_outline,
      iconColor: AppColors.primary,
      rows: rows,
    );
  }

  void _showCustomModal({required String title, required IconData icon, required Color iconColor, required List<Widget> rows}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
              ],
            ),
            const SizedBox(height: 16),
            ...rows,
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final geojsonPolygons = <Polygon>[];
    if (_layers != null) {
      for (final layer in _layers!) {
        if (_visibleLayers.contains(layer.def.id)) {
          geojsonPolygons.addAll(layer.polygons);
        }
      }
    }

    final surveyPolygons = _surveys.where((r) => r.polygonCoords.isNotEmpty).map((record) {
      Color polyColor = record.status == 'Healthy' ? Colors.teal.withAlpha(100) : record.status == 'Blocked' ? Colors.red.withAlpha(100) : Colors.orange.withAlpha(100);
      Color strokeColor = record.status == 'Healthy' ? Colors.teal : record.status == 'Blocked' ? Colors.red : Colors.orange;
      return Polygon(points: record.polygonCoords, color: polyColor, borderColor: strokeColor, borderStrokeWidth: 2);
    }).toList();

    final treeMarkers = _plantings.map((record) {
      return Marker(
        point: LatLng(record.latitude, record.longitude),
        width: 30,
        height: 30,
        child: const Icon(Icons.park, color: Colors.green, size: 24),
      );
    }).toList();

    return Scaffold(
      body: Stack(
        children: [
          // ── MAP ──
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _bizerteCenter,
              initialZoom: 10.5,
              minZoom: 8,
              maxZoom: 18,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: _useSatellite
                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.bizerte_reforest_agent',
              ),
              PolygonLayer(polygons: geojsonPolygons),
              PolygonLayer(polygons: surveyPolygons),
              MarkerLayer(markers: treeMarkers),
              if (_position != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _position!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.gpsBlue.withAlpha(50),
                          border: Border.all(color: AppColors.gpsBlue, width: 2),
                        ),
                        child: const Center(
                          child: Icon(Icons.my_location, color: AppColors.gpsBlue, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ── LOADING OVERLAY ──
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.white.withAlpha(220),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppColors.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Loading Satellite Data...\n($_loaded/$_total layers)',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── TOP CONTROLS ──
          if (!_isLoading)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: SafeArea(
                child: _showPanel
                    ? _LayerPanel(
                        layers: _layers ?? [],
                        visibleLayers: _visibleLayers,
                        useSatellite: _useSatellite,
                        onLayerChanged: (id, visible) {
                          setState(() {
                            visible ? _visibleLayers.add(id) : _visibleLayers.remove(id);
                          });
                        },
                        onLocate: _locate,
                        onToggleSatellite: () {
                          setState(() => _useSatellite = !_useSatellite);
                        },
                        onCollapse: () => setState(() => _showPanel = false),
                      )
                    : Row(
                        children: [
                          _MapButton(icon: Icons.layers, onTap: () => setState(() => _showPanel = true)),
                          const SizedBox(width: 8),
                          _MapButton(icon: Icons.my_location, onTap: _locate),
                        ],
                      ),
              ),
            ),
        ],
      ),
      floatingActionButton: !_isLoading && _position == null
          ? FloatingActionButton(
              onPressed: _locate,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: AppColors.textPrimary),
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────
class _LayerPanel extends StatelessWidget {
  const _LayerPanel({
    required this.layers,
    required this.visibleLayers,
    required this.useSatellite,
    required this.onLayerChanged,
    required this.onLocate,
    required this.onToggleSatellite,
    required this.onCollapse,
  });

  final List<GisLayer> layers;
  final Set<String> visibleLayers;
  final bool useSatellite;
  final void Function(String id, bool visible) onLayerChanged;
  final VoidCallback onLocate;
  final VoidCallback onToggleSatellite;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(245),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.layers, color: AppColors.textPrimary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Map Layers', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              _MapButton(icon: useSatellite ? Icons.map : Icons.satellite_alt, onTap: onToggleSatellite),
              const SizedBox(width: 8),
              _MapButton(icon: Icons.keyboard_arrow_up, onTap: onCollapse),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final layer in layers)
                _LayerChip(
                  layer: layer,
                  isActive: visibleLayers.contains(layer.def.id),
                  onTap: () => onLayerChanged(layer.def.id, !visibleLayers.contains(layer.def.id)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _LayerChip extends StatelessWidget {
  const _LayerChip({
    required this.layer,
    required this.isActive,
    required this.onTap,
  });

  final GisLayer layer;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? layer.def.strokeColor.withAlpha(20) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? layer.def.strokeColor : AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isActive ? layer.def.strokeColor : AppColors.textHint,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              layer.def.name,
              style: TextStyle(
                color: isActive ? AppColors.textPrimary : AppColors.textHint,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isAlert;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textHint),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isAlert ? AppColors.priorityVeryHigh : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
