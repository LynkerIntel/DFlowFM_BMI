set(library_name kdtree_wrapper)
create_library(${library_name} ${CMAKE_CURRENT_SOURCE_DIR} src)

set (oss_dependencies deltares_common kdtree2)
oss_include_libraries(${library_name} oss_dependencies)

if (UNIX)
    target_link_libraries(${library_name} ${oss_dependencies})
endif(UNIX)

# Set additional compilation properties, specific for Debug mode
target_compile_options(${library_name} PRIVATE "$<$<CONFIG:Debug>:${check_pointers_flag}>")
target_compile_options(${library_name} PRIVATE "$<$<CONFIG:Debug>:${floating_point_exception_flag}>")

set_target_properties (${library_name} PROPERTIES FOLDER utils_lgpl/kdtree_wrapper)
