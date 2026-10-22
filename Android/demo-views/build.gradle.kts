plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
}
android {
    namespace = "media.membrana.adwall.demo.views"
    compileSdk = 36
    defaultConfig {
        applicationId = "media.membrana.adwall.demo.views"
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.1"
    }
    buildFeatures { buildConfig = true;  }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
kotlin { compilerOptions { jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17) } }
dependencies {
    // Publisher integration: the SDK with the Google Mobile Ads SDK. To use GMA Next-Gen instead,
    // replace the line below with the commented one; the app code stays the same.
    implementation("media.membrana:adwall-sdk:1.0.1")
    // implementation("media.membrana:adwall-sdk-nextgen:1.0.1")
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.activity.ktx)
    implementation(libs.androidx.appcompat)
    implementation(libs.androidx.lifecycle.runtime)
    implementation(libs.material.views)
}
