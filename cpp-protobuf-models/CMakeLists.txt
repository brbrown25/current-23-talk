project(protobuf-models)
cmake_minimum_required(VERSION 3.12)
set (CMAKE_CXX_STANDARD 11)

find_package(Protobuf REQUIRED)
include_directories(${Protobuf_INCLUDE_DIRS})
get_target_property(PROTOC_EXE protobuf::protoc IMPORTED_LOCATION)

file(GLOB_RECURSE PB_CC "${GENERATED_FILE_PATH}/*.cc")
if (NOT PB_CC)
    message(FATAL_ERROR "Failed to find .cc files in ${GENERATED_FILE_PATH}")
endif()

file(GLOB_RECURSE PB_H "${GENERATED_FILE_PATH}/*.h")
if (NOT PB_H)
    message(FATAL_ERROR "Failed to find .h files in ${GENERATED_FILE_PATH}")
endif()

add_library(${PROJECT_NAME} ${PB_CC} ${PB_H})
target_include_directories(${PROJECT_NAME} PUBLIC ${GENERATED_FILE_PATH})

# We don't set public header property because it does not preserve header hierarchy.
install (
    TARGETS ${PROJECT_NAME} RUNTIME DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

# We expect top level directory to be IO:
install(
    DIRECTORY "${GENERATED_FILE_PATH}/com"
    DESTINATION "include"
    FILES_MATCHING
    PATTERN "*.h"
)
