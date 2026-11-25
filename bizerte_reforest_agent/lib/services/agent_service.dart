import 'dart:convert';

import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────
// OFFLINE GUIDE
// ─────────────────────────────────────────────
class OfflineGuide {
  static String answer(String question) {
    final q = question.toLowerCase();
    if (q.contains('built') || q.contains('building') || q.contains('road')) {
      return 'Do not accept the site if it is inside a building, road, paved parking area, or private sealed surface. Mark it as "Not suitable" and add a note explaining the obstacle.';
    }
    if (q.contains('photo') || q.contains('gps')) {
      return 'For every validation point:\n1. Save GPS first\n2. Take a photo facing the candidate land\n3. Record land type, existing trees, obstacles\n4. Set final suitability rating';
    }
    if (q.contains('priority') || q.contains('high')) {
      return 'High priority means low vegetation and nearby urban pressure (heat island effect). In the field, confirm that the pixel is open land — not a roof or road — and that planting would be physically possible.';
    }
    if (q.contains('candidate') || q.contains('land')) {
      return 'Candidate planting land is identified by satellite as bare or degraded ground, excluding water bodies, existing trees, crops, and built-up areas. Verify on the ground that the land is truly open and accessible.';
    }
    if (q.contains('tree') || q.contains('cover')) {
      return 'The tree cover layer shows areas classified as having existing tree canopy with NDVI > 0.3 and EVI > 0.2. These areas are excluded from reforestation candidates since trees already exist.';
    }
    if (q.contains('water') || q.contains('lake') || q.contains('sea')) {
      return 'Water bodies are detected using MNDWI, NDWI, NIR reflectance, and Dynamic World classification. A 60m safety buffer is applied around detected water. These areas are excluded from candidate land.';
    }
    if (q.contains('report') || q.contains('recommend')) {
      return 'Recommended wording:\n\n"Field validation was used to verify AI-derived priority zones, removing unsuitable built-up, paved, private, or already vegetated areas before final reforestation recommendations."';
    }
    if (q.contains('export') || q.contains('csv')) {
      return 'Go to the Records tab and tap "Copy CSV". The exported CSV includes: ID, timestamp, GPS coordinates, priority class, land type, suitability, trees, obstacles, and notes. Import into QGIS or Excel.';
    }
    return 'Start by checking whether the site is open and plantable. Confirm:\n• Land type (bare soil, grass, pavement, etc.)\n• Existing trees present?\n• Any obstacles or private surfaces?\n• Public access available?\n• Water/maintenance feasibility?\n\nSave GPS, photo, and notes for each site.';
  }
}

// ─────────────────────────────────────────────
// OPENROUTER CLIENT
// ─────────────────────────────────────────────
class OpenRouterClient {
  OpenRouterClient({required this.apiKey, required this.model});

  final String apiKey;
  final String model;

  Future<String> ask(String question) async {
    final response = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://bizerte-reforest-agent.local',
        'X-Title': 'Bizerte Reforest Agent',
      },
      body: jsonEncode({
        'model': model.isEmpty ? 'deepseek/deepseek-chat-v3-0324:free' : model,
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a GIS field assistant for Bizerte, Tunisia. You help users validate Sentinel-2 derived urban tree cover and AI reforestation priority zones. The analysis uses Random Forest classification on Sentinel-2 imagery with NDVI, EVI, MNDWI, BSI, and GLCM texture indices. Priority zones are scored by urban heat density, vegetation deficit, and distance from existing trees. Be concise, practical, and guide GPS/photo/land-type field checks.',
          },
          {'role': 'user', 'content': question},
        ],
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('OpenRouter error ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['choices'][0]['message']['content'] as String;
  }
}
