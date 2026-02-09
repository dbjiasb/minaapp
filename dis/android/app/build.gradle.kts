plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

dependencies {
    implementation("com.facebook.android:facebook-android-sdk:16.0.0")
    implementation("com.adjust.sdk:adjust-android-meta-referrer:5.1.0")
    implementation("com.google.gms:google-services:4.3.13")
    implementation(platform("com.google.firebase:firebase-bom:31.2.0"))
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.android.billingclient:billing:7.0.0")
}

android {
    namespace = "com.soulink.aibot.release"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"
    buildToolsVersion = "35.0.0"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            storeFile = file("./soulink.jks")
            storePassword = "123456"
            keyAlias = "soulink-alias"
            keyPassword = "123456"
        }
    }

    defaultConfig {
        applicationId = "com.soulink.aibot.release"

        minSdk = 24
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            abiFilters.addAll(listOf("arm64-v8a"))
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false  // 开启代码混淆
            isShrinkResources = false  // 开启资源压缩
            signingConfig = signingConfigs.getByName("release")
        }
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

