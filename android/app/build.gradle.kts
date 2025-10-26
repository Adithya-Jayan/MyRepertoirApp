import java.util.Properties
import java.io.FileInputStream
// Import the necessary task type
import com.android.build.gradle.tasks.PackageApplication

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val flutterProperties = Properties()
val flutterPropertiesFile = rootProject.file("local.properties")
if (flutterPropertiesFile.exists()) {
    flutterProperties.load(flutterPropertiesFile.reader(Charsets.UTF_8))
}

val flutterVersionCode = flutterProperties.getProperty("flutter.versionCode")?.toInt() ?: 1
val flutterVersionName = flutterProperties.getProperty("flutter.versionName") ?: "1.0"

android {
    namespace = "io.github.adithya_jayan.myrepertoirapp"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "io.github.adithya_jayan.myrepertoirapp"
        minSdk = 29
        targetSdk = 36
        versionCode = flutterVersionCode
        versionName = flutterVersionName
        externalNativeBuild {
            cmake {
                cppFlags += "-std=c++17"
            }
        }
    }

    sourceSets {
        getByName("main") {
            jniLibs.srcDirs("src/main/jniLibs")
        }
    }

    signingConfigs {
        create("release") {
            val keyProperties = Properties()
            val keyPropertiesFile = rootProject.file("key.properties")
            if (keyPropertiesFile.exists()) {
                keyProperties.load(FileInputStream(keyPropertiesFile))
                keyAlias = keyProperties["keyAlias"] as String
                keyPassword = keyProperties["keyPassword"] as String
                storeFile = file(keyProperties["storeFile"] as String)
                storePassword = keyProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            resValue("string", "app_name", "Repertoire")
        }
    }

    flavorDimensions += "app"
    productFlavors {
        create("fdroid") {
            dimension = "app"
            applicationId = "io.github.adithya_jayan.myrepertoirapp.fdroid"
            resValue("string", "app_name", "Repertoire")
        }
        create("nightly") {
            dimension = "app"
            applicationId = "io.github.adithya_jayan.myrepertoirapp.nightly"
            resValue("string", "app_name", "Repertoire Nightly")
        }
    }

    } // <--- This is the closing brace for 'android'

flutter {
    source = "../.."
}