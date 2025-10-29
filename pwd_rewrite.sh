#!/bin/bash

# Kondwani Mtawali
# 10/26/2025
# 'pwd' coreutil rewrite with two flag implementations

help() { 
    echo -e "This program replicates the function of the 'pwd' coreutil"
    echo -e "It includes the -L and -P flags "
    echo -e "Options:"
    echo -e "     [Get Active Dir]: pwd_rewrite"
    echo -e "     [Logical Path]: -L"
    echo -e "     [Physical Path]: -P"
    echo -e "     [Help]: h"
}

# Function that validates the directory
validate_dir() { 
    local dir="$1"
    if [ ! -d "$dir" ]; then
        echo "Directory does not exist: $dir" >&2
        return 1
    fi

    # Attempt cd into directory
    if ! cd "$dir" 2>/dev/null; then
        echo "Cannot access directory: $dir" >&2
        return 1
    fi
    return 0 
}

# Get physical path (resolve symlinks)
get_physical() {
    local dir="${1:-.}"
    local path=""

    # Use a subshell to safely cd without changing main shell
    while true; do
        # Resolve symlink if dir is one
        if [ -L "$dir" ]; then
            dir=$(readlink "$dir")
        fi

        # Prepend basename to path
        local base
        base=$(basename "$dir")
        path="/$base$path"

        # Get parent directory
        local parent
        parent=$(cd "$dir/.." 2>/dev/null && echo "$(stat -c "%i" .):$dir/..")
        local parent_inode="${parent%%:*}"
        local parent_path="${parent#*:}"

        local current_inode
        current_inode=$(stat -c "%i" "$dir")
        if [ "$current_inode" -eq "$parent_inode" ]; then
            break
        fi

        dir="$parent_path"
    done

    echo "$path"
}

# Get logical path (preserve symlinks)
get_logical() {
    local dir="${1:-.}"
    local path=""

    while true; do
        # Prepend basename (do not resolve symlinks)
        local base
        base=$(basename "$dir")
        path="/$base$path"

        # Get parent directory
        local parent
        parent=$(cd "$dir/.." 2>/dev/null && echo "$(stat -c "%i" .):$dir/..")
        local parent_inode="${parent%%:*}"
        local parent_path="${parent#*:}"

        # Stop if at root (inode same as current)
        local current_inode
        current_inode=$(stat -c "%i" "$dir")
        if [ "$current_inode" -eq "$parent_inode" ]; then
            break
        fi

        dir="$parent_path"
    done

    echo "$path"
}

# pwd rewrite function
pwd_rewrite() { 
    local mode="logical" # logical is set by default
    local OPTIND opt

    # Parsing flags using getopts
    while getopts ":LPh" opt; do
        case "$opt" in
            L) mode="logical"
            ;;
            P) mode="physical" 
            ;;
            h) help; 
            exit 0;;
            \?) echo "Invalid Input: -$OPTARG"; help; exit 1;;
        esac
    done
    shift $((OPTIND - 1))
    
    # Default to current directory
    local dir="${1:-.}"

    # Validate directory
    validate_dir "$dir" || exit 1

    # Print path based on mode
    if [ "$mode" = "logical" ]; then
        get_logical "$dir"
    else
        get_physical "$dir"
    fi
}

# Call main function with user's arguments
pwd_rewrite "$@"



