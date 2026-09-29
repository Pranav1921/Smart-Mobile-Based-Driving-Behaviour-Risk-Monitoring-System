# Fix Build Failures and Upgrade Versions

The project is failing to build due to invalid Android Gradle Plugin (AGP) and Gradle versions, as well as an outdated Kotlin version. There are also indications of memory issues (JVM crashes).

## Proposed Changes

### Build Configuration

#### [MODIFY] [settings.gradle.kts](file:///C:/Users/prana/projects/Major project/MobileApp/android/settings.gradle.kts)
- Downgrade AGP from `8.11.1` to `8.7.0` (latest stable).
- Upgrade Kotlin from `2.0.21` to `2.1.0` (as recommended by Flutter warning).

#### [MODIFY] [gradle-wrapper.properties](file:///C:/Users/prana/projects/Major project/MobileApp/android/gradle/wrapper/gradle-wrapper.properties)
- Downgrade Gradle from `8.14` to `8.10.2` (latest stable) to ensure compatibility and stability.

#### [MODIFY] [gradle.properties](file:///C:/Users/prana/projects/Major project/MobileApp/android/gradle.properties)
- Ensure memory settings are reasonable for the host system (7GB RAM).

## Verification Plan

### Automated Tests
- Run `flutter clean` followed by `flutter run` to verify the build completes successfully.
