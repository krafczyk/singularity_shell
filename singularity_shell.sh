#!/bin/bash

# Check if a given device is a block device
isBlockDevice() {
  local device=$1
  [[ $(ls -l "$device" 2>/dev/null | cut -c1) == "b" ]]
}

# Check if a given device is a loop device
isLoopDevice() {
  local device=$1
  losetup "$device" >/dev/null 2>&1
}

# Create a mapping of device names to their corresponding mount points
getDfOutputMap() {
  declare -A dfMap
  while read -r source target; do
    [[ $source == "/dev/"* ]] && dfMap["$source"]="$target"
  done < <(df --output=source,target | tail -n +2)
  echo "${dfMap[@]}"
}

# Get mount points of non-loopback block devices
getMountPoints() {
  local -n dfMap=$1
  local mountPoints=()
  for device in "${!dfMap[@]}"; do
    if isBlockDevice "$device" && ! isLoopDevice "$device"; then
      mountPoints+=("$device")
    fi
  done
  echo "${mountPoints[@]}"
}

# Generate volume arguments for container runtime
generateVolumeArgs() {
  local -n dfMap=$1
  local -n mountPoints=$2
  local volumeArgs=()
  for device in "${mountPoints[@]}"; do
    local mount=${dfMap[$device]}
    if [ "$mount" != "/" ]; then
      volumeArgs+=("--bind" "$mount:$mount")
    fi
  done
  echo "${volumeArgs[@]}"
}

# Main function
main() {
  # Store passed arguments
  cmdArgs="$*"

  declare -A dfMap
  read -ra dfMap <<< "$(getDfOutputMap)"
  read -ra mountPoints <<< "$(getMountPoints dfMap)"
  read -ra volumeArgs <<< "$(generateVolumeArgs dfMap mountPoints)"

  echo ${volumeArgs[@]}

  # Execute singularity shell with volume and additional arguments
  #eval "singularity shell $volumeArgs $cmdArgs"
}

main "$@"
