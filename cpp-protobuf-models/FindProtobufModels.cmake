find_path(ProtobufModels_INCLUDE_DIR NAMES com/bbrownsound/proto/)
if (NOT ProtobufModels_INCLUDE_DIR)
  message(WARNING "Failed to find ProtobufModels include dir")
  return()
endif()

find_library(ProtobufModels_LIBRARY NAMES protobuf-models)
if (NOT ProtobufModels_LIBRARY)
  message(WARNING "Failed to find ProtobufModels library dir")
  return()
endif()

include(CMakeFindDependencyMacro)
find_dependency(Protobuf)

set(ProtobufModels_FOUND TRUE)
set(ProtobufModels_INCLUDE_DIRS ${ProtobufModels_INCLUDE_DIR})
set(ProtobufModels_LIBRARIES ${CONAN_LIBS_ProtobufModels})
mark_as_advanced(ProtobufModels_LIBRARY_DIR ProtobufModels_INCLUDE_DIR)


if (NOT TARGET libprotobuf-models)
  add_library(libprotobuf-models STATIC IMPORTED)
  set_target_properties(libprotobuf-models PROPERTIES
    IMPORTED_LOCATION "${ProtobufModels_LIBRARY}"
    INTERFACE_INCLUDE_DIRECTORIES "${ProtobufModels_INCLUDE_DIR}"
    INTERFACE_LINK_LIBRARIES protobuf::libprotobuf
  )
endif()
