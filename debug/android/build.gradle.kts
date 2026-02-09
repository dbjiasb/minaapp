allprojects {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
// 根项目 build.gradle.kts
buildscript {
    // 定义版本常量
    val kotlinVersion = "2.1.10"  // 使用最新稳定版

    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.10.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.10")
        classpath("com.google.gms:google-services:4.3.13") // 使用最新稳定版本
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
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
