# X-Wing Revival VR: CMake build for
#   - Linux desktop client (OpenGL)              cmake -S . -B build && cmake --build build -j
#   - Linux dedicated server (headless, no GL)   cmake -S . -B build-server -DXWR_SERVER_ONLY=ON
#   - Android / Meta Quest (libmain.so)          built by quest/app/build.gradle
# The original Makefile / Visual Studio / Xcode projects are untouched.

cmake_minimum_required(VERSION 3.16)
project(XWingRevival LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
if(NOT CMAKE_BUILD_TYPE)
	set(CMAKE_BUILD_TYPE RelWithDebInfo)
endif()

option(XWR_SERVER_ONLY "Build only the headless dedicated server" OFF)

# Some vendored deps (freetype, gl4es) declare ancient cmake_minimum_required versions.
set(CMAKE_POLICY_VERSION_MINIMUM 3.5)

set(ENGINE ${CMAKE_CURRENT_SOURCE_DIR}/RaptorEngine)
set(EXT ${CMAKE_CURRENT_SOURCE_DIR}/external)

# ---------------------------------------------------------------------------
# Third-party SDL2 libraries (git submodules in external/)

set(SDL_TEST OFF CACHE BOOL "" FORCE)
set(SDL2_DISABLE_INSTALL ON CACHE BOOL "" FORCE)
set(SDL2_DISABLE_UNINSTALL ON CACHE BOOL "" FORCE)
if(ANDROID)
	# SDLActivity loads libSDL2.so + libmain.so.
	set(SDL_SHARED ON CACHE BOOL "" FORCE)
	set(SDL_STATIC OFF CACHE BOOL "" FORCE)
else()
	set(SDL_SHARED OFF CACHE BOOL "" FORCE)
	set(SDL_STATIC ON CACHE BOOL "" FORCE)
endif()
if(XWR_SERVER_ONLY)
	# The dedicated server never opens a window or audio device.
	foreach(sub VIDEO RENDER AUDIO JOYSTICK HAPTIC SENSOR HIDAPI POWER)
		set(SDL_${sub} OFF CACHE BOOL "" FORCE)
	endforeach()
endif()
add_subdirectory(${EXT}/SDL EXCLUDE_FROM_ALL)
if(ANDROID)
	add_library(XWR::SDL2 ALIAS SDL2)
	# The satellite libraries are built static and look for SDL2::SDL2-static; point them at the shared lib.
	add_library(SDL2::SDL2-static ALIAS SDL2)
else()
	add_library(XWR::SDL2 ALIAS SDL2-static)
endif()

set(BUILD_SHARED_LIBS OFF)
set(SDL2NET_INSTALL OFF CACHE BOOL "" FORCE)
set(SDL2NET_SAMPLES OFF CACHE BOOL "" FORCE)
add_subdirectory(${EXT}/SDL_net EXCLUDE_FROM_ALL)

if(NOT XWR_SERVER_ONLY)
	set(SDL2MIXER_INSTALL OFF CACHE BOOL "" FORCE)
	set(SDL2MIXER_SAMPLES OFF CACHE BOOL "" FORCE)
	set(SDL2MIXER_DEPS_SHARED OFF CACHE BOOL "" FORCE)
	set(SDL2MIXER_VENDORED OFF CACHE BOOL "" FORCE)
	foreach(fmt CMD FLAC GME MOD MIDI OPUS VORBIS WAVPACK)
		set(SDL2MIXER_${fmt} OFF CACHE BOOL "" FORCE)
	endforeach()
	set(SDL2MIXER_MP3 ON CACHE BOOL "" FORCE)          # Music/*.dat are obfuscated MP3s
	set(SDL2MIXER_MP3_MINIMP3 ON CACHE BOOL "" FORCE)
	set(SDL2MIXER_MP3_MPG123 OFF CACHE BOOL "" FORCE)
	set(SDL2MIXER_WAVE ON CACHE BOOL "" FORCE)
	add_subdirectory(${EXT}/SDL_mixer EXCLUDE_FROM_ALL)

	set(SDL2IMAGE_INSTALL OFF CACHE BOOL "" FORCE)
	set(SDL2IMAGE_SAMPLES OFF CACHE BOOL "" FORCE)
	set(SDL2IMAGE_DEPS_SHARED OFF CACHE BOOL "" FORCE)
	set(SDL2IMAGE_VENDORED OFF CACHE BOOL "" FORCE)
	set(SDL2IMAGE_BACKEND_STB ON CACHE BOOL "" FORCE)
	foreach(fmt AVIF JXL SVG TIF WEBP XCF XPM XV LBM PCX PNM QOI GIF)
		set(SDL2IMAGE_${fmt} OFF CACHE BOOL "" FORCE)
	endforeach()
	add_subdirectory(${EXT}/SDL_image EXCLUDE_FROM_ALL)

	set(SDL2TTF_INSTALL OFF CACHE BOOL "" FORCE)
	set(SDL2TTF_SAMPLES OFF CACHE BOOL "" FORCE)
	set(SDL2TTF_VENDORED ON CACHE BOOL "" FORCE)
	set(SDL2TTF_HARFBUZZ OFF CACHE BOOL "" FORCE)
	add_subdirectory(${EXT}/SDL_ttf EXCLUDE_FROM_ALL)
endif()

# The game includes <SDL2/SDL_xxx.h>. SDL itself copies its headers to <build>/include/SDL2;
# forward the satellite libraries' headers from a shim dir with the same layout.
set(SDLINC ${CMAKE_BINARY_DIR}/sdl2inc)
file(MAKE_DIRECTORY ${SDLINC}/SDL2)
foreach(h ${EXT}/SDL_net/include/SDL_net.h ${EXT}/SDL_mixer/include/SDL_mixer.h
		${EXT}/SDL_image/include/SDL_image.h ${EXT}/SDL_ttf/SDL_ttf.h)
	get_filename_component(n ${h} NAME)
	file(WRITE ${SDLINC}/SDL2/${n}.tmp "#include \"${h}\"\n")
	configure_file(${SDLINC}/SDL2/${n}.tmp ${SDLINC}/SDL2/${n} COPYONLY)
endforeach()

# ---------------------------------------------------------------------------
# Game + engine sources

file(GLOB GAME_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/Sources/*.cpp ${CMAKE_CURRENT_SOURCE_DIR}/Sources/*/*.cpp)
file(GLOB ENGINE_SOURCES ${ENGINE}/*/*.cpp)
list(FILTER ENGINE_SOURCES EXCLUDE REGEX "/Saitek/")
set(ENGINE_INCLUDES "")
file(GLOB _engine_dirs LIST_DIRECTORIES true ${ENGINE}/*)
foreach(d ${_engine_dirs})
	if(IS_DIRECTORY ${d} AND NOT d MATCHES "/\\.git")
		list(APPEND ENGINE_INCLUDES ${d})
	endif()
endforeach()

set(XWR_DEFS SDL2 NO_VR)
set(XWR_WARN -Wall -Wno-multichar -Wno-unused-parameter -Wno-overloaded-virtual -Wno-unused-variable
	-Wno-unused-but-set-variable -Wno-sign-compare -Wno-misleading-indentation -Wno-format-truncation)

if(ANDROID)
	add_library(main SHARED ${GAME_SOURCES} ${ENGINE_SOURCES})
	set(XWR_TARGET main)
else()
	if(XWR_SERVER_ONLY)
		set(XWR_TARGET xwingrev-server)
	else()
		set(XWR_TARGET xwingrev)
	endif()
	if(XWR_SERVER_ONLY)
		add_executable(${XWR_TARGET})
	else()
		add_executable(${XWR_TARGET} ${GAME_SOURCES} ${ENGINE_SOURCES})
	endif()
endif()

target_include_directories(${XWR_TARGET} PRIVATE
	${SDLINC}
	${CMAKE_CURRENT_SOURCE_DIR}/Sources
	${CMAKE_CURRENT_SOURCE_DIR}/Sources/Game
	${CMAKE_CURRENT_SOURCE_DIR}/Sources/UI
	${ENGINE_INCLUDES})
target_compile_definitions(${XWR_TARGET} PRIVATE ${XWR_DEFS})
target_compile_options(${XWR_TARGET} PRIVATE ${XWR_WARN} -fno-strict-aliasing -fsigned-char)
target_link_libraries(${XWR_TARGET} PRIVATE XWR::SDL2 SDL2_net::SDL2_net-static)

if(XWR_SERVER_ONLY)
	# Headless dedicated server: compile the whole game, but resolve the graphics/audio/font/image
	# symbols (never called with -dedicated) with generated no-op stubs instead of linking GL etc.
	target_compile_definitions(${XWR_TARGET} PRIVATE XWR_SERVER_ONLY)
	add_library(xwr_server_objs OBJECT ${GAME_SOURCES} ${ENGINE_SOURCES})
	get_target_property(_inc ${XWR_TARGET} INCLUDE_DIRECTORIES)
	target_include_directories(xwr_server_objs PRIVATE ${_inc})
	target_link_libraries(xwr_server_objs PRIVATE XWR::SDL2 SDL2_net::SDL2_net-static)
	target_compile_definitions(xwr_server_objs PRIVATE ${XWR_DEFS} XWR_SERVER_ONLY)
	target_compile_options(xwr_server_objs PRIVATE ${XWR_WARN} -fno-strict-aliasing -fsigned-char)
	add_custom_command(OUTPUT ${CMAKE_BINARY_DIR}/server_stubs.c
		COMMAND python3 ${CMAKE_CURRENT_SOURCE_DIR}/tools/gen_server_stubs.py ${CMAKE_BINARY_DIR}/server_stubs.c $<TARGET_OBJECTS:xwr_server_objs>
		DEPENDS $<TARGET_OBJECTS:xwr_server_objs> ${CMAKE_CURRENT_SOURCE_DIR}/tools/gen_server_stubs.py
		COMMAND_EXPAND_LISTS VERBATIM)
	target_sources(${XWR_TARGET} PRIVATE $<TARGET_OBJECTS:xwr_server_objs> ${CMAKE_BINARY_DIR}/server_stubs.c)
	target_link_options(${XWR_TARGET} PRIVATE -static-libstdc++ -static-libgcc)
else()
	target_link_libraries(${XWR_TARGET} PRIVATE SDL2_mixer::SDL2_mixer-static SDL2_image::SDL2_image-static SDL2_ttf::SDL2_ttf-static)
	if(ANDROID)
		# gl4es translates the engine's desktop OpenGL (immediate mode, GLSL 1.10) to OpenGL ES.
		set(NOX11 ON CACHE BOOL "" FORCE)
		set(NOEGL ON CACHE BOOL "" FORCE)
		set(STATICLIB ON CACHE BOOL "" FORCE)
		set(NO_LOADER ON CACHE BOOL "" FORCE)
		set(NO_INIT_CONSTRUCTOR ON CACHE BOOL "" FORCE)
		set(USE_ANDROID_LOG ON CACHE BOOL "" FORCE)
		set(DEFAULT_ES 2 CACHE STRING "" FORCE)
		add_subdirectory(${EXT}/gl4es EXCLUDE_FROM_ALL)
		set_target_properties(GL PROPERTIES ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/gl4es)
		target_include_directories(${XWR_TARGET} PRIVATE ${EXT}/gl4es/include)
		target_link_libraries(${XWR_TARGET} PRIVATE GL GLESv3 EGL)
	else()
		find_package(OpenGL REQUIRED)
		find_package(GLEW REQUIRED)
		target_link_libraries(${XWR_TARGET} PRIVATE GLEW::GLEW OpenGL::GL OpenGL::GLU)
	endif()
endif()

if(ANDROID)
	target_compile_definitions(${XWR_TARGET} PRIVATE XWR_QUEST)
	target_link_libraries(${XWR_TARGET} PRIVATE android log)
	if(XWR_OPENXR)
		find_package(OpenXR REQUIRED CONFIG)
		target_compile_definitions(${XWR_TARGET} PRIVATE XWR_OPENXR)
		target_link_libraries(${XWR_TARGET} PRIVATE OpenXR::openxr_loader)
	endif()
else()
	target_link_libraries(${XWR_TARGET} PRIVATE pthread dl m)
	set_target_properties(${XWR_TARGET} PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
endif()
