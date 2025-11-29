import com.android.build.gradle.internal.api.BaseVariantOutputImpl
import java.util.Properties

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.kotlin.serialization)
    alias(libs.plugins.hilt)
    alias(libs.plugins.ksp)
    alias(libs.plugins.google.gms.google.services)
    alias(libs.plugins.google.firebase.crashlytics)
}

// Load local.properties - Kotlin way
val localProps = Properties().apply {
    val file = rootProject.file("local.properties")
    if (file.exists()) {
        file.inputStream().use { load(it) }
    }
}

android {
    namespace = "uz.iportal.axadmixled"
    compileSdk = 35

    defaultConfig {
        applicationId = "uz.iportal.axadmixled"
        minSdk = 21
        targetSdk = 35
        versionCode = 8
        versionName = "0.5"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    signingConfigs {
        create("release") {
            storeFile = file(localProps.getProperty("KEYSTORE_FILE"))
            storePassword = localProps.getProperty("KEYSTORE_PASSWORD")
            keyAlias = localProps.getProperty("KEY_ALIAS")
            keyPassword = localProps.getProperty("KEY_PASSWORD")
        }

        getByName("debug") {}
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
        viewBinding = true
        buildConfig = true
    }

    flavorDimensions += "environment"
    productFlavors {
        create("staging") {
            dimension = "environment"
            versionNameSuffix = "-staging"
            buildConfigField("String", "PORT", "\":8000\"")
            buildConfigField("String", "PROTOCOL", "\"http\"")
            buildConfigField("String", "DOMAIN", "\"192.168.100.173\"")
        }

        create("production") {
            dimension = "environment"
            buildConfigField("String", "PORT", "\"\"")
            buildConfigField("String", "PROTOCOL", "\"https\"")
            buildConfigField("String", "DOMAIN", "\"admin-led.ohayo.uz\"")
        }
    }

    applicationVariants.all {
        val variant = this
        outputs.all {
            val versionCode = defaultConfig.versionCode
            val versionName = defaultConfig.versionName
            val versionNameSuffix =
                variant.productFlavors.firstOrNull()?.versionNameSuffix.orEmpty()
            val debugInfo = if (buildType.name == "debug") "_debug" else ""

            (this as BaseVariantOutputImpl).outputFileName =
                "${rootProject.name}${debugInfo}_v${versionName}${versionNameSuffix}-${versionCode}.apk"
        }
    }
}

dependencies {

    // Core & UI
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.appcompat)
    implementation(libs.androidx.activity.ktx)
    implementation(libs.androidx.fragment.ktx)
    implementation(libs.androidx.constraintlayout)
    implementation(libs.material)

    // Lifecycle
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.lifecycle.viewmodel.ktx)

    // Coroutines
    implementation(libs.kotlinx.coroutines.core)
    implementation(libs.kotlinx.coroutines.android)

    // Datastore
    implementation(libs.androidx.datastore)
    implementation(libs.kotlinx.serialization.json)

    // Room
    implementation(libs.androidx.room.runtime)
    implementation(libs.androidx.room.ktx)
    ksp(libs.androidx.room.compiler)

    // Media3
    implementation(libs.media3.exoplayer)
    implementation(libs.media3.common)
    implementation(libs.media3.ui)
    implementation(libs.media3.okhttp)

    // Image loading
    implementation(libs.coil)

    // Networking
    implementation(libs.retrofit)
    implementation(libs.retrofit.converter.gson)
    implementation(libs.okhttp)
    implementation(libs.okhttp.logging.interceptor)
    implementation(libs.gson)

    // Security
    implementation(libs.androidx.security.crypto)

    // WorkManager
    implementation(libs.androidx.work.runtime.ktx)
    implementation(libs.androidx.hilt.work)

    // Hilt
    implementation(libs.hilt.android)
    ksp(libs.hilt.compiler)
    ksp(libs.androidx.hilt.compiler)

    // Logging & Debug
    implementation(libs.timber)
    debugImplementation(libs.chucker)
    releaseImplementation(libs.chucker.no.op)

    // Firebase / Google
    implementation(libs.firebase.crashlytics)
    implementation(libs.play.services.time)

    // Testing
    testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.junit)
}