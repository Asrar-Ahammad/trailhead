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

    project.plugins.withId("com.android.library") {
        if (project.name == "isar_flutter_libs") {
            val androidExt = project.extensions.findByName("android")
                ?: throw GradleException("Android extension missing for isar_flutter_libs")
            val namespaceSetter = androidExt.javaClass.methods.find {
                it.name == "setNamespace" &&
                    it.parameterTypes.size == 1 &&
                    it.parameterTypes[0] == String::class.java
            } ?: throw GradleException("Could not set namespace for isar_flutter_libs")

            namespaceSetter.invoke(androidExt, "dev.isar.isar_flutter_libs")
        }
    }

    afterEvaluate {
        val androidExt = project.extensions.findByName("android")
        if (androidExt != null) {
            try {
                val method = androidExt.javaClass.methods.find { it.name == "compileSdkVersion" && it.parameterTypes.size == 1 && it.parameterTypes[0] == Int::class.java }
                method?.invoke(androidExt, 35)
            } catch (e: Exception) {}
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}


tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
