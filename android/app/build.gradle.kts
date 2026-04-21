import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}
val hasReleaseSigning = keystorePropertiesFile.exists()

android {
    namespace = "com.cookmate.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.cookmate.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                fun requireProperty(name: String): String = requireNotNull(
                    keystoreProperties.getProperty(name)?.takeIf { it.isNotBlank() }
                ) { "key.properties is missing or blank for '$name'" }

                storeFile = rootProject.file(requireProperty("storeFile"))
                storePassword = requireProperty("storePassword")
                keyAlias = requireProperty("keyAlias")
                keyPassword = requireProperty("keyPassword")
            }
        }
    }

    packaging {
        jniLibs {
            // Exclude native libraries shipped by flutter_gemma that are not
            // needed for LLM chat (vision, image generation, embeddings, RAG).
            excludes += setOf(
                "**/libmediapipe_tasks_vision_jni.so",
                "**/libmediapipe_tasks_vision_image_generator_jni.so",
                "**/libimagegenerator_gpu.so",
                "**/libgemma_embedding_model_jni.so",
                "**/libgecko_embedding_model_jni.so",
                "**/libtext_chunker_jni.so",
                "**/libsqlite_vector_store_jni.so",
            )
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
