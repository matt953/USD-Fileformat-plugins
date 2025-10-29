#[=======================================================================[.rst:
----

Finds or fetches the TinyGLTF library.
If USD_FILEFORMATS_FORCE_FETCHCONTENT or USD_FILEFORMATS_FETCH_TINYGLTF are
TRUE, TinyGLTF will be fetched. Otherwise it will be searched manually since
TinyGLTF is a header-only library.

Imported Targets
^^^^^^^^^^^^^^^^

This module provides the following imported targets:

``tinygltf::tinygltf``
  The TinyGLTF library

Result Variables
^^^^^^^^^^^^^^^^

This will define the following variables:

``TinyGLTF_FOUND``
  True if TinyGLTF was found
``TinyGLTF_INCLUDE_DIR``
  TinyGLTF include directory


#]=======================================================================]

if(TARGET tinygltf::tinygltf)
    return()
endif()

if(USD_FILEFORMATS_FORCE_FETCHCONTENT OR USD_FILEFORMATS_FETCH_TINYGLTF)
    message(STATUS "Fetching TinyGLTF")
    include(FetchContent)
    FetchContent_Declare(
        TinyGLTF
        GIT_REPOSITORY "https://github.com/syoyo/tinygltf.git"
        GIT_TAG        "v2.8.21" # 4bfc1fc1807e2e2cf3d3111f67d6ebd957514c80
        OVERRIDE_FIND_PACKAGE
    )
    set(TINYGLTF_BUILD_LOADER_EXAMPLE OFF)
    set(TINYGLTF_INSTALL OFF)
    set(TINYGLTF_HEADER_ONLY ON)
    FetchContent_MakeAvailable(TinyGLTF)
    if(tinygltf_POPULATED)
        set(TinyGLTF_FOUND TRUE)
        add_library(tinygltf::tinygltf ALIAS tinygltf)
    elseif(${TinyGLTF_FIND_REQUIRED})
        message(FATAL_ERROR "Could not fetch TinyGLTF")
    endif()
else()
    # Manual search for TinyGLTF (header-only library)

    # Determine search paths
    if(TinyGLTF_ROOT)
        set(_tinygltf_SEARCH_DIRS ${TinyGLTF_ROOT})
    elseif(CMAKE_PREFIX_PATH)
        set(_tinygltf_SEARCH_DIRS ${CMAKE_PREFIX_PATH})
    else()
        set(_tinygltf_SEARCH_DIRS "")
    endif()

    # Find the main header file
    find_path(TinyGLTF_INCLUDE_DIR
        NAMES tiny_gltf.h
        PATHS ${_tinygltf_SEARCH_DIRS}
        PATH_SUFFIXES "" include
        NO_DEFAULT_PATH
    )

    include(FindPackageHandleStandardArgs)
    find_package_handle_standard_args(TinyGLTF
        REQUIRED_VARS TinyGLTF_INCLUDE_DIR
    )

    if(TinyGLTF_FOUND)
        # Create interface imported target for header-only library
        if(NOT TARGET tinygltf::tinygltf)
            add_library(tinygltf::tinygltf INTERFACE IMPORTED)
            set_target_properties(tinygltf::tinygltf PROPERTIES
                INTERFACE_INCLUDE_DIRECTORIES "${TinyGLTF_INCLUDE_DIR}"
            )
        endif()

        mark_as_advanced(TinyGLTF_INCLUDE_DIR)
    endif()
endif()
