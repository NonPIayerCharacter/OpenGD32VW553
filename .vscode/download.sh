#!/bin/bash
# Unified firmware download script for Linux
# Usage: ./download.sh [TARGET] [DEBUGGER]
# TARGET: MSDK, MBL, ALL
# DEBUGGER: GDLink, JLink

set -e

TARGET="${1:-MSDK}"
DEBUGGER="${2:-GDLink}"

# Get the script directory and workspace directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORK_DIR="$(dirname "$SCRIPT_DIR")"

# Validate target
if [[ ! "$TARGET" =~ ^(MSDK|MBL|ALL)$ ]]; then
    echo "Error: Invalid TARGET. Usage: ./download.sh [MSDK|MBL|ALL] [GDLink|JLink]"
    exit 1
fi

# Validate debugger
if [[ ! "$DEBUGGER" =~ ^(GDLink|JLink)$ ]]; then
    echo "Error: Invalid DEBUGGER. Usage: ./download.sh [MSDK|MBL|ALL] [GDLink|JLink]"
    exit 1
fi

# Set binary file and flash address based on target
case "${TARGET}" in
    MSDK)
        echo "Downloading MSDK via ${DEBUGGER}..."
        BIN_FILE="${WORK_DIR}/MSDK/projects/cmake/output/bin/msdk.bin"
        FLASH_ADDR="0x0800A000"
        ;;
    MBL)
        echo "Downloading MBL via ${DEBUGGER}..."
        BIN_FILE="${WORK_DIR}/MBL/project/cmake/bin/mbl.bin"
        FLASH_ADDR="0x08000000"
        ;;
    ALL)
        echo "Downloading ALL via ${DEBUGGER}..."
        BIN_FILE="${WORK_DIR}/scripts/images/image-all.bin"
        FLASH_ADDR="0x08000000"
        ;;
esac

# Set OpenOCD config based on debugger
if [ "$DEBUGGER" = "GDLink" ]; then
    CONFIG_FILE="${WORK_DIR}/MSDK/projects/eclipse/msdk/openocd_gdlink.cfg"
else
    CONFIG_FILE="${WORK_DIR}/MSDK/projects/eclipse/msdk/openocd_jlink.cfg"
fi

# Check if required files exist
if [ ! -f "$BIN_FILE" ]; then
    echo "Error: Binary file not found: $BIN_FILE"
    echo "Please make sure you have built the project first."
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: OpenOCD config file not found: $CONFIG_FILE"
    exit 1
fi

echo ""
echo "Target: $TARGET"
echo "Debugger: $DEBUGGER"
echo "Binary: $BIN_FILE"
echo "Flash Address: $FLASH_ADDR"
echo "Config: $CONFIG_FILE"
echo ""

# Run OpenOCD with appropriate config
if ${WORK_DIR}/tools/xpack-openocd-0.11.0-3_linux/bin/openocd -f "$CONFIG_FILE" \
    -c "init" \
    -c "program $BIN_FILE $FLASH_ADDR verify reset" \
    -c "exit"; then
    echo ""
    echo "Download completed successfully!"
else
    echo ""
    echo "Download failed!"
    exit 1
fi
