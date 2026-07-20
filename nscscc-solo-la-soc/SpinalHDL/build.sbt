name := "test"

ThisBuild / version := "1.0"
ThisBuild / scalaVersion := "2.12.20"

val spinalVersion = "1.10.1"
val spinalCore = "com.github.spinalhdl" %% "spinalhdl-core" % spinalVersion
val spinalLib = "com.github.spinalhdl" %% "spinalhdl-lib" % spinalVersion
val spinalIdslPlugin = compilerPlugin("com.github.spinalhdl" %% "spinalhdl-idsl-plugin" % spinalVersion)
val scalatest= "org.scalatest" %% "scalatest" % "3.2.16" % "test"
val scalatest_funsuite = "org.scalatest" %% "scalatest-funsuite" % "3.2.16" % "test"

libraryDependencies += spinalCore
libraryDependencies += spinalLib
libraryDependencies += spinalIdslPlugin
libraryDependencies += scalatest
libraryDependencies += scalatest_funsuite

fork := true