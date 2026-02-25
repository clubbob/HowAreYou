import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release 서명: android/key.properties (없으면 debug 서명 사용)
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}
val storePass = keystoreProperties.getProperty("storePassword")
val keyAliasVal = keystoreProperties.getProperty("keyAlias")
val keyPass = keystoreProperties.getProperty("keyPassword")
val storeFileStr = keystoreProperties.getProperty("storeFile") ?: "upload-keystore.jks"
val storeFileResolved = rootProject.file(storeFileStr)
val hasValidReleaseSigning = keystorePropertiesFile.exists() &&
    storePass != null && storePass.isNotBlank() &&
    keyAliasVal != null && keyAliasVal.isNotBlank() &&
    keyPass != null && keyPass.isNotBlank() &&
    storeFileResolved.exists()

tasks.register("validateKeystore") {
    doFirst {
        if (keystorePropertiesFile.exists() && !hasValidReleaseSigning) {
            logger.warn(
                "key.properties가 있지만 release 서명에 필요한 값이 부족합니다. debug 서명으로 빌드합니다.\n" +
                "storePassword, keyPassword, keyAlias, storeFile 확인. keystore 경로: ${storeFileResolved.absolutePath}"
            )
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

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
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
        if (hasValidReleaseSigning) {
            create("release") {
                storeFile = storeFileResolved
                storePassword = storePass
                keyAlias = keyAliasVal
                keyPassword = keyPass
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasValidReleaseSigning) {
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
