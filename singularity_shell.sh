#!/bin/bash

# Check if a given device is a block device
isBlockDevice() {
  [[ $(ls -l "$1" 2>/dev/null | cut -c1) == "b" ]]
}

# Check if a given device is a loop device
isLoopDevice() {
  losetup "$1" >/dev/null 2>&1
}

# Create a mapping of device names to their corresponding mount points
getDfOutputMap() {
  df --output=source,target | tail -n +2 | awk '$1 ~ /^\/dev\// {print $1, $2}'
}

# Get mount points of non-loopback block devices
getMountPoints() {
  mountPoints=()
  while read -r device mount; do
    if isBlockDevice "$device" && ! isLoopDevice "$device"; then
      mountPoints+=("$device")
    fi
  done <<< "$1"
  echo "${mountPoints[@]}"
}

# Generate volume arguments for container runtime
generateVolumeArgs() {
  volumeArgs=()
  while read -r device mount; do
    if [[ " ${mountPoints[@]} " =~ " ${device} " ]]; then
      if [ "$mount" != "/" ]; then
        volumeArgs+=("--bind" "$mount:$mount")
      fi
    fi
  done <<< "$1"
  echo "${volumeArgs[@]}"
}

# Main function
main() {
  # Store passed arguments
  cmdArgs="$*"

  dfOutput=$(getDfOutputMap)
  mountPoints=($(getMountPoints "$dfOutput"))
  volumeArgs=($(generateVolumeArgs "$dfOutput"))

  # Execute singularity shell with volume and additional arguments
  eval "singularity shell ${volumeArgs[@]} $cmdArgs"
}

main "$@"
