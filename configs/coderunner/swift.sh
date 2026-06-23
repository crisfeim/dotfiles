#!/bin/bash
[ -z "$CR_SUGGESTED_OUTPUT_FILE" ] && CR_SUGGESTED_OUTPUT_FILE="$PWD/${CR_FILENAME%.*}"
if [ "$CR_FILENAME" = "main.swift" ]; then
    xcrun -sdk macosx swiftc -strict-concurrency=minimal -o "$CR_SUGGESTED_OUTPUT_FILE" *.swift "${@:1}" ${CR_DEBUGGING:+-g}
else
	xcrun -sdk macosx swiftc -strict-concurrency=minimal -o "$CR_SUGGESTED_OUTPUT_FILE" "$CR_FILENAME" "${@:1}" ${CR_DEBUGGING:+-g}
fi
status=$?
if [ $status -eq 0 ]; then
    echo "$CR_SUGGESTED_OUTPUT_FILE"
fi
exit $status
