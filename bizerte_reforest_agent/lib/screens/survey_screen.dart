import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../models.dart';
import '../services/cloud_service.dart';
import '../theme.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final _zoneController = TextEditingController(text: 'Bizerte Sector A');
  final _notesController = TextEditingController();
  final _mapController = MapController();
  
  String _status = 'Healthy';
  final List<String> _statuses = ['Healthy', 'Degraded', 'Replanted', 'Blocked'];
  
  final List<LatLng> _drawnPolygon = [];
  bool _isSaving = false;

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _drawnPolygon.add(point);
    });
  }

  void _clearPolygon() {
    setState(() {
      _drawnPolygon.clear();
    });
  }

  Future<void> _submit() async {
    if (_drawnPolygon.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please tap the map to draw a polygon (at least 3 points)'))
      );
      return;
    }

    setState(() => _isSaving = true);

    final record = FieldRecord(
      id: const Uuid().v4(),
      zoneId: _zoneController.text.trim(),
      polygonCoords: List.from(_drawnPolygon),
      date: DateTime.now(),
      status: _status,
      notes: _notesController.text,
    );

    await CloudService().saveFieldRecord(record);

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _drawnPolygon.clear();
      _notesController.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Survey for ${_zoneController.text} submitted!'))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Field Survey')),
      body: Column(
        children: [
          // ── MAP DRAWING AREA ──
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(37.2746, 9.8739),
                    initialZoom: 12,
                    onTap: _onMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                      userAgentPackageName: 'com.example.bizerte_reforest_agent',
                    ),
                    if (_drawnPolygon.isNotEmpty)
                      PolygonLayer(
                        polygons: [
                          Polygon(
                            points: _drawnPolygon,
                            color: Colors.blue.withAlpha(80),
                            borderColor: Colors.blue,
                            borderStrokeWidth: 2,
                          )
                        ],
                      ),
                    if (_drawnPolygon.isNotEmpty)
                      MarkerLayer(
                        markers: _drawnPolygon.map((p) => Marker(
                          point: p,
                          width: 12,
                          height: 12,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )).toList(),
                      ),
                  ],
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(230),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.touch_app, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Tap the map to draw the survey zone perimeter.',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (_drawnPolygon.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.undo),
                            onPressed: () {
                              setState(() => _drawnPolygon.removeLast());
                            },
                          ),
                        if (_drawnPolygon.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: _clearPolygon,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── FORM AREA ──
          Expanded(
            flex: 5,
            child: Container(
              color: AppColors.background,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _zoneController,
                      decoration: const InputDecoration(
                        labelText: 'Zone Name',
                        prefixIcon: Icon(Icons.map),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Zone Health Status',
                        prefixIcon: Icon(Icons.health_and_safety),
                      ),
                      items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _status = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Field Notes',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 40),
                          child: Icon(Icons.notes),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _submit,
                      icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.cloud_upload),
                      label: const Text('Submit Survey'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
