# Set version file variables
# Note that the CMAKE_CURRENT_SOURCE_DIR has a path to THIS CMakeLists location

# Set the DFlow FM component path
set(dflowfm_path "${CMAKE_CURRENT_SOURCE_DIR}/../../")

# Include directories that are required as references
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)

# Set the directory of where the source code is located
set(src_path src)


# Add iso_c_fortran sub directory to BMI
# This method is excluded currently becuase 
# (1) we do not currently use the iso_c fortran bmi functions
# and (2) PATCH ELF error occurs when we try to compiled and link
# it's shared libraries amongst the current DFlowFM build. Will 
# resolve this issue later on. 
#add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/iso_c_fortran_bmi ${CMAKE_BINARY_DIR}/iso_c_bmi)

# Set version file variables

set_source_files_properties(${fortran_version_files}
                            PROPERTIES COMPILE_OPTIONS "${file_preprocessor_flag}")

get_fortran_source_files(${src_path} dflowfm_bmi2_files)

# Define library
set(library_name dflowfm_bmi2)
set(library_source_list     ${dflowfm_bmi2_files})

add_library(${library_name} ${library_source_list})

# Add dependencies
if (UNIX)
    # the `pkg_check_modules` function is created with this call
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(PETSC REQUIRED IMPORTED_TARGET PETSc)
endif(UNIX)

    set(oss_dependencies    deltares_common
                            deltares_common_c
                            deltares_common_mpi
                            dhydrology_kernel
                            ec_module
                            flow1d
                            flow1d_core
                            flow1d_io
                            gridgeom
                            io_netcdf
                            io_netcdf_data
                            interacter_stub
                            kdtree_wrapper
                            kdtree2
                            fortrangis
                            libsigwatch
                            md5digest
                            md5
                            metis
                            metisoptions
                            morphology_data
                            morphology_io
                            morphology_kernel
                            morphology_plugins_c
                            nefis
                            netcdf4
                            netcdff
                            polypack
                            trachytopes_io
                            trachytopes_kernel
                            triangle_c
                            wq_processes
                            waq_process
                            waq_hyd_data
                            waq_utils_c
                            waq_utils_f
                            dflowfm_kernel)

    oss_include_libraries(${library_name} oss_dependencies)

if (UNIX)
    target_link_libraries(${library_name} ${oss_dependencies} PkgConfig::PETSC)

    message(STATUS "Setting target_compile_definitions in Unix")
    target_compile_definitions(${library_name} PRIVATE "HAVE_DISPLAY=0;HAVE_METIS;HAVE_POLYPACK;HAVE_MPI;HAVE_PETSC")
endif(UNIX)

if (WIN32)

    target_link_libraries(${library_name} ${oss_dependencies})

    set_target_properties(${library_name} PROPERTIES LINK_FLAGS ${openmp_flag})

    message(STATUS "Setting target_compile_definitions in windows")
    target_compile_definitions(${library_name} PRIVATE "WIN32;HAVE_DISPLAY=0;HAVE_METIS;HAVE_POLYPACK;HAVE_MPI;HAVE_PETSC;HAVE_OPENGL")
endif(WIN32)

include_directories(${mpi_include_path})

# Define additional compilation flags

set_source_files_properties(${CMAKE_CURRENT_SOURCE_DIR}/${src_path}/bmidflowfm.f90
                            PROPERTIES COMPILE_OPTIONS "${file_preprocessor_flag}")

# Set additional compilation properties, specific for Debug mode
target_compile_options(${library_name} PRIVATE "$<$<CONFIG:Debug>:${check_pointers_flag}>")
target_compile_options(${library_name} PRIVATE "$<$<CONFIG:Debug>:${floating_point_exception_flag}>")

# Define preprocessor definitions
if (WIN32)
    set_target_properties(${library_name} PROPERTIES COMPILE_FLAGS ${openmp_flag})
    if(WITH_INTERACTER)
        # Add HAVE_DISPLAY=1
        target_compile_definitions(${library_name} PRIVATE "WIN32;HAVE_TECPLOT;HAVE_METIS;HAVE_POLYPACK;HAVE_MPI;HAVE_PETSC;HAVE_OPENGL;HAVE_DISPLAY=1")
    else()
        target_compile_definitions(${library_name} PRIVATE "WIN32;HAVE_TECPLOT;HAVE_METIS;HAVE_POLYPACK;HAVE_MPI;HAVE_PETSC;HAVE_OPENGL;HAVE_DISPLAY=0")
    endif()
endif(WIN32)

if (UNIX)
    target_link_libraries(${library_name} ${oss_dependencies})
    target_compile_definitions(${library_name} PRIVATE "HAVE_METIS;HAVE_POLYPACK;HAVE_MPI;HAVE_PETSC")
endif(UNIX)

# Create the folder structure in vfproj
source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR} FILES ${library_source_list})
set_target_properties (${library_name} PROPERTIES FOLDER engines_gpl/dflowfm)


# Define shared library
set(library_name_shared dflowfm_bmi2_shared)
set(library_source_list SHARED ${dflowfm_bmi2_files})

add_library(${library_name_shared} ${library_source_list})

# Add dependencies
if (UNIX)
    # the `pkg_check_modules` function is created with this call
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(PETSC REQUIRED IMPORTED_TARGET PETSc)
endif(UNIX)

    set(oss_dependencies    deltares_common
                            deltares_common_c
                            deltares_common_mpi
                            dhydrology_kernel
                            ec_module
                            flow1d
                            flow1d_core
                            flow1d_io
                            gridgeom
                            io_netcdf
                            io_netcdf_data
                            interacter_stub
                            kdtree_wrapper
                            kdtree2
                            fortrangis
                            libsigwatch
                            md5digest
                            md5
                            metis
                            metisoptions
                            morphology_data
                            morphology_io
                            morphology_kernel
                            morphology_plugins_c
                            nefis
                            netcdf4
                            netcdff
                            polypack
                            trachytopes_io
                            trachytopes_kernel
                            triangle_c
                            wq_processes
                            waq_process
                            waq_hyd_data
                            waq_utils_c
                            waq_utils_f
                            dflowfm_kernel)

    oss_include_libraries(${library_name_shared} oss_dependencies)


if (UNIX)
    target_link_libraries(${library_name_shared} ${oss_dependencies} PkgConfig::PETSC)

    message(STATUS "Setting target_compile_definitions in Unix")
    target_compile_definitions(${library_name_shared} PRIVATE "HAVE_DISPLAY=0;HAVE_METIS;HAVE_POLYPACK;HAVE_MPI;HAVE_PETSC")
endif(UNIX)

if (WIN32)

    target_link_libraries(${library_name_shared} ${oss_dependencies})

    set_target_properties(${library_name_shared} PROPERTIES LINK_FLAGS ${openmp_flag})

    message(STATUS "Setting target_compile_definitions in windows")
    target_compile_definitions(${library_name_shared} PRIVATE "WIN32;HAVE_DISPLAY=0;HAVE_METIS;HAVE_POLYPACK;HAVE_MPI;HAVE_PETSC;HAVE_OPENGL")
endif(WIN32)

include_directories(${mpi_include_path})

# Define additional compilation flags

set_source_files_properties(${CMAKE_CURRENT_SOURCE_DIR}/${src_path}/bmidflowfm.f90
                            PROPERTIES COMPILE_OPTIONS "${file_preprocessor_flag}")

# Set additional compilation properties, specific for Debug mode
target_compile_options(${library_name_shared} PRIVATE "$<$<CONFIG:Debug>:${check_pointers_flag}>")
target_compile_options(${library_name_shared} PRIVATE "$<$<CONFIG:Debug>:${floating_point_exception_flag}>")

# Define preprocessor definitions
if (WIN32)
    set_target_properties(${library_name_shared} PROPERTIES COMPILE_FLAGS ${openmp_flag})
    if(WITH_INTERACTER)
        # Add HAVE_DISPLAY=1
        target_compile_definitions(${library_name_shared} PRIVATE "WIN32;HAVE_TECPLOT;HAVE_METIS;HAVE_POLYPACK;HAVE_MPI;HAVE_PETSC;HAVE_OPENGL;HAVE_DISPLAY=1")
    else()
        target_compile_definitions(${library_name_shared} PRIVATE "WIN32;HAVE_TECPLOT;HAVE_METIS;HAVE_POLYPACK;HAVE_MPI;HAVE_PETSC;HAVE_OPENGL;HAVE_DISPLAY=0")
    endif()
endif(WIN32)

if (UNIX)
    target_link_libraries(${library_name_shared} ${oss_dependencies})
    target_compile_definitions(${library_name_shared} PRIVATE "HAVE_METIS;HAVE_POLYPACK;HAVE_MPI;HAVE_PETSC")
endif(UNIX)

# Create the folder structure in vfproj
source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR} FILES ${library_source_list})
set_target_properties (${library_name_shared} PROPERTIES FOLDER engines_gpl/dflowfm)

