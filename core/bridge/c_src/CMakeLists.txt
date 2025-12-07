# Bridge层 CMake 构建配置
# 用于桌面端C/C++编译和Dart FFI绑定

cmake_minimum_required(VERSION 3.16)
project(mihomo_bridge)

# 设置C标准
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# 编译选项
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wextra -O2")
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -g -DDEBUG")
set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -O3 -DNDEBUG")

# 平台特定配置
if(ANDROID)
    # Android配置
    find_library(log-lib log)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DANDROID -D__ANDROID__")
    add_library(mihomo_bridge SHARED bridge.c)
    target_link_libraries(mihomo_bridge ${log-lib})
elseif(APPLE)
    # Apple配置 (macOS/iOS)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DAPPLE -D__APPLE__")
    add_library(mihomo_bridge STATIC bridge.c)
elseif(WIN32)
    # Windows配置
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DWIN32 -D_WIN32")
    add_library(mihomo_bridge STATIC bridge.c)
else()
    # Linux配置
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DLINUX -D__linux__")
    add_library(mihomo_bridge STATIC bridge.c)
endif()

# 设置输出目录
set_target_properties(mihomo_bridge PROPERTIES
    ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)

# 安装配置
install(TARGETS mihomo_bridge
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
)

# 头文件安装
install(FILES bridge.h DESTINATION include)
