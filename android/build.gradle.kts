allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
    
    tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class.java).configureEach {
        val java17Projects = setOf("package_info_plus", "share_plus", "wakelock_plus")
        val java11Projects = setOf(
            "audio_session",
            "file_picker",
            "shared_preferences_android",
            "path_provider_android",
            "url_launcher_android"
        )

        if (java17Projects.contains(project.name)) {
            kotlinOptions {
                jvmTarget = "17"
            }
        } else if (java11Projects.contains(project.name)) {
            kotlinOptions {
                jvmTarget = "11"
            }
        } else if (project.name != "app") {
            kotlinOptions {
                jvmTarget = "1.8"
            }
        }
    }
}


tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}


