#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 <number>"
    exit 1
fi

num_nodes=$1
target="./web-server"
active_nodes_file="active_nodes.txt"
stdout_dir="./stdout"
mkdir -p "$stdout_dir"

all_nodes=()
nodes=()
ports=()

# Get available nodes
readarray -t all_nodes < <(/share/ifi/available-nodes.sh)
num_available_nodes=${#all_nodes[@]}

if [ $num_available_nodes -eq 0 ]; then
    echo "No nodes available."
    exit 1
fi

# Select random nodes
if [ $num_available_nodes -ge $num_nodes ]; then
    readarray -t nodes < <(printf '%s\n' "${all_nodes[@]}" | shuf -n "$num_nodes")
else
    # Extend nodes with repeats if not enough nodes
    readarray -t nodes < <(printf '%s\n' "${all_nodes[@]}" | shuf)
    missing_nodes=$((num_nodes - num_available_nodes))
    index=0
    while [ $missing_nodes -gt 0 ]; do
        nodes+=(${nodes[((index % num_available_nodes))]})
        ((missing_nodes--))
        ((index++))
    done
fi

# Store name of active nodes on disk for clean up script
printf "%s\n" "${nodes[@]}" | sort -u >> "$active_nodes_file"

# Start processes
for i in "${!nodes[@]}"; do
    node="${nodes[$i]}"
    port=$(shuf -i 49152-65535 -n1)
    ports+=("$port")

    # Copy target file to node (one for each proccess)
    # and start the proccess
    temp_file="/tmp/web-server-$$-$i"
    {
        scp "$target" "$USER@$node:$temp_file" && \
        ssh "$USER@$node" "chmod +x $temp_file && $temp_file $node $port; rm -f $temp_file"
    } > "${stdout_dir}/${node}" 2>&1 &
done

# Create and print the json output
json_output="["
for i in "${!nodes[@]}"; do
    node="${nodes[$i]}"
    if [ "$i" = 0 ]; then
        json_output="${json_output}\"${node}:${ports[$i]}\""
    else
        json_output="${json_output}, \"${node}:${ports[$i]}\""
    fi
done
json_output="${json_output}]"
echo "$json_output"
