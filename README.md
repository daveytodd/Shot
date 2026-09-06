# Shot

Shot is an iOS 17+ SwiftUI interval photography app for sunrise, day-to-night, and night-to-day Holy Grail timelapses. It uses AVFoundation, a pure-black low-glare interface, exposure ramping, live histogram, session telemetry, and high-bitrate export.

## Requirements

- Xcode 15 or later
- iOS 17 or later
- A physical iPhone for camera, RAW/ProRAW, and HEIF capture
- Swift 5.9+

## Clone and open in Xcode

```bash
git clone https://github.com/daveytodd/Shot.git
cd Shot
open Shot.xcodeproj
```

If opening the source-only starter on a new machine, create an iOS App project named `Shot` in Xcode with SwiftUI and Swift, set the deployment target to iOS 17.0, then add the `Shot/` directory files to the target. The repository intentionally keeps all camera and export code in small, testable Swift files.

Enable these capabilities/permissions in the target:

- Camera Usage Description: `Shot needs camera access to capture your timelapse.`
- Photo Library Additions Usage Description: `Shot saves captured frames and rendered timelapses.`
- Background Modes > Audio, AirPlay, and Picture in Picture only if your product configuration requires background capture.

## Architecture

- `CameraManager`: AVCaptureSession lifecycle, device selection, photo output, HEIF/RAW selection, histogram samples, and exposure control.
- `ExposureRamp`: smoothed log-luminance target and bounded exposure compensation to reduce flicker through extreme transitions.
- `SessionStore`: settings and live session state.
- `Views`: pure OLED black UI, red night-safe accents, capture controls, histogram, telemetry, and settings.
- `VideoExporter`: AVAssetWriter H.265/ProRes export scaffold and frame-directory ZIP handoff point.

## Notes on RAW and ProRAW

RAW/ProRAW availability is device-dependent. Shot checks `isAppleProRAWEnabled` and `availableRawPhotoPixelFormatTypes` at runtime and falls back to HEIF when unavailable. ProRes video is likewise only available on supported hardware and configurations. Never rely on Simulator camera behavior.

## Safety and field use

Use a tripod, keep the device ventilated, and test the selected format before a long session. Long captures can consume substantial storage and battery. The exposure algorithm is deliberately conservative; review test sequences before unattended production use.

## License

Add your preferred license before distribution.
