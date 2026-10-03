plugins {
    kotlin("jvm") version "2.4.20"
    application
}
repositories { mavenCentral() }
kotlin {
    jvmToolchain(17)
    sourceSets.main {
        kotlin.srcDir("../../../android/app/src/main/kotlin")
        kotlin.include("**/*Stub.kt", "**/Probe.kt", "**/SoundEffectBridge.kt")
    }
}
application { mainClass.set("ProbeKt") }
