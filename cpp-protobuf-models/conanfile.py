import os

from conans import ConanFile, CMake


class ProtobufModels(ConanFile):
    name = "protobuf-models"
    author = "Brandon Brown <brandon@bbrownsound.com>"
    description = "Protobuf Models"
    topics = ()
    settings = "os", "compiler", "build_type", "arch"
    options = {"shared": [True, False], "fPIC": [True, False]}
    default_options = {"shared": False, "fPIC": True}
    generators = "cmake"

    requires = "protobuf/3.21.9"  # This version should match version for generated files if option is used.
    exports_sources = ("CMakeLists.txt", "src/*", "FindProtobufModels.cmake")

    def set_version(self):
        version = os.environ.get("CPP_BBROWNSOUND_SCHEMA_VERSION")
        if version is None:
            raise ValueError('missing CPP_BBROWNSOUND_SCHEMA_VERSION environment variable!')
        self.version = version

    def package_info(self):
        self.cpp_info.name = "protobufModels"
        self.cpp_info.libs = ["protobuf-models"]

    def _configure_cmake(self):
        cmake = CMake(self)
        build_type = self.settings.build_type
        assert build_type == "Release"
        protobuf_install_dir = self.deps_cpp_info["protobuf"].rootpath
        gen_file_path = self.source_folder
        defs = {
            "Protobuf_ROOT": protobuf_install_dir,
            "GENERATED_FILE_PATH": gen_file_path + "/src",
        }

        cmake.configure(defs=defs)

        return cmake

    def build(self):
        cmake = self._configure_cmake()
        cmake.build()

    def package(self):
        cmake = self._configure_cmake()
        cmake.install()
        self.copy("FindProtobufModels.cmake", ".", ".")
