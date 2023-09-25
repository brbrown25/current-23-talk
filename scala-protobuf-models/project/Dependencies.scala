import sbt._

object Versions {
  val protobufJava = "3.21.11"
  val scalaPbJson  = "0.12.0"
}

object Dependencies {
  lazy val protobufJava = "com.google.protobuf"   % "protobuf-java"  % Versions.protobufJava
  lazy val scalaPbJson  = "com.thesamet.scalapb" %% "scalapb-json4s" % Versions.scalaPbJson
  lazy val protobufDeps = Seq(protobufJava, scalaPbJson)
}
