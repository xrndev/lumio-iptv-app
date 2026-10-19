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
// Algunos plugins (p. ej. file_picker) se publican compilados contra Android 34 pero sus
// dependencias (androidx lifecycle) exigen 36: se fuerza la misma compileSdk en todos.
subprojects {
    val forceCompileSdk: Project.() -> Unit = {
        (extensions.findByName("android") as? com.android.build.gradle.BaseExtension)
            ?.compileSdkVersion(36)
    }
    if (state.executed) forceCompileSdk() else afterEvaluate { forceCompileSdk() }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
