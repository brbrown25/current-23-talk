lazy val scala213 = "2.13.10"
lazy val scala212 = "2.12.17"
lazy val scala213Options = Seq(
  "-Wconf:cat=unused-imports:info",
  "-Wconf:cat=unused-locals:info",
  "-Wconf:cat=unused-params:info",
  "-Ywarn-macros:after",
  "-Ymacro-annotations",
  "-P:semanticdb:synthetics:on"
)

// Reload Sbt on changes to sbt or dependencies
Global / onChangedBuildSource := ReloadOnSourceChanges

ThisBuild / startYear := Some(2021)
ThisBuild / version := sys.env.get("SCALA_BBROWNSOUND_SCHEMA_VERSION").getOrElse(throw new Exception("SCALA_BBROWNSOUND_SCHEMA_VERSION not set!"))
ThisBuild / organization := "com.bbrownsound"
ThisBuild / organizationName := "Bbrownsound"
ThisBuild / scalafixDependencies += "com.github.liancheng" %% "organize-imports" % "0.5.0"
ThisBuild / semanticdbEnabled := false
ThisBuild / semanticdbVersion := scalafixSemanticdb.revision
ThisBuild / scalaVersion := scala213
ThisBuild / crossScalaVersions := List(scala213, scala212)
ThisBuild / versionScheme := Some("early-semver")
(Universal / maintainer) := "brandon@bbrownsound.com"

lazy val baseSettings: Seq[Setting[_]] = Seq(
  Compile / scalacOptions ++= scala213Options
)

lazy val root = (project in file("."))
  .enablePlugins(BuildInfoPlugin, JavaAppPackaging, UniversalPlugin)
  .settings(
    name := "protobuf-models",
    buildInfoKeys := Seq[BuildInfoKey](name, version, scalaVersion, sbtVersion),
    buildInfoPackage := organization.value,
    libraryDependencies ++= Dependencies.protobufDeps,
    javacOptions ++= Seq("-source", "1.8", "-target", "1.8")
  )
  .settings(undeclaredCompileDependenciesFilter -= moduleFilter("org.scala-lang"))
  .settings(undeclaredCompileDependenciesFilter -= moduleFilter("org.scala-lang.modules"))

addCommandAlias("format", ";scalafmtAll ;scalafmtSbt ;scalafixAll ;undeclaredCompileDependenciesTest")

addCommandAlias(
  "formatCheck",
  ";scalafmtCheck ;scalafmtSbtCheck ;scalafixAll --check ;undeclaredCompileDependenciesTest"
)

publishTo := Some(
  "Artifactory Realm" at "https://Bbrownsound.jfrog.io/artifactory/ssc-sbt-dev-local;build.timestamp=" + new java.util.Date().getTime
)
credentials += Credentials(
  "Artifactory Realm",
  "Bbrownsound.jfrog.io",
  sys.env.get("JFROG_USER").getOrElse("JFROG_USER NOT SET"),
  sys.env.get("JFROG_PASSWORD").getOrElse("JFROG_TOKEN NOT SET"),
)
