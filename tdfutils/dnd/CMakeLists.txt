cmake_minimum_required(VERSION 3.16)

project(dnd LANGUAGES CXX)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Core)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS DBus)


add_executable(dnd
  main.cpp
)
target_link_libraries(dnd Qt${QT_VERSION_MAJOR}::Core)
target_link_libraries(dnd Qt${QT_VERSION_MAJOR}::DBus)

include(GNUInstallDirs)
install(TARGETS dnd
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
