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
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        kotlinOptions {
            if (this is org.jetbrains.kotlin.gradle.dsl.KotlinJvmOptions) {
                freeCompilerArgs += listOf("-Xskip-metadata-version-check", "-language-version", "1.9")
            }
        }
    }
    project.configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "androidx.core" && requested.name == "core") {
                useVersion("1.15.0")
            }
            if (requested.group == "androidx.core" && requested.name == "core-ktx") {
                useVersion("1.15.0")
            }
            if (requested.group == "androidx.browser" && requested.name == "browser") {
                useVersion("1.8.0")
            }
        }
    }
    afterEvaluate {
        val android = project.extensions.findByType<com.android.build.gradle.BaseExtension>()
        android?.apply {
            compileSdkVersion(35)
            buildToolsVersion("35.0.0")
            defaultConfig {
                targetSdkVersion(34)
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
