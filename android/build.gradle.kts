allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val androidCompileSdkVersion = 36

private fun setAndroidCompileSdk(android: Any, compileSdk: Int) {
    val intType = Integer.TYPE
    val methodNames = listOf("compileSdkVersion", "setCompileSdkVersion", "setCompileSdk")

    for (methodName in methodNames) {
        try {
            android.javaClass.getMethod(methodName, intType).invoke(android, compileSdk)
            return
        } catch (e: Exception) {
            // Try the next Android Gradle Plugin API shape.
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    val project = this
    val fixIsarAndroidConfig: (Project) -> Unit = { p ->
        if (p.name == "isar_flutter_libs") {
            p.extensions.findByName("android")?.let { android ->
                setAndroidCompileSdk(android, androidCompileSdkVersion)
                try {
                    android.javaClass.getMethod("setNamespace", String::class.java).invoke(android, "dev.isar.isar_flutter_libs")
                } catch (e: Exception) {
                    // Fail silently or log
                }
            }
        }
    }

    if (project.state.executed) {
        fixIsarAndroidConfig(project)
    } else {
        project.afterEvaluate { fixIsarAndroidConfig(this) }
    }
}
