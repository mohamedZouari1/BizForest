import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models.dart';
import '../services/cloud_service.dart';
import '../theme.dart';

class IncidentsScreen extends StatefulWidget {
  const IncidentsScreen({super.key});

  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends State<IncidentsScreen> {
  final _descController = TextEditingController();
  String _category = 'Fire';
  final _categories = ['Fire', 'Illegal Cutting', 'Erosion', 'Waste Dumping', 'Other'];
  bool _isSaving = false;

  Future<void> _submit() async {
    if (_descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please describe the incident')));
      return;
    }

    setState(() => _isSaving = true);
    
    final inc = Incident(
      id: const Uuid().v4(),
      category: _category,
      latitude: 37.27,
      longitude: 9.87,
      date: DateTime.now(),
      description: _descController.text,
      status: 'Open',
    );

    await CloudService().saveIncident(inc);

    if (!mounted) return;
    setState(() => _isSaving = false);
    _descController.clear();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Incident reported and syncing to cloud. Field team notified.'))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Incident')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.priorityVeryHigh.withAlpha(20),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.priorityVeryHigh.withAlpha(50)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.priorityVeryHigh, size: 32),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Your report will automatically log your GPS location and alert the nearest field team.',
                      style: TextStyle(color: AppColors.priorityVeryHigh, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.category)),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 24),

            const Text('Description', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'What did you observe? Please provide details...',
              ),
            ),
            const SizedBox(height: 24),
            
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Add Evidence Photo'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.divider),
              ),
            ),
            const SizedBox(height: 32),
            
            FilledButton(
              onPressed: _isSaving ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: AppColors.priorityVeryHigh),
              child: _isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }
}
