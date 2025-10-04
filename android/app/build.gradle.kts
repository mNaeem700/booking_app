plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") // ✅ use the modern Kotlin plugin name
    id("dev.flutter.flutter-gradle-plugin") // must come after Android + Kotlin
    id("com.google.gms.google-services") // ✅ Firebase plugin
}

android {
    namespace = "com.example.booking_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.booking_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug") // temp signing
        }
    }
}

flutter {
    source = "../.."
}
