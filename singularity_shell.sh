#!/bin/sh

# Check if a device is a block device
isBlockDevice() {
    [ "$(ls -l "$1" 2>/dev/null | cut -c 1)" = "b" ]
}

# Check if a device is a loop device
isLoopDevice() {
    losetup "$1" >/dev/null 2>&1
}

# Main function
main() {
    # Store passed arguments
    cmdArgs="$*"

    # Get df output
    df_output=$(df --output=source,target 2>/dev/null)

    # Initialize empty volume arguments
    volumeArgs=""

    # Parse df output
    echo "$df_output" | tail -n +2 | while read -r source target; do
        # Skip if not in /dev
        [ "${source#/dev/}" = "$source" ] && continue

        # Check for block and non-loopback devices
        if isBlockDevice "$source" && ! isLoopDevice "$source"; then
            # Exclude root mount
            [ "$target" != "/" ] || continue

            # Append to volume args
            volumeArgs="$volumeArgs --bind $target:$target"
        fi
    done

    # Execute singularity shell with volume and additional arguments
    eval "singularity shell $volumeArgs $cmdArgs"
}

main "$@"
