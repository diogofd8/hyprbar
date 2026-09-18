#!/usr/bin/env bash

# Check if the user provided at least one argument for window title and a command
if [ $# -lt 2 ]; then
    echo "Usage: $0 <window-title> <command-to-run> [--interactive]"
    exit 1
fi

WIN_TITLE="$1"
shift

# Check for optional interactive flag
KEEP_ALIVE=false
if [[ "${@: -1}" == "--keep-alive" ]]; then
    KEEP_ALIVE=true
    # Remove the flag from command arguments
    set -- "${@:1:$(($#-1))}"
fi

CMD="$@"

# Try to find the process
PID=$(pgrep -f "alacritty.*-t $WIN_TITLE")

if [ -n "$PID" ]; then
    # Process exists → kill it
    kill "$PID"
else
    # Process doesn't exist → open it
    if [ "$KEEP_ALIVE" = true ]; then
        # Wrap the command in an keep alive shell
        alacritty -t "$WIN_TITLE" -e sh -c "$CMD; read -n1 -s" &
    else
        alacritty -t "$WIN_TITLE" -e $CMD &
    fi
fi