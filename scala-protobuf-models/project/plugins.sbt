resolvers += Classpaths.sbtPluginReleases

addDependencyTreePlugin

addSbtPlugin("ch.epfl.scala"             % "sbt-bloop"                 % "1.4.8")
addSbtPlugin("ch.epfl.scala"             % "sbt-scalafix"              % "0.9.29")
addSbtPlugin("com.eed3si9n"              % "sbt-buildinfo"             % "0.10.0")
addSbtPlugin("com.github.cb372"          % "sbt-explicit-dependencies" % "0.2.16")
addSbtPlugin("com.typesafe.sbt"          % "sbt-native-packager"       % "1.8.1")
addSbtPlugin("io.github.davidgregory084" % "sbt-tpolecat"              % "0.1.20")
addSbtPlugin("org.scalameta"             % "sbt-scalafmt"              % "2.4.3")
addSbtPlugin("org.scoverage"             % "sbt-scoverage"             % "1.8.2")
