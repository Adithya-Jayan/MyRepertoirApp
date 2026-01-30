import com.android.build.gradle.internal.api.ApkVariantOutputImpl
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

    android {
    namespace = "io.github.adithya_jayan.myrepertoirapp"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "io.github.adithya_jayan.myrepertoirapp"
        minSdk = 29
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        missingDimensionStrategy("app", "fdroid")
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
}

flutter {
    source = "../.."
}

val abiCodes = mapOf("armeabi-v7a" to 1, "arm64-v8a" to 2, "x86_64" to 3)
android.applicationVariants.configureEach {
    val variant = this
    variant.outputs.forEach { output ->
        val abiVersionCode = abiCodes[output.filters.find { it.filterType == "ABI" }?.identifier]
        if (abiVersionCode != null) {
            val originalVersionCode = flutter.versionCode as? Int ?: 1
            (output as ApkVariantOutputImpl).versionCodeOverride = originalVersionCode * 10 + abiVersionCode
        }
    }
}