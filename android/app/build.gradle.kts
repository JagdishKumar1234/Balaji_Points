import java.util.Properties
import java.io.FileInputStream
import org.gradle.api.tasks.Copy
import java.io.File
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.balaji.points"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    packaging {
        jniLibs.useLegacyPackaging = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.balaji.points"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val props = Properties()
            val file = rootProject.file("app/key.properties")
            if (file.exists()) {
                props.load(FileInputStream(file))

                keyAlias = props["keyAlias"] as String?
                keyPassword = props["keyPassword"] as String?
                val storeFileProp = props["storeFile"] as String?
                if (storeFileProp != null) {
                    // Handle both relative and absolute paths
                    val keystoreFile = if (storeFileProp.startsWith("/")) {
                        file(storeFileProp)
                    } else {
                        file(rootProject.file("app/$storeFileProp"))
                    }
                    storeFile = keystoreFile
                }
                storePassword = props["storePassword"] as String?
            }
        }
    }

    buildTypes {
        getByName("debug") {
            isDebuggable = true
            isMinifyEnabled = false
        }

        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

flutter { source = "../.." }

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

// ----------------------------
// FIX: copy APK where Flutter expects
// ----------------------------
val flutterApkDir = File(
    rootProject.projectDir.parentFile,
    "build/app/outputs/flutter-apk"
)

tasks.register<Copy>("copyFlutterDebugApk") {
    from(layout.buildDirectory.file("outputs/apk/debug/app-debug.apk"))
    into(flutterApkDir)
    rename { "app-debug.apk" }
}

tasks.register<Copy>("copyFlutterReleaseApk") {
    from(layout.buildDirectory.file("outputs/apk/release/app-release.apk"))
    into(flutterApkDir)
    rename { "app-release.apk" }
}

// Copy AAB to where Flutter expects it (build/app/outputs/bundle/release/)
val flutterBundleDir = File(
    rootProject.projectDir.parentFile,
    "build/app/outputs/bundle/release"
)
tasks.register<Copy>("copyFlutterReleaseBundle") {
    from(layout.buildDirectory.file("outputs/bundle/release/app-release.aab"))
    into(flutterBundleDir)
    rename { "app-release.aab" }
}

afterEvaluate {
    tasks.named("assembleDebug") {
        finalizedBy("copyFlutterDebugApk")
    }
    tasks.named("copyFlutterDebugApk") {
        dependsOn("assembleDebug")
    }
    tasks.named("assembleRelease") {
        finalizedBy("copyFlutterReleaseApk")
    }
    tasks.named("copyFlutterReleaseApk") {
        dependsOn("assembleRelease")
    }
    tasks.named("bundleRelease") {
        finalizedBy("copyFlutterReleaseBundle")
    }
    tasks.named("copyFlutterReleaseBundle") {
        dependsOn("bundleRelease")
    }
}
