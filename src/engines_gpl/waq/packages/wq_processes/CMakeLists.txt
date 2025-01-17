# Set directory which contains all source files
set(src_path src)

# Set version file variables
set(svn_version_root ${CMAKE_CURRENT_SOURCE_DIR}/../) # Check the SVN revision of WAQ directory
set(waq_root_path ${CMAKE_CURRENT_SOURCE_DIR}/../../) # Trace back to the WAQ path

# Set version file variables
set(waq_version_path ${waq_root_path}/version)
set(rc_version_file ${CMAKE_CURRENT_SOURCE_DIR}/../../version/version_number.rc)
set(version_include_dir ${CMAKE_SOURCE_DIR}/../version_includes)

# Set dependencies
set(oss_dependencies_general deltares_common
                             waq_process
                             waq_utils_c
                             waq_hyd_data)
# Gather source files
get_fortran_source_files(${src_path} source)

# Define library
set(library_name wq_processes)
add_library(${library_name} ${source}
                            ${rc_version_file})

# Set dependencies
set(oss_dependencies deltares_common
                     deltares_common_c
                     waq_process
                     waq_utils_f)

# Link libraries
target_link_libraries(${library_name} ${oss_dependencies})

# Set dependencies
set(oss_dependencies deltares_common
                     deltares_common_c
                     waq_process
                     waq_hyd_data
                     waq_utils_c
                     waq_utils_f)

set(oss_dependencies ${oss_dependencies})

# Set additional compilation properties
target_compile_options(${library_name} PRIVATE "${waq_default_flags}")
target_include_directories(${library_name}  PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/../../include ${version_include_dir})

# Define how the files should be structured in Visual studio
source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR} FILES  ${source})
set_target_properties (${library_name} PROPERTIES FOLDER engines_gpl/waq)
