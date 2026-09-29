# Fix Flutter Android Build Failure

The Flutter build is failing because:
1. **Java Version Incompatibility**: Gradle/Kotlin is picking up Java 25 from the system path, which is causing an `IllegalArgumentException: 25.0.2` in the Kotlin Gradle Plugin.
2. **Out of Memory (OOM)**: The machine has 8GB of RAM, and the JVM is crashing due to insufficient native memory when running Gradle with a 2GB heap.

## Proposed Changes

### [Component] Android Build Configuration

#### [MODIFY] [gradle.properties](file:///C:/Users/prana/projects/Major project/MobileApp/android/gradle.properties)
- Explicitly set `org.gradle.java.home` to Java 17 to avoid compatibility issues with Java 25.
- Reduce Gradle heap size to `1536M` to prevent OOM on the 8GB RAM machine.
- Enable parallel builds and caching for better performance.

#### [MODIFY] [build.gradle.kts](file:///C:/Users/prana/projects/Major project/MobileApp/android/build.gradle.kts)
- Clean up redundant or potentially problematic `subprojects` configurations.
- Ensure consistent versions for core libraries to avoid conflicts.

## Verification Plan

### Automated Tests
- Run `flutter clean` to clear previous failed build artifacts.
- Run `flutter build apk --debug` to verify the build process completes successfully.

### Manual Verification
- Check that the APK is generated in `build/app/outputs/flutter-apk/app-debug.apk`.
- Verify the app launches on the connected device `V2149`.
