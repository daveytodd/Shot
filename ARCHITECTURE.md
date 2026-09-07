# Shot architecture

Shot is a pure SwiftUI sunrise timelapse app with an OLED-black presentation. The camera path is standalone: `CameraEngine` owns AVFoundation configuration and manual exposure capture, while `CaptureSessionStore` owns intervalometer state and frame scheduling.

`DJIGimbalManager` is an optional CoreBluetooth adapter. It is instantiated independently, scans only when requested, and the capture session checks `isPaired` before attempting waypoint movement. A missing, disconnected, or unsupported gimbal never blocks handheld/tripod capture. UI labels and the gimbal toolbar action appear as paired state changes.

The BLE service/packet definitions are isolated in `DJIGimbalManager.swift`. DJI firmware generations can use different UUIDs and packet formats; replace `serviceUUID` and `GimbalPacket` with the validated profile for the target Osmo Mobile model without changing the capture or UI layers. Do not ship unverified motor packets to hardware.

Required Info.plist keys: `NSCameraUsageDescription`, `NSBluetoothAlwaysUsageDescription`, and `NSPhotoLibraryAddUsageDescription` when persistence is added. The Xcode target should include AVFoundation, CoreBluetooth, SwiftUI, and Photos (for the eventual photo-library writer).

The current branch is a clean Swift source architecture; add an iOS App target/project file in Xcode and include the `Shot` directory. Test manual exposure limits per device, background execution/power behavior, and each gimbal firmware profile on physical hardware.