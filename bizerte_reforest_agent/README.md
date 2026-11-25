# Bizerte Reforest Agent

A Flutter mobile app prototype for the project:

**Urban Tree Assessment and AI-Based Spatial Identification of Priority Reforestation Areas in Bizerte, Tunisia Using GIS and Remote Sensing**

The app uses:

- OpenStreetMap background map
- Local GeoJSON layers exported from GEE/QGIS
- Offline rule-based field guidance
- Optional OpenRouter chatbot guidance
- Field validation records with GPS, photo path, notes, and suitability result

## Setup

Requires the Flutter SDK (3.3+). Android and iOS platform folders are included.

```bash
cd bizerte_reforest_agent
flutter pub get
flutter run
```

For iPhone builds you need macOS + Xcode. Android can be built on Windows with Android Studio.
See `NATIVE_SETUP.md` for GPS, camera, and internet permissions.

## OpenRouter Setup

The app works offline without an API key. For chatbot mode:

1. Create an OpenRouter API key.
2. Open the Agent tab.
3. Paste the key into the API key field.
4. Ask questions about field validation or reforestation priority.

The key is stored locally using SharedPreferences for the prototype.

## Replace Sample GIS Data

The current GeoJSON files are small placeholders around Bizerte so the app has a beginning state.

Replace these files with your exported layers:

- `assets/geojson/bizerte_boundary.geojson`
- `assets/geojson/priority_zones.geojson`
- `assets/geojson/tree_cover.geojson`
- `assets/geojson/candidate_land.geojson`

The app loads the mobile display copies:

- `assets/geojson/bizerte_boundary_mobile.geojson`
- `assets/geojson/priority_zones_mobile.geojson`
- `assets/geojson/tree_cover_mobile.geojson`
- `assets/geojson/candidate_land_mobile.geojson`

The current mobile copies were filtered from the full exports to keep the map responsive on phones.

Recommended QGIS workflow:

1. Export GeoTIFFs from Google Earth Engine.
2. Open them in QGIS.
3. Polygonize priority/tree/candidate layers.
4. Dissolve or simplify polygons if they are too heavy.
5. Export each layer as GeoJSON using EPSG:4326.
6. Replace the files in `assets/geojson/`.

Keep mobile GeoJSON files small. For field work, simplified polygons are better than huge raw rasters.
