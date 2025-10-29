#[=======================================================================[.rst:
----

Finds the OpenImageIO library.

Imported Targets
^^^^^^^^^^^^^^^^

This module provides the following imported targets, if found:

``OpenImageIO::OpenImageIO``
  The OpenImageIO library

Result Variables
^^^^^^^^^^^^^^^^

This will define the following variables:

``OpenImageIO_FOUND``
  True if the system has the OpenImageIO library.
``OpenImageIO_INCLUDE_DIR``
  Include directories for OpenImageIO.
``OpenImageIO_LIBRARY``
  OpenImageIO library path.

#]=======================================================================]
if (TARGET OpenImageIO::OpenImageIO AND TARGET OpenImageIO::OpenImageIO_Util)
    return()
endif()


# Determine search paths
if(OpenImageIO_ROOT)
    set(_oiio_SEARCH_DIRS ${OpenImageIO_ROOT})
elseif(pxr_ROOT)
    set(_oiio_SEARCH_DIRS ${pxr_ROOT})
elseif(CMAKE_PREFIX_PATH)
    set(_oiio_SEARCH_DIRS ${CMAKE_PREFIX_PATH})
else()
    set(_oiio_SEARCH_DIRS "")
endif()

# Find include directory
find_path(OpenImageIO_INCLUDE_DIR
    NAMES OpenImageIO/imageio.h
    PATHS ${_oiio_SEARCH_DIRS}
    PATH_SUFFIXES include
    NO_DEFAULT_PATH
)

# Find library directory
find_library(OpenImageIO_LIBRARY
    NAMES OpenImageIO libOpenImageIO.a
    PATHS ${_oiio_SEARCH_DIRS}
    PATH_SUFFIXES lib
    NO_DEFAULT_PATH
)

# Find utility library
find_library(OpenImageIO_Util_LIBRARY
    NAMES OpenImageIO_Util libOpenImageIO_Util.a
    PATHS ${_oiio_SEARCH_DIRS}
    PATH_SUFFIXES lib
    NO_DEFAULT_PATH
)

# Find TIFF library (required by OpenImageIO)
find_library(TIFF_LIBRARY
    NAMES tiff libtiff.a
    PATHS ${_oiio_SEARCH_DIRS}
    PATH_SUFFIXES lib
    NO_DEFAULT_PATH
)

# Find JPEG library (required by OpenImageIO and TIFF)
find_library(JPEG_LIBRARY
    NAMES jpeg libjpeg.a
    PATHS ${_oiio_SEARCH_DIRS}
    PATH_SUFFIXES lib
    NO_DEFAULT_PATH
)

# Find PNG library (required by OpenImageIO)
find_library(PNG_LIBRARY
    NAMES png png16 libpng.a libpng16.a
    PATHS ${_oiio_SEARCH_DIRS}
    PATH_SUFFIXES lib
    NO_DEFAULT_PATH
)

# Find TBB library (required by OpenImageIO and USD)
find_library(TBB_LIBRARY
    NAMES tbb libtbb.a
    PATHS ${_oiio_SEARCH_DIRS}
    PATH_SUFFIXES lib
    NO_DEFAULT_PATH
)

# Find Boost libraries (required by OpenImageIO)
find_library(BOOST_FILESYSTEM_LIBRARY
    NAMES boost_filesystem libboost_filesystem.a
    PATHS ${_oiio_SEARCH_DIRS}
    PATH_SUFFIXES lib
    NO_DEFAULT_PATH
)

find_library(BOOST_THREAD_LIBRARY
    NAMES boost_thread libboost_thread.a
    PATHS ${_oiio_SEARCH_DIRS}
    PATH_SUFFIXES lib
    NO_DEFAULT_PATH
)

find_library(BOOST_SYSTEM_LIBRARY
    NAMES boost_system libboost_system.a
    PATHS ${_oiio_SEARCH_DIRS}
    PATH_SUFFIXES lib
    NO_DEFAULT_PATH
)

# Find OpenEXR libraries (required by OpenImageIO)
find_library(IEX_LIBRARY
    NAMES Iex-3_1 libIex-3_1.a
    PATHS ${_oiio_SEARCH_DIRS}
    PATH_SUFFIXES lib
    NO_DEFAULT_PATH
)

find_library(IMATH_LIBRARY
    NAMES Imath-3_1 libImath-3_1.a
    PATHS ${_oiio_SEARCH_DIRS}
    PATH_SUFFIXES lib
    NO_DEFAULT_PATH
)

find_library(OPENEXR_LIBRARY
    NAMES OpenEXR-3_1 libOpenEXR-3_1.a
    PATHS ${_oiio_SEARCH_DIRS}
    PATH_SUFFIXES lib
    NO_DEFAULT_PATH
)

find_library(OPENEXRCORE_LIBRARY
    NAMES OpenEXRCore-3_1 libOpenEXRCore-3_1.a
    PATHS ${_oiio_SEARCH_DIRS}
    PATH_SUFFIXES lib
    NO_DEFAULT_PATH
)

find_library(ILMTHREAD_LIBRARY
    NAMES IlmThread-3_1 libIlmThread-3_1.a
    PATHS ${_oiio_SEARCH_DIRS}
    PATH_SUFFIXES lib
    NO_DEFAULT_PATH
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(OpenImageIO
    REQUIRED_VARS OpenImageIO_LIBRARY OpenImageIO_INCLUDE_DIR
)

if(OpenImageIO_FOUND)
    # Create imported target
    if(NOT TARGET OpenImageIO::OpenImageIO)
        add_library(OpenImageIO::OpenImageIO STATIC IMPORTED)
        set_target_properties(OpenImageIO::OpenImageIO PROPERTIES
            IMPORTED_LOCATION "${OpenImageIO_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${OpenImageIO_INCLUDE_DIR}"
        )

        # Build list of dependencies in correct order for static linking
        # Dependencies that are needed by libraries above must come later
        set(_oiio_deps "")

        # OpenImageIO_Util comes first as it's directly used by OpenImageIO
        if(OpenImageIO_Util_LIBRARY)
            list(APPEND _oiio_deps "${OpenImageIO_Util_LIBRARY}")
        endif()

        # Image format libraries in order of dependencies (JPEG/PNG before TIFF)
        if(JPEG_LIBRARY)
            list(APPEND _oiio_deps "${JPEG_LIBRARY}")
        endif()

        if(PNG_LIBRARY)
            list(APPEND _oiio_deps "${PNG_LIBRARY}")
        endif()

        # TIFF depends on JPEG, so it comes after
        if(TIFF_LIBRARY)
            list(APPEND _oiio_deps "${TIFF_LIBRARY}")
        endif()

        # TBB for threading
        if(TBB_LIBRARY)
            list(APPEND _oiio_deps "${TBB_LIBRARY}")
        endif()

        # Boost libraries
        if(BOOST_FILESYSTEM_LIBRARY)
            list(APPEND _oiio_deps "${BOOST_FILESYSTEM_LIBRARY}")
        endif()

        if(BOOST_THREAD_LIBRARY)
            list(APPEND _oiio_deps "${BOOST_THREAD_LIBRARY}")
        endif()

        if(BOOST_SYSTEM_LIBRARY)
            list(APPEND _oiio_deps "${BOOST_SYSTEM_LIBRARY}")
        endif()

        # OpenEXR libraries
        if(IEX_LIBRARY)
            list(APPEND _oiio_deps "${IEX_LIBRARY}")
        endif()

        if(IMATH_LIBRARY)
            list(APPEND _oiio_deps "${IMATH_LIBRARY}")
        endif()

        if(OPENEXR_LIBRARY)
            list(APPEND _oiio_deps "${OPENEXR_LIBRARY}")
        endif()

        if(OPENEXRCORE_LIBRARY)
            list(APPEND _oiio_deps "${OPENEXRCORE_LIBRARY}")
        endif()

        if(ILMTHREAD_LIBRARY)
            list(APPEND _oiio_deps "${ILMTHREAD_LIBRARY}")
        endif()

        # Set all dependencies at once in the correct order
        if(_oiio_deps)
            set_target_properties(OpenImageIO::OpenImageIO PROPERTIES
                INTERFACE_LINK_LIBRARIES "${_oiio_deps}"
            )
        endif()
    endif()

    # Create separate imported target for OpenImageIO_Util
    if(NOT TARGET OpenImageIO::OpenImageIO_Util AND OpenImageIO_Util_LIBRARY)
        add_library(OpenImageIO::OpenImageIO_Util STATIC IMPORTED)
        set_target_properties(OpenImageIO::OpenImageIO_Util PROPERTIES
            IMPORTED_LOCATION "${OpenImageIO_Util_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${OpenImageIO_INCLUDE_DIR}"
        )
    endif()

    mark_as_advanced(OpenImageIO_INCLUDE_DIR OpenImageIO_LIBRARY OpenImageIO_Util_LIBRARY)
endif()
