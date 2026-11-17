import java.util.concurrent.TimeUnit

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.gym_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.gym_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}

tasks.register("setupAdbReverse") {
    description = "Configures adb reverse tcp:8080 tcp:8080 for connected USB Android devices."
    outputs.upToDateWhen { false }
    val adbProvider = androidComponents.sdkComponents.adb
    doLast {
        runCatching {
            val adbExe = adbProvider.get().asFile.absolutePath
            val devicesProc = ProcessBuilder(adbExe, "devices")
                .redirectErrorStream(true)
                .start()
            val devicesOut = devicesProc.inputStream.bufferedReader().readText()
            devicesProc.waitFor(3, TimeUnit.SECONDS)

            devicesOut.lineSequence()
                .map { it.trim().split(Regex("\\s+")) }
                .filter { parts -> parts.size >= 2 && parts[1] == "device" }
                .map { parts -> parts[0] }
                .forEach { serial ->
                    ProcessBuilder(adbExe, "-s", serial, "reverse", "tcp:8080", "tcp:8080")
                        .redirectErrorStream(true)
                        .start()
                        .waitFor(3, TimeUnit.SECONDS)
                }
        }
    }
}

tasks.matching { it.name == "preBuild" }.configureEach {
    dependsOn("setupAdbReverse")
}
