import java.io.FileInputStream
import java.util.Properties
import java.util.concurrent.TimeUnit

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}
val hasReleaseKeystore = keystorePropertiesFile.exists() &&
    !keystoreProperties.getProperty("storePassword").isNullOrBlank() &&
    !keystoreProperties.getProperty("keyPassword").isNullOrBlank() &&
    !keystoreProperties.getProperty("keyAlias").isNullOrBlank()

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

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(
                    keystoreProperties.getProperty("storeFile", "upload-keystore.jks"),
                )
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Usa la firma release persistente cuando existe android/key.properties;
            // en local mantiene debug como fallback para no bloquear compilaciones rápidas.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
    onlyIf { System.getenv("CI") != "true" }
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
