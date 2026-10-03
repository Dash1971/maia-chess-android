import com.android.build.api.dsl.LibraryExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

val stockfishProjects =
    setOf(
        "multistockfish_chess",
        "multistockfish_light",
        "multistockfish_variant",
    )
val nativeSourceDateEpoch =
    providers.gradleProperty("mobileMaiaSourceDateEpoch").orElse("unset")

subprojects {
    if (name in stockfishProjects) {
        plugins.withId("com.android.library") {
            extensions.configure<LibraryExtension> {
                // Flutter's plugin profile variant inherits Debug. Native engine
                // performance qualification must use the same optimization path
                // as Release, while retaining Dart's profile VM/test connection.
                buildTypes.maybeCreate("profile").externalNativeBuild.cmake {
                    arguments += "-DCMAKE_BUILD_TYPE=Release"
                }
                defaultConfig {
                    externalNativeBuild {
                        cmake {
                            // Android's default linker build ID varies between
                            // otherwise identical native builds. The timestamp
                            // argument also makes a new release invalidate old
                            // CMake outputs that may contain __DATE__.
                            arguments +=
                                listOf(
                                    "-DCMAKE_SHARED_LINKER_FLAGS=-Wl,--build-id=none",
                                    "-DCMAKE_CXX_FLAGS=-DMOBILE_MAIA_SOURCE_DATE_EPOCH=${nativeSourceDateEpoch.get()}",
                                )
                        }
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
