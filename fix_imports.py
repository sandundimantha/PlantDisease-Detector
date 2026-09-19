import os

base_dir = r"c:\Users\Admin\Desktop\Plant_Disease\PlantDisease-Detector\lib"

# 1. Fix app_router.dart
router_path = os.path.join(base_dir, "core", "routing", "app_router.dart")
with open(router_path, "r", encoding="utf-8") as f:
    router_content = f.read()
router_content = router_content.replace(
    "builder: (context, state) => const ScanningScreen(),",
    "builder: (context, state) => ScanningScreen(imagePath: state.extra as String? ?? ''),"
)
with open(router_path, "w", encoding="utf-8") as f:
    f.write(router_content)

# 2. Fix scanning_screen.dart
scanning_path = os.path.join(base_dir, "features", "diagnosis", "presentation", "screens", "scanning_screen.dart")
with open(scanning_path, "r", encoding="utf-8") as f:
    scanning_content = f.read()

# Replace ScanRecord initialization
scanning_content = scanning_content.replace(
"""        scan = ScanRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          imagePath: widget.imagePath,
          diseaseName: result['label'] as String,
          confidenceScore: result['confidence'] as double,
          date: DateTime.now(),
        );""",
"""        scan = ScanRecord(
          id: DateTime.now().millisecondsSinceEpoch,
          imageUrl: widget.imagePath,
          diseaseName: result['label'] as String,
          confidenceScore: result['confidence'] as double,
          scannedAt: DateTime.now(),
          latinName: 'Unknown',
          cropType: 'Unknown',
          severity: 'none',
          fieldLocation: 'Unknown',
          treatable: false,
        );"""
)

scanning_content = scanning_content.replace(
"""        scan = ScanRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          imagePath: widget.imagePath,
          diseaseName: 'Unknown',
          confidenceScore: 0.0,
          date: DateTime.now(),
        );""",
"""        scan = ScanRecord(
          id: DateTime.now().millisecondsSinceEpoch,
          imageUrl: widget.imagePath,
          diseaseName: 'Unknown',
          confidenceScore: 0.0,
          scannedAt: DateTime.now(),
          latinName: 'Unknown',
          cropType: 'Unknown',
          severity: 'none',
          fieldLocation: 'Unknown',
          treatable: false,
        );"""
)

with open(scanning_path, "w", encoding="utf-8") as f:
    f.write(scanning_content)


# 3. Fix diagnostic_result_screen.dart
diag_path = os.path.join(base_dir, "features", "diagnosis", "presentation", "screens", "diagnostic_result_screen.dart")
with open(diag_path, "r", encoding="utf-8") as f:
    diag_content = f.read()

diag_content = diag_content.replace("id: _scan.id,", "id: _scan.id.toString(),")
diag_content = diag_content.replace("clientUuid: _scan.id,", "clientUuid: _scan.id.toString(),")
diag_content = diag_content.replace("_scan.imagePath", "_scan.imageUrl")

# Fix Row with 1 positional arg
diag_content = diag_content.replace(
"""                    Builder(
                      builder: (context) {
                        final officer = getNearestOfficer(locationState.address);
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,""",
"""                    children: [
                      Builder(
                        builder: (context) {
                          final officer = getNearestOfficer(locationState.address);
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,"""
)
diag_content = diag_content.replace(
"""                      }
                    ),
                  ),""",
"""                        }
                      ),
                    ],
                  ),"""
)

with open(diag_path, "w", encoding="utf-8") as f:
    f.write(diag_content)

# 4. Fix tflite_service.dart imports and methods
tflite_path = os.path.join(base_dir, "features", "diagnosis", "data", "tflite_service.dart")
with open(tflite_path, "r", encoding="utf-8") as f:
    tflite_content = f.read()

tflite_content = tflite_content.replace("import 'package:image/image.dart' as img;", "import 'package:image/image.dart' as img;")
tflite_content = tflite_content.replace("img.decodeImage", "img.decodeImage")
tflite_content = tflite_content.replace("img.copyResize", "img.copyResize")
# Wait, decodeImage and copyResize are correct for package:image. The issue was that package:image was missing!

with open(tflite_path, "w", encoding="utf-8") as f:
    f.write(tflite_content)

print("Fixed dart files.")
