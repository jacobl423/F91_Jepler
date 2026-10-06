# Task Assignment: Survey Android Environment & Build Toolchain

## Objective
Investigate the system's Android development environment and toolchain for building the F91_Jepler Android companion app.

## Context
- Project Root: `/Users/jacobloesch/Documents/F91_Jepler`
- Companion App Root: `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app`
- Android Project Directory: `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app/android`
- Original Request: `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/ORIGINAL_REQUEST.md`

## Specific Investigation Items
1. Check installed Java/JDK version (`java -version`, `javac -version`, `JAVA_HOME`, `/usr/libexec/java_home`).
2. Check Android SDK location (`ANDROID_HOME`, `ANDROID_SDK_ROOT`, `~/Library/Android/sdk`, etc.), installed platform tools, build tools, platforms (e.g. android-34, android-35), and command-line tools.
3. Check the Android project structure in `Software/companion_app/android`:
   - Inspect `gradlew`, `gradle/wrapper/gradle-wrapper.properties` (Gradle version).
   - Inspect `build.gradle`, `app/build.gradle` (compileSdkVersion, targetSdkVersion, minSdkVersion, plugins, dependencies).
   - Inspect `local.properties` (is `sdk.dir` set?).
4. Evaluate if `./gradlew tasks` or `./gradlew assembleDebug` can be executed cleanly, or identify any missing environment variables / configuration needed.

## Output
Write your comprehensive survey findings and recommendations to `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/survey_apk_explorer_1/handoff.md`.
Report back when complete.

## 2026-10-05T05:04:56Z
From: 73b327f6-797d-4e99-bde6-8417a8908ff9 (parent)
You are the Android Environment Explorer for surveying the toolchain to build the F91_Jepler mobile companion app into a sideloadable APK.
Investigate:
1. Java/JDK availability, versions, JAVA_HOME on this macOS system.
2. Android SDK paths, installed platforms, build-tools, and command line tools.
3. Software/companion_app/android project structure, gradlew executable, gradle wrapper, local.properties, and build.gradle files.
4. What exact environment variables or command-line flags are required to execute Gradle cleanly.
