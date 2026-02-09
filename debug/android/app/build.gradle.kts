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
    namespace = "com.example.soulinkapp"
    compileSdk = 36
//    ndkVersion = flutter.ndkVersion
    ndkVersion = "27.0.12077973"
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.docare.solink"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        ndk {
            abiFilters.add("arm64-v8a")
            abiFilters.add("x86_64")
        }
    }

//    packagingOptions {
//        pickFirst 'lib/**/libliteavsdk.so'
//    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
//            minifyEnabled true
//            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}

flutter {
    source = "../.."
}
