import java.util.Properties

// Upload-key credentials, kept out of version control (ticket 015) and out of
// the repository entirely — `key.properties` names an absolute path to a
// keystore that lives outside the working tree, so no `.gitignore` rule stands
// between a private key and a `git add -A`. check.sh fails if either is
// tracked.
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "nl.evict.quadrim"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // PERMANENT. Once this reaches any Play track, including closed
        // testing, it can never be changed — a different id is a different
        // app, with its own listing, its own reviews and its own install base
        // (D213). Chosen 2026-08-11, before anything was uploaded.
        applicationId = "nl.evict.quadrim"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Absent when the keystore is not installed on this machine. The
            // release build type below refuses to run in that state rather
            // than reading nulls, so an empty config is never used.
            if (!keystoreProperties.isEmpty) {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // **A missing keystore fails the build; it does not fall back to
            // the debug key** (D355). The Flutter template's fallback is what
            // this replaces: it signs a release with the debug certificate and
            // says nothing, so the first sign of trouble is Play rejecting the
            // upload -- or, worse, nothing at all, because ticket 015 recorded
            // Android signing as done on the strength of builds that had it.
            //
            // ponytail: the release check is a task-name match, so a release
            // build reached some other way is unguarded. Upgrade to a doLast
            // assertion on the signing config if that ever happens.
            if (keystoreProperties.isEmpty &&
                gradle.startParameter.taskNames.any { it.contains("Release") }) {
                throw GradleException(
                    "app/android/key.properties is missing -- a release build " +
                        "needs the upload keystore. See ticket 015.",
                )
            }
            signingConfig = signingConfigs.getByName("release")
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
