set(library_name dhydrology_kernel)

create_library(${library_name} ${CMAKE_CURRENT_SOURCE_DIR} src)

# Specify dependencies
set(oss_dependencies    deltares_common)
oss_include_libraries(${library_name} oss_dependencies)

if(UNIX)
    target_link_libraries(${library_name} ${oss_dependencies})
endif()

# Set additional compilation properties, specific for Debug mode
target_compile_options(${library_name} PRIVATE "$<$<CONFIG:Debug>:${check_pointers_flag}>")
target_compile_options(${library_name} PRIVATE "$<$<CONFIG:Debug>:${floating_point_exception_flag}>")

set_target_properties (${library_name} PROPERTIES FOLDER utils_gpl/dhydrology)
