set(library_name morphology_kernel)

create_library(${library_name} ${CMAKE_CURRENT_SOURCE_DIR} src)

# Set dependencies
set(oss_dependencies    deltares_common
                        deltares_common_c
                        deltares_common_mpi
                        morphology_data
                        morphology_plugins_c)
oss_include_libraries(${library_name} oss_dependencies)

if(UNIX)
    target_link_libraries(${library_name} ${oss_dependencies})
endif(UNIX)

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/../../include")

# Set additional compilation properties, specific for Debug mode
target_compile_options(${library_name} PRIVATE "$<$<CONFIG:Debug>:${check_pointers_flag}>")
target_compile_options(${library_name} PRIVATE "$<$<CONFIG:Debug>:${floating_point_exception_flag}>")

set_target_properties (${library_name} PROPERTIES FOLDER utils_gpl/morphology)
