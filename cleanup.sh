#!/bin/bash

node_file="active_nodes.txt"
stdout_dir="stdout"

if [ ! -f "$node_file" ]; then
    echo "No active nodes file found: $node_file"
    exit 1
fi

echo "Killing processes..."
cat "$node_file"
echo ""

while read -r node; do
    if [ -n "$node" ]; then
        echo -n "Killing web-server on $node... "
        if ssh -n "$USER"@"$node" "pkill web-server" 2>/dev/null; then
            echo "SUCCESS"
        else
            echo "No process found or failed"
        fi
    fi
done < "$node_file"

rm -f "$node_file"
rm -r "$stdout_dir"
echo "Done."

