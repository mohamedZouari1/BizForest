import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../models.dart';
import '../services/cloud_service.dart';
import '../theme.dart';

class PlantingScreen extends StatefulWidget {
  const PlantingScreen({super.key});

  @override
  State<PlantingScreen> createState() => _PlantingScreenState();
}

class _PlantingScreenState extends State<PlantingScreen> {
  final _speciesController = TextEditingController();
  final _countController = TextEditingController(text: '1');
  bool _isSaving = false;
  bool _isLoadingLoc = false;
  Position? _position;

  Future<void> _getLocation() async {
    setState(() => _isLoadingLoc = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition();
        setState(() => _position = pos);
      }
    } finally {
      setState(() => _isLoadingLoc = false);
    }
  }

  Future<void> _submit() async {
    final species = _speciesController.text.trim();
    final count = int.tryParse(_countController.text) ?? 1;
    
    if (species.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter species name')));
      return;
    }
    
    if (_position == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please capture GPS location first')));
      return;
    }

    setState(() => _isSaving = true);
    
    final record = PlantingRecord(
      id: const Uuid().v4(),
      species: species,
      count: count,
      latitude: _position!.latitude,
      longitude: _position!.longitude,
      date: DateTime.now(),
      zoneId: 'Bizerte_North', // In production, resolve via point-in-polygon
    );

    await CloudService().savePlantingRecord(record);

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _position = null;
    });
    _speciesController.clear();
    _countController.text = '1';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Successfully logged $count trees to the map!'))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Planting')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryLight.withAlpha(50)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.gps_fixed, color: AppColors.primary, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    _position != null
                        ? '${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}'
                        : 'GPS Location Required',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingLoc)
                    const CircularProgressIndicator(strokeWidth: 2)
                  else
                    OutlinedButton.icon(
                      onPressed: _getLocation,
                      icon: const Icon(Icons.my_location),
                      label: Text(_position == null ? 'Capture Location' : 'Update Location'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text('Tree Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _speciesController,
              decoration: const InputDecoration(
                labelText: 'Tree Species (e.g. Pinus halepensis)',
                prefixIcon: Icon(Icons.eco),
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _countController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Count',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Photo'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            FilledButton.icon(
              onPressed: _isSaving ? null : _submit,
              icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.add_location_alt),
              label: const Text('Log on Map'),
            ),
          ],
        ),
      ),
    );
  }
}
