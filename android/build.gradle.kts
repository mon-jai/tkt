allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val packageNamespace = "com.monjai.tkt"
project.extensions.extraProperties["namespace"] = packageNamespace

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    // You can also propagate the namespace to subprojects if needed
    project.extensions.extraProperties["namespace"] = packageNamespace
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
