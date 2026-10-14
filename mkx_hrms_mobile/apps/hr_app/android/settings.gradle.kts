pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")

gradle.beforeProject {
    if (name == "home_widget") {
        val buildFile = buildFile
        if (buildFile != null && buildFile.exists()) {
            var content = buildFile.readText()
            var modified = false
            
            if (content.contains("apply plugin: 'kotlin-android'") && !content.contains("// apply plugin: 'kotlin-android'")) {
                content = content.replace("apply plugin: 'kotlin-android'", "// apply plugin: 'kotlin-android'")
                modified = true
            }
            if (content.contains("apply plugin: \"kotlin-android\"") && !content.contains("// apply plugin: \"kotlin-android\"")) {
                content = content.replace("apply plugin: \"kotlin-android\"", "// apply plugin: \"kotlin-android\"")
                modified = true
            }
            if (content.contains("id 'org.jetbrains.kotlin.android'") && !content.contains("// id 'org.jetbrains.kotlin.android'")) {
                content = content.replace("id 'org.jetbrains.kotlin.android'", "// id 'org.jetbrains.kotlin.android'")
                modified = true
            }
            if (content.contains("id \"org.jetbrains.kotlin.android\"") && !content.contains("// id \"org.jetbrains.kotlin.android\"")) {
                content = content.replace("id \"org.jetbrains.kotlin.android\"", "// id \"org.jetbrains.kotlin.android\"")
                modified = true
            }
            if (content.contains("id 'kotlin-android'") && !content.contains("// id 'kotlin-android'")) {
                content = content.replace("id 'kotlin-android'", "// id 'kotlin-android'")
                modified = true
            }
            if (content.contains("id \"kotlin-android\"") && !content.contains("// id \"kotlin-android\"")) {
                content = content.replace("id \"kotlin-android\"", "// id \"kotlin-android\"")
                modified = true
            }
            if (content.contains("kotlinOptions")) {
                content = content.replace(Regex("kotlinOptions\\s*\\{[\\s\\S]*?\\}"), "")
                modified = true
            }
            if (content.contains("android { compileSdkVersion 34 }")) {
                content = content.replace("android { compileSdkVersion 34 }", "")
                modified = true
            }
            if (!content.contains("compileSdk 35") && !content.contains("compileSdkVersion 35")) {
                content = content + "\n\nandroid { compileSdk 35 }\n"
                modified = true
            }
            
            if (modified) {
                buildFile.writeText(content)
            }
        }
    }
}
