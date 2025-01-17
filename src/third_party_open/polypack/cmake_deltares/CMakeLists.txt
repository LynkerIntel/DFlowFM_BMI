# Define library
set(library_name polypack)

# Set the directory of where the source code is located.
set(src_directory "${CMAKE_CURRENT_SOURCE_DIR}/../src")
create_library(${library_name} ${src_directory} ${src_directory})

# Set additional compilation properties
target_compile_options(${library_name} PRIVATE "${real_size_64_flag}")

# Set additional compilation properties, specific for Debug mode
target_compile_options(${library_name} PRIVATE "$<$<CONFIG:Debug>:${check_pointers_flag}>")
target_compile_options(${library_name} PRIVATE "$<$<CONFIG:Debug>:${floating_point_exception_flag}>")

set_target_properties (${library_name} PROPERTIES FOLDER third_party_open)