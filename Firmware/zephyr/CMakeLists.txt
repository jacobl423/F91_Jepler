cmake_minimum_required(VERSION 3.20.0)

find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(f91_jepler_watch)

target_include_directories(app PRIVATE src src/services)

target_sources(app PRIVATE
    src/logic/watch_logic.c
    src/main.c
    src/services/notification_service.c
    src/services/clock_service.c
)
