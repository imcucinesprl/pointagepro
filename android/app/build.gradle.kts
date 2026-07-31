import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")

    // Firebase
    id("com.google.gms.google-services")

    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

/*
|--------------------------------------------------------------------------
| Configuration de signature Google Play
|--------------------------------------------------------------------------
*/

val keystoreProperties = Properties()

val keystorePropertiesFile =
    rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    FileInputStream(
        keystorePropertiesFile
    ).use { inputStream ->
        keystoreProperties.load(
            inputStream
        )
    }
}

val releaseKeyAlias =
    keystoreProperties
        .getProperty("keyAlias")
        ?.trim()
        .orEmpty()

val releaseKeyPassword =
    keystoreProperties
        .getProperty("keyPassword")
        ?.trim()
        .orEmpty()

val releaseStoreFile =
    keystoreProperties
        .getProperty("storeFile")
        ?.trim()
        .orEmpty()

val releaseStorePassword =
    keystoreProperties
        .getProperty("storePassword")
        ?.trim()
        .orEmpty()

val hasReleaseSigningConfig =
    keystorePropertiesFile.exists() &&
        releaseKeyAlias.isNotEmpty() &&
        releaseKeyPassword.isNotEmpty() &&
        releaseStoreFile.isNotEmpty() &&
        releaseStorePassword.isNotEmpty()

android {
    namespace =
        "com.izs.pointagepro"

    compileSdk =
        flutter.compileSdkVersion

    ndkVersion =
        flutter.ndkVersion

    compileOptions {
    sourceCompatibility =
        JavaVersion.VERSION_17

    targetCompatibility =
        JavaVersion.VERSION_17

    isCoreLibraryDesugaringEnabled = true
}

    kotlinOptions {
        jvmTarget =
            JavaVersion.VERSION_17
                .toString()
    }

    defaultConfig {
        applicationId =
            "com.izs.pointagepro"

        minSdk =
            flutter.minSdkVersion

        targetSdk =
            flutter.targetSdkVersion

        versionCode =
            flutter.versionCode

        versionName =
            flutter.versionName
    }

    /*
    |--------------------------------------------------------------------------
    | Signatures
    |--------------------------------------------------------------------------
    */

    signingConfigs {
        if (hasReleaseSigningConfig) {
            create("release") {
                keyAlias =
                    releaseKeyAlias

                keyPassword =
                    releaseKeyPassword

                storeFile =
                    file(
                        releaseStoreFile
                    )

                storePassword =
                    releaseStorePassword
            }
        }
    }

    /*
    |--------------------------------------------------------------------------
    | Types de build
    |--------------------------------------------------------------------------
    */

    buildTypes {
        debug {
            /*
             * Le build debug utilise automatiquement
             * la signature debug Android.
             */
        }

        release {
            if (hasReleaseSigningConfig) {
                signingConfig =
                    signingConfigs
                        .getByName(
                            "release"
                        )
            } else {
                /*
                 * Permet de compiler localement sans planter.
                 * Pour publier sur Google Play, key.properties
                 * doit être complet.
                 */
                signingConfig =
                    signingConfigs
                        .getByName(
                            "debug"
                        )
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring(
        "com.android.tools:desugar_jdk_libs:2.1.4"
    )
}

flutter {
    source = "../.."
}