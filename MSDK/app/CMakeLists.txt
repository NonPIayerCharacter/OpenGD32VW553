
cmake_minimum_required(VERSION 3.15)

target_include_directories(${TARGET_EXE}
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/mqtt_app
        ${CMAKE_CURRENT_SOURCE_DIR}/atcmd_ota_demo
)
target_sources(${TARGET_EXE}
    PRIVATE
        atcmd.c
        ../ble/app/ble_init.c
        cmd_shell.c
        iperf.c
        main.c
        mqtt_app/mqtt_cmd.c
        ota_demo.c
        ping.c
    )


