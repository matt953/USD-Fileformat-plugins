# FindPxr.cmake - Find USD (PixarOpenUSD) installation
#
# This module defines:
#  pxr_FOUND - System has USD
#  pxr_INCLUDE_DIRS - USD include directories
#  pxr_LIBRARY_DIR - USD library directory
#  pxr_LIBRARIES - USD libraries
#
# And creates imported targets for all USD libraries

if(pxr_ROOT)
    set(_pxr_SEARCH_DIRS ${pxr_ROOT})
else()
    set(_pxr_SEARCH_DIRS "")
endif()

# Find include directory
find_path(pxr_INCLUDE_DIR
    NAMES pxr/pxr.h
    PATHS ${_pxr_SEARCH_DIRS}
    PATH_SUFFIXES include
    NO_DEFAULT_PATH
)

# Find library directory by looking for the monolithic USD library
find_path(pxr_LIBRARY_DIR
    NAMES libusd_m.a usd_m.lib
    PATHS ${_pxr_SEARCH_DIRS}
    PATH_SUFFIXES lib
    NO_DEFAULT_PATH
)

# Find the monolithic USD library or individual libraries
set(_USD_MONOLITHIC_LIBS usd_m)
set(_USD_INDIVIDUAL_LIBS
    arch tf gf js trace work plug vt ar kind sdf ndr sdr pcp usd
    usdGeom usdVol usdLux usdMedia usdShade usdRender usdHydra usdRi
    usdSkel usdUI usdUtils usdPhysics usdMtlx usdProc garch hf hio
    cameraUtil pxOsd geomUtil glf
)

# Try monolithic library first
foreach(_lib ${_USD_MONOLITHIC_LIBS})
    set(_lib_name "usd_${_lib}")
    find_library(_${_lib}_LIBRARY
        NAMES ${_lib_name} lib${_lib_name}.a
        PATHS ${pxr_LIBRARY_DIR}
        NO_DEFAULT_PATH
    )

    if(_${_lib}_LIBRARY)
        # For monolithic build, create UNKNOWN IMPORTED targets pointing to the monolithic library
        foreach(_alias_lib ${_USD_INDIVIDUAL_LIBS})
            if(NOT TARGET ${_alias_lib})
                add_library(${_alias_lib} UNKNOWN IMPORTED)
                set_target_properties(${_alias_lib} PROPERTIES
                    IMPORTED_LOCATION "${_${_lib}_LIBRARY}"
                    INTERFACE_INCLUDE_DIRECTORIES "${pxr_INCLUDE_DIR}"
                )
            endif()
        endforeach()
        set(pxr_FOUND_MONOLITHIC TRUE)
        break()
    endif()
    unset(_${_lib}_LIBRARY CACHE)
endforeach()

# If monolithic wasn't found, try individual libraries
if(NOT pxr_FOUND_MONOLITHIC)
    foreach(_lib ${_USD_INDIVIDUAL_LIBS})
        set(_lib_name "usd_${_lib}")
        find_library(_${_lib}_LIBRARY
            NAMES ${_lib_name} lib${_lib_name}.a
            PATHS ${pxr_LIBRARY_DIR}
            NO_DEFAULT_PATH
        )

        if(_${_lib}_LIBRARY)
            if(NOT TARGET ${_lib})
                add_library(${_lib} STATIC IMPORTED)
                set_target_properties(${_lib} PROPERTIES
                    IMPORTED_LOCATION "${_${_lib}_LIBRARY}"
                    INTERFACE_INCLUDE_DIRECTORIES "${pxr_INCLUDE_DIR}"
                )
            endif()
            list(APPEND pxr_LIBRARIES ${_lib})
        endif()
        unset(_${_lib}_LIBRARY CACHE)
    endforeach()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(pxr
    REQUIRED_VARS pxr_INCLUDE_DIR pxr_LIBRARY_DIR
    VERSION_VAR pxr_VERSION
)

if(pxr_FOUND)
    set(pxr_INCLUDE_DIRS ${pxr_INCLUDE_DIR})
    mark_as_advanced(pxr_INCLUDE_DIR pxr_LIBRARY_DIR)
endif()
