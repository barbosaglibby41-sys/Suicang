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

subprojects {
    afterEvaluate {
        extensions.findByName("android")?.let { androidExtension ->
            when (androidExtension) {
                is com.android.build.gradle.AppExtension -> androidExtension.compileSdkVersion = "android-36"
                is com.android.build.gradle.LibraryExtension -> androidExtension.compileSdkVersion = "android-36"
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
