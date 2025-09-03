# Assignment 1 INF-3200

A distributed web server deployment system that automatically launches HTTP servers across cluster nodes.

## Overview

This project implements a cluster deployment system that:
- Deploys multiple web servers across available compute nodes
- Automatically distributes servers to different nodes (wraps around if more servers than nodes)
- Each server responds to `/helloworld` with its host:port combination

## Components

- **`web-server`** - HTTP server binary (responds to `/helloworld` with host:port)
- **`run.sh`** - Deployment script that launches servers across cluster nodes
- **`testscript.py`** - Test client that validates all server endpoints
- **`cleanup.sh`** - Stops all running web-server instances

## Usage

### Deploy servers
```bash
./run.sh <number_of_servers>
```

**Example:**
```bash
./run.sh 3
["c0-1:50153", "c1-0:49001", "c1-1:55737"]
```

### Test deployment
```bash
python3 testscript.py '["c0-1:50153", "c1-0:49001", "c1-1:55737"]'
```

**Expected output:**
```
received "c0-1:50153"
received "c1-0:49001"
received "c1-1:55737"
Success!
```

### Cleanup
```bash
./cleanup.sh
```

## Implementation Details

- **Server**: Written in Rust using tiny_http library
- **API**: GET `/helloworld` returns host:port, all other endpoints return "404"
- **Node selection**: Uses random distribution across available cluster nodes
- **Port assignment**: Random ports in range 49152-65535
- **Deployment strategy**: One server per node until all nodes used, then wraps around
- **Output format**: JSON array of host:port strings
- **Cleanup**: Parallel termination of all web-server processes across nodes

## Files Generated

- `active_nodes.txt` - Tracks nodes with running servers (for cleanup)
- `stdout/` - Directory containing stdout/stderr logs from each node
