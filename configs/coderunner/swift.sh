#!/bin/bash
[ -z "$CR_SUGGESTED_OUTPUT_FILE" ] && CR_SUGGESTED_OUTPUT_FILE="$PWD/${CR_FILENAME%.*}"
if [ "$CR_FILENAME" = "main.swift" ]; then
    # Test filtering
    SOURCES=$(ls *.swift | grep -v "\.test\.swift$")
    xcrun -sdk macosx swiftc -strict-concurrency=minimal -o "$CR_SUGGESTED_OUTPUT_FILE" $SOURCES "${@:1}" ${CR_DEBUGGING:+-g}
else
    case "$CR_FILENAME" in
        *.test.swift)
            TEST_LIB_PATH="$HOME/dotfiles/libs/swift/MiniTests"
            BASE_NAME="${CR_FILENAME%.test.swift}"
            SRC_FILE="${BASE_NAME}.swift"

            # Se añade "$SRC_FILE" junto a "$CR_FILENAME" para compilar ambos
            xcrun -sdk macosx swiftc \
            -strict-concurrency=minimal \
            -I "$TEST_LIB_PATH" \
            -L "$TEST_LIB_PATH" \
            -lMiniTests \
            -o "$CR_SUGGESTED_OUTPUT_FILE" \
            -Xlinker -rpath -Xlinker "$TEST_LIB_PATH" \
            "$SRC_FILE" "$CR_FILENAME" "${@:1}" ${CR_DEBUGGING:+-g}
            ;;
        *)
            xcrun -sdk macosx swiftc -strict-concurrency=minimal -o "$CR_SUGGESTED_OUTPUT_FILE" "$CR_FILENAME" "${@:1}" ${CR_DEBUGGING:+-g}
            ;;
    esac
fi
status=$?
if [ $status -eq 0 ]; then
    echo "$CR_SUGGESTED_OUTPUT_FILE"
fi
exit $status
