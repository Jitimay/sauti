group = "com.sauti.hybrid_ai"
version = "1.0-SNAPSHOT"

rootProject.allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.library")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

android {
    namespace = "com.sauti.hybrid_ai"
    compileSdk = flutter.compileSdkVersion

    defaultConfig {
        // Firebase AI Logic on-device inference (Gemini Nano via ML Kit's
        // Prompt API) requires API level 26.
        minSdk = 26
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    // firebase-ai 18.2.0 is the first release with OnDeviceConfig /
    // InferenceMode; the on-device library is not in the Firebase BoM yet.
    implementation("com.google.firebase:firebase-ai:18.2.0")
    implementation("com.google.firebase:firebase-ai-ondevice:16.0.0-beta08")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
}
