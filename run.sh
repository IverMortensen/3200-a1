#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 <number>"
    exit 1
fi

num_nodes=$1
target="$HOME/3200-a1/web-server/target/release/web-server"
active_nodes_file="active_nodes.txt"
stdout_dir="./stdout"
mkdir -p "$stdout_dir"

ports=()

# Get available nodes
all_nodes=$(/share/ifi/available-nodes.sh)
readarray -t selected_nodes < <(echo "$all_nodes" | shuf -n "$num_nodes")

# Store active nodes on disk for clean up script
printf "%s\n" "${selected_nodes[@]}" >> "$active_nodes_file"

echo "Selected nodes:"
printf "%s\n" "${selected_nodes[@]}"
echo ""

# Start processes
for node in "${selected_nodes[@]}"; do
    if [ -n "$node" ]; then
        echo "Processing node: $node"
        port=$(shuf -i 49152-65535 -n1)
        ports+=("$port")
        ssh "$USER"@"$node" "$target" "$node" "$port" > "${stdout_dir}/${node}" 2>&1 &
    fi
done

echo ""

# Create and print the json output
json_output="["
index=0
for node in "${selected_nodes[@]}"; do
    if [ -n "$node" ]; then
        if [ "$index" = 0 ]; then
            json_output="${json_output}\"${node}:${ports["$index"]}\""
        else
            json_output="${json_output}, \"${node}:${ports["$index"]}\""
        fi
        ((index++))
    fi
done
json_output="${json_output}]"

echo "$json_output"
