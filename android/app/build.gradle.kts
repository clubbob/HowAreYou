import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release 서명: android/key.properties (없으면 debug 서명 사용)
// 경로 표준화: 항상 android/ 기준 (rootProject = android/)
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

// 빌드 전 keystore 존재 여부 검증 (경로 오류 즉시 파악)
tasks.register("validateKeystore") {
    doFirst {
        if (keystorePropertiesFile.exists()) {
            val storeFilePath = keystoreProperties["storeFile"] ?: "upload-keystore.jks"
            val storeFile = rootProject.file(storeFilePath)
            if (!storeFile.exists()) {
                throw GradleException(
                    "Keystore file not found at: ${storeFile.absolutePath}\n" +
                    "Check key.properties storeFile value. Expected: upload-keystore.jks in android/"
                )
            }
        }
    }
}

android {
    namespace = "com.andy.howareyou"
    compileSdk = 36  // Android SDK 36.1.0
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.andy.howareyou"
        // Android 8 (API 26) 이상 지원
        minSdk = 26
        targetSdk = 36  // Android SDK 36.1.0
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                // rootProject.file() = android/ 기준, 경로 불일치 차단
                storeFile = rootProject.file(keystoreProperties["storeFile"] ?: "upload-keystore.jks")
                storePassword = keystoreProperties["storePassword"] as String?
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

// Release 빌드 시 keystore 검증 선행
tasks.named("preBuild").configure {
    dependsOn("validateKeystore")
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("com.android.installreferrer:installreferrer:2.2")
}
