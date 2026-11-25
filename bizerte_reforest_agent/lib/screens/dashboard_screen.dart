import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../models.dart';
import '../services/cloud_service.dart';
import '../theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bizerte Overview',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Reforestation intelligence based on Sentinel-2 data.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            
            // Stats Grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                const _StatCard(
                  title: 'Total Mapped',
                  value: '383k',
                  unit: 'ha',
                  icon: Icons.map,
                  color: AppColors.gpsBlue,
                ),
                const _StatCard(
                  title: 'Deforested',
                  value: '14.2k',
                  unit: 'ha',
                  icon: Icons.forest_outlined,
                  color: AppColors.layerDeforested,
                ),
                const _StatCard(
                  title: 'Priority Zones',
                  value: '84',
                  unit: 'zones',
                  icon: Icons.bolt,
                  color: AppColors.priorityHigh,
                ),
                StreamBuilder<List<PlantingRecord>>(
                  stream: CloudService().streamPlantingRecords(),
                  builder: (context, snapshot) {
                    int total = 1200; // base from GEE
                    if (snapshot.hasData) {
                      for (var r in snapshot.data!) {
                        total += r.count;
                      }
                    }
                    return _StatCard(
                      title: 'Live Planted',
                      value: '${(total / 1000).toStringAsFixed(1)}k',
                      unit: 'trees',
                      icon: Icons.nature,
                      color: AppColors.primary,
                    );
                  }
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            const Text(
              'Priority Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const _PriorityBar(
              label: 'Very High Priority',
              percent: 0.15,
              value: '12 zones',
              color: AppColors.priorityVeryHigh,
            ),
            const _PriorityBar(
              label: 'High Priority',
              percent: 0.35,
              value: '28 zones',
              color: AppColors.priorityHigh,
            ),
            const _PriorityBar(
              label: 'Moderate Priority',
              percent: 0.30,
              value: '24 zones',
              color: AppColors.priorityModerate,
            ),
            const _PriorityBar(
              label: 'Low Priority',
              percent: 0.20,
              value: '20 zones',
              color: AppColors.priorityLow,
            ),
            const SizedBox(height: 32),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryLight.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: AppColors.primary),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export Official Report',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Generate PDF for government sharing',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Generating PDF Report...'))
                      );
                    },
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Export'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityBar extends StatelessWidget {
  final String label;
  final double percent;
  final String value;
  final Color color;

  const _PriorityBar({
    required this.label,
    required this.percent,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
              ),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearPercentIndicator(
            lineHeight: 8.0,
            percent: percent,
            padding: EdgeInsets.zero,
            backgroundColor: color.withAlpha(20),
            progressColor: color,
            barRadius: const Radius.circular(4),
            animation: true,
            animationDuration: 1000,
          ),
        ],
      ),
    );
  }
}
