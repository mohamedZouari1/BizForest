import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../services/cloud_service.dart';
import '../theme.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _cloud = CloudService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Records (Cloud)'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Surveys'),
            Tab(text: 'Plantings'),
            Tab(text: 'Incidents'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFieldList(),
          _buildPlantingList(),
          _buildIncidentList(),
        ],
      ),
    );
  }

  Widget _buildFieldList() {
    return StreamBuilder<List<FieldRecord>>(
      stream: _cloud.streamFieldRecords(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Cloud sync not configured or offline.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.data ?? [];
        if (records.isEmpty) {
          return const Center(child: Text('No field surveys logged yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: records.length,
          itemBuilder: (context, i) {
            final r = records[i];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.assignment, color: AppColors.primary),
                title: Text('Zone: ${r.zoneId}'),
                subtitle: Text(DateFormat.yMMMd().format(r.date)),
                trailing: Chip(
                  label: Text(r.status, style: const TextStyle(fontSize: 10)),
                  backgroundColor: r.status == 'Healthy' ? AppColors.statusHealthy.withAlpha(20) : AppColors.statusWarning.withAlpha(20),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlantingList() {
    return StreamBuilder<List<PlantingRecord>>(
      stream: _cloud.streamPlantingRecords(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Cloud sync not configured or offline.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.data ?? [];
        if (records.isEmpty) {
          return const Center(child: Text('No plantings logged yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: records.length,
          itemBuilder: (context, i) {
            final r = records[i];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.nature, color: AppColors.primaryLight),
                title: Text('${r.count}x ${r.species}'),
                subtitle: Text(DateFormat.yMMMd().format(r.date)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIncidentList() {
    return StreamBuilder<List<Incident>>(
      stream: _cloud.streamIncidents(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Cloud sync not configured or offline.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.data ?? [];
        if (records.isEmpty) {
          return const Center(child: Text('No incidents reported.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: records.length,
          itemBuilder: (context, i) {
            final r = records[i];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.warning, color: AppColors.priorityVeryHigh),
                title: Text(r.category),
                subtitle: Text(r.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Chip(
                  label: Text(r.status, style: const TextStyle(fontSize: 10)),
                  backgroundColor: AppColors.divider,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
