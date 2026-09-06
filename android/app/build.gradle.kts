import java.security.MessageDigest

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKeystorePath = System.getenv("MOBILE_MAIA_KEYSTORE")
val releaseStorePassword = System.getenv("MOBILE_MAIA_STORE_PASSWORD")
val releaseKeyPassword = System.getenv("MOBILE_MAIA_KEY_PASSWORD")
val releaseSigningValues = listOf(
    releaseKeystorePath,
    releaseStorePassword,
    releaseKeyPassword,
)

require(releaseSigningValues.all { it == null } || releaseSigningValues.all { it != null }) {
    "Set MOBILE_MAIA_KEYSTORE, MOBILE_MAIA_STORE_PASSWORD, and " +
        "MOBILE_MAIA_KEY_PASSWORD together."
}

dependencies {
    implementation("com.microsoft.onnxruntime:onnxruntime-android:1.23.2")
    androidTestImplementation("androidx.test.ext:junit:1.2.1")
    androidTestImplementation("androidx.test:runner:1.6.2")
}

android {
    namespace = "com.dash1971.maia_chess"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.dash1971.maia_chess"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    signingConfigs {
        if (releaseKeystorePath != null) {
            create("mobileMaiaRelease") {
                storeFile = file(releaseKeystorePath)
                storePassword = releaseStorePassword
                keyAlias = "mobile-maia"
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            // F-Droid can build an unsigned release when signing credentials are
            // absent. Official Mobile Maia releases provide all three variables.
            signingConfig = signingConfigs.findByName("mobileMaiaRelease")
            // The bundled ONNX model dominates APK size; Java/Kotlin shrinking
            // adds release risk without a meaningful download-size reduction.
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// Fail before Flutter copies assets: GitHub ZIP downloads and incomplete LFS
// clones otherwise produce an installable APK with a tiny text pointer as Maia.
val verifyMaiaModel by tasks.registering {
    val model = rootProject.file("../assets/models/maia3-79m.onnx")
    inputs.file(model)
    doLast {
        require(model.isFile && model.length() == 316_034_244L) {
            "Maia model missing or wrong size. Run git lfs install && git lfs pull."
        }
        val digest = MessageDigest.getInstance("SHA-256")
        model.inputStream().buffered().use { stream ->
            val buffer = ByteArray(1024 * 1024)
            while (true) {
                val count = stream.read(buffer)
                if (count < 0) break
                digest.update(buffer, 0, count)
            }
        }
        val sha256 = digest.digest().joinToString("") { "%02x".format(it) }
        require(sha256 == "3454b03ae78baa64a87b345fdb1a457265d912caec531039b074f07eda0d8010") {
            "Maia model SHA-256 mismatch. Restore the pinned Git LFS object."
        }
    }
}
tasks.matching { it.name == "preBuild" || it.name.startsWith("compileFlutterBuild") }.configureEach {
    dependsOn(verifyMaiaModel)
}
