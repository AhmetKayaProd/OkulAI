# Firebase Test Lab - Automated Testing

## Test Configuration

### Test Matrix
- **Device Types**: Multiple Android devices (real + virtual)
- **Android Versions**: 8.0+ (API 26+)
- **Test Type**: Robo test (automated UI exploration)
- **Timeout**: 5 minutes per device

### Commands

#### Submit Test (via Firebase CLI)
```bash
# Build release APK first
flutter build apk --release

# Submit to Test Lab
firebase test android run \
  --type robo \
  --app build/app/outputs/apk/release/app-release.apk \
  --timeout 5m \
  --results-bucket=gs://okulai-dev_test-lab-results \
  --results-dir=homework-ai-test-$(date +%Y%m%d-%H%M%S)
```

#### Submit Test (via gcloud CLI)
```bash
gcloud firebase test android run \
  --type robo \
  --app build/app/outputs/apk/release/app-release.apk \
  --device model=Pixel2,version=28,locale=tr,orientation=portrait \
  --timeout 5m
```

#### View Results
```bash
# Via Firebase Console
# https://console.firebase.google.com/project/okulai-dev/testlab/histories

# Via CLI
firebase test android list-device-capacities
```

### Test Scenarios (Robo Test)

Robo test will automatically:
1. Launch the app
2. Explore all screens systematically
3. Interact with UI elements
4. Take screenshots at each step
5. Detect crashes and ANRs
6. Generate video recording

### Expected Flow
1. App launches → School type selection
2. Login/Signup screens
3. Authentication flow
4. Main app screens (if authentication allows)
5. Navigation exploration
6. Back button handling

### Known Limitations
- Robo test may not complete full authentication flow
- Some screens require specific user roles
- Firebase auth may block test accounts
- Network-dependent features may fail

## Alternative: Instrumentation Tests

For more controlled testing, create instrumentation tests:

```dart
// test_driver/app_test.dart
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('KresAI App', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver.close();
    });

    test('launches and shows school type selection', () async {
      await driver.waitFor(find.text('KresAI'));
      // Add more test steps
    });
  });
}
```

Then run:
```bash
flutter drive --target=test_driver/app.dart
```

## Manual Test Lab Submission (Web Console)

1. Go to: https://console.firebase.google.com/project/okulai-dev/testlab
2. Click "Run a test"
3. Upload: `build/app/outputs/apk/release/app-release.apk`
4. Choose "Robo test"
5. Select devices (recommended):
   - Pixel 2 (API 28)
   - Samsung Galaxy S9 (API 28)
   - OnePlus 6 (API 29)
6. Click "Start test"
7. Wait 5-10 minutes
8. Review results (screenshots, video, logs)

## Cost
- **Spark plan (free)**: 10 tests/day on virtual devices
- **Blaze plan**: Real devices available (pay-per-use)
