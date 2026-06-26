#!/bin/bash

# --- Color Definitions ---
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Starting Multi-Emulator Test Suite ===${NC}"

# 1. Run standard unit/bloc tests (VM)
echo -e "\n${BLUE}--- Running Unit & BLoC Tests (VM) ---${NC}"
UNIT_RESULT=0
for dir in test/*/ ; do
    # Skip integration (which we moved back) and utils
    if [[ "$dir" != "test/integration/" && "$dir" != "test/utils/" ]]; then
        echo -e "Testing directory: $dir"
        flutter test "$dir"
        if [ $? -ne 0 ]; then
            UNIT_RESULT=1
        fi
    fi
done

# 2. Find all running emulators/simulators
# Improved parsing: Extract IDs of devices that are NOT 'macos', 'linux', or 'windows'
EMULATORS=$(flutter devices --machine | tr ',' '\n' | grep '"id":' | grep -vE 'macos|linux|windows' | cut -d '"' -f 4)

if [ -z "$EMULATORS" ]; then
    echo -e "${RED}No emulators detected. Skipping integration tests.${NC}"
    INTEGRATION_SUMMARY="No emulators found"
else
    echo -e "${BLUE}Detected Devices:${NC}\n$EMULATORS"

    INTEGRATION_SUMMARY=""
    for ID in $EMULATORS; do
        echo -e "\n${BLUE}--- Running Integration Tests on: $ID ---${NC}"
        # Correct path to the integration test
        flutter test integration_test/app_test.dart -d "$ID"

        if [ $? -eq 0 ]; then
            INTEGRATION_SUMMARY+="$ID: ${GREEN}PASSED${NC}\n"
        else
            INTEGRATION_SUMMARY+="$ID: ${RED}FAILED${NC}\n"
            ANY_INTEGRATION_FAILED=true
        fi
    done
fi

# --- Final Summary ---
echo -e "\n${BLUE}=== Test Summary ===${NC}"
if [ $UNIT_RESULT -eq 0 ]; then
    echo -e "Unit/BLoC Tests: ${GREEN}PASSED${NC}"
else
    echo -e "Unit/BLoC Tests: ${RED}FAILED${NC}"
fi

echo -e "Integration Tests:\n$INTEGRATION_SUMMARY"

if [ $UNIT_RESULT -ne 0 ] || [ "$ANY_INTEGRATION_FAILED" = true ]; then
    exit 1
fi

exit 0
