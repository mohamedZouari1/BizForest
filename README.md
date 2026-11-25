# BizForest — Bizerte Reforestation

Urban tree assessment and AI-based identification of priority reforestation areas in Bizerte, Tunisia, using GIS and remote sensing (Sentinel-2, Random Forest).

## Contents

| Folder | Description |
| --- | --- |
| [`bizerte_reforest_agent/`](bizerte_reforest_agent/) | Flutter mobile app (Android / iOS): interactive map of priority zones, field surveys, planting and incident records, Firestore sync, and an offline/OpenRouter field assistant. |
| [`bizforest_website/`](bizforest_website/) | Static website (HTML/CSS + Leaflet): home, interactive map, data and about pages. |

## Run the mobile app

```bash
cd bizerte_reforest_agent
flutter pub get
flutter run
```

## Run the website

The map loads GeoJSON with `fetch`, so serve the folder over HTTP rather than opening the file directly:

```bash
cd bizforest_website
python -m http.server 8000
# open http://localhost:8000
```
