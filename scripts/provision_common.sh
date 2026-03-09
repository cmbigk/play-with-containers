#!/bin/bash

echo ">>> Updating system and installing common dependencies..."
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y python3 python3-pip python3-venv git curl

echo ">>> Common dependencies installed."
