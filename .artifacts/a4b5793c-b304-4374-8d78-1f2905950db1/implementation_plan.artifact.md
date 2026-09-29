# Fix Gradle Build Failure in MobileApp

The build is failing because the `camera_android_camerax` plugin is requesting invalid AGP/Kotlin versions and the environment is experiencing DNS/network resolution issues.

## Proposed Changes

### [Component] Flutter Plugin Cache

#### [MODIFY] [build.gradle](file:///C:/Users/prana/AppData/Local/Pub/Cache/hosted/pub.dev/camera_android_camerax-0.6.30/android/build.gradle)
Revert the AGP and Kotlin versions to match the project's stable configuration.

### [Component] Project Configuration

#### [CHECK] [gradle.properties](file:///C:/Users/prana/projects/Major project/MobileApp/android/gradle.properties)
Ensure no proxy settings are missing if required by the network.

## Verification Plan

### Automated Tests
1. Run `flutter pub get` to ensure dependencies are refreshed.
2. Run `./gradlew clean assembleDebug` from the `MobileApp/android` directory.

### Manual Verification
- Verify that the `:camera_android_camerax` project configures successfully without version resolution errors.
