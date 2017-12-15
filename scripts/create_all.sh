#!/bin/sh

echo "Creating SSH keys..."
sh scripts/create_keys.sh
echo "done."

echo "Creating Subnets..."
sh scripts/create_network.sh
echo "done."

echo "Creating Stack..."
sh scripts/create_stack.sh
echo "done."
