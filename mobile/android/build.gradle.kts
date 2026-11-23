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

    afterEvaluate {
        val androidExt = project.extensions.findByName("android")
        if (androidExt != null) {
            // --- Namespace fix for legacy plugins that still use package= in AndroidManifest.xml ---
            // AGP 8+ no longer supports setting namespace via the package attribute in the manifest.
            // We detect the package from the source AndroidManifest.xml and inject it as the namespace.
            try {
                val nsGetter = androidExt.javaClass.methods.find { it.name == "getNamespace" && it.parameterTypes.isEmpty() }
                val currentNamespace = nsGetter?.invoke(androidExt) as? String
                if (currentNamespace.isNullOrBlank()) {
                    // Try to read package from src/main/AndroidManifest.xml
                    val manifestFile = project.file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val content = manifestFile.readText()
                        val match = Regex("""package\s*=\s*["']([^"']+)["']""").find(content)
                        val pkg = match?.groupValues?.get(1)
                        if (!pkg.isNullOrBlank()) {
                            val setNs = androidExt.javaClass.methods.find {
                                it.name == "setNamespace" && it.parameterTypes.size == 1 && it.parameterTypes[0] == String::class.java
                            }
                            setNs?.invoke(androidExt, pkg)
                        }
                    }
                }
            } catch (_: Exception) {}
            // Ensure compileSdkVersion is set to at least 36
            try {
                val method = androidExt.javaClass.methods.find {
                    it.name == "compileSdkVersion" && it.parameterTypes.size == 1 && it.parameterTypes[0] == Int::class.java
                }
                method?.invoke(androidExt, 36)
            } catch (_: Exception) {}
        }
    }

}

subprojects {
    project.evaluationDependsOn(":app")
}


tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
