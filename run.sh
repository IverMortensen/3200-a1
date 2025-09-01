#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 <number>"
    exit 1
fi

num_nodes=$1
node_file="active_nodes.txt"
temp_dir=$(mktemp -d)
host_ports=()

# Get available nodes
all_nodes=$(/share/ifi/available-nodes.sh)
selected_nodes=$(echo "$all_nodes" | head -"$num_nodes")

echo "$selected_nodes" > "$node_file"
echo "Selected nodes:"
echo "$selected_nodes"
echo ""

# Start the processes
echo "$selected_nodes" | while read -r node; do
    if [ -n "$node" ]; then
        echo "Processing node: $node"

        temp_file="$temp_dir/${node}.out"
        ssh imo059@"$node" "~/3200-a1/web-server/target/release/web-server" > "$temp_file" 2>&1 &
        # Store process output in temp file
        echo "$temp_file" >> "$temp_dir/temp_files.list"
    fi
done

echo "Done."
echo ""

sleep 2

# Create and print the json output
host_ports_json="["
first=true

while IFS= read -r temp_file; do
    if [ -f "$temp_file" ]; then
        # Get the host and port from output temp file
        host_port=$(grep "Host:port" "$temp_file" | sed 's/Host:port //')
        if [ -n "$host_port" ]; then
            if [ "$first" = true ]; then
                host_ports_json="${host_ports_json}\"${host_port}\""
                first=false
            else
                host_ports_json="${host_ports_json}, \"${host_port}\""
            fi
        fi
    fi
done < "$temp_dir/temp_files.list"

host_ports_json="${host_ports_json}]"

echo "$host_ports_json"

# Clean up temporary files
rm -rf "$temp_dir"
