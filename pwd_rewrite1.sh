#!/bin/bash

# Kondwani Mtawali
# 10/26/2025
# 'pwd' coreutil rewrite with -L and -P flags

help() { 
    echo -e "This program replicates the function of the 'pwd' coreutil"
    echo -e "It includes the -L and -P flags"
    echo -e "Options:"
    echo -e "     [Get Active Dir]: pwd_rewrite"
    echo -e "     [Logical Path]: -L"
    echo -e "     [Physical Path]: -P"
    echo -e "     [Help]: -h"
}

# Validate directory exists and is accessible
validate_dir() {
    local dir="$1"
    if [ ! -e "$dir" ]; then
        echo "$dir: No such file or directory" >&2
        return 1
    fi
    if [ ! -d "$dir" ]; then
        echo "$dir: Not a directory" >&2
        return 1
    fi
    if ! cd "$dir" 2>/dev/null; then
        echo "$dir: Permission denied" >&2
        return 1
    fi
    return 0
}

# Physical path: fully resolve symlinks without pwd
get_physical() {
    local start_dir="${1:-.}"
    readlink -f "$start_dir"  # readlink resolves to physical path that the symbolic link points to
}

# Logical path: uses $PWD but doesn't no resolved symlinks
get_logical() {
    local start_dir="${1:-.}"
    local saved_pwd="$PWD"

    if ! cd "$start_dir" 2>/dev/null; then
        echo "cannot cd to '$start_dir'" >&2
        return 1
    fi

    echo "$PWD"
    cd "$saved_pwd" 2>/dev/null || true # Goes back into saved dir, doesn't break function if cd fails
}

# pwd_rewrite function
pwd_rewrite() {
    local mode="logical"  # set to logical by default
    local OPTIND opt # Decalring option index to keep track of arguments

    while getopts ":LPh" opt; do
        case "$opt" in
            L) mode="logical" ;;
            P) mode="physical" ;;
            h) help; exit 0 ;;
            \?) echo "Invalid option: -$OPTARG" >&2; help; exit 1 ;;
            :) echo "Argument required: -$OPTARG" >&2; exit 1 ;;
        esac
    done
    shift $((OPTIND - 1)) # Removes arguments already handled

    local dir="${1:-.}"

    # Validate input directory
    if ! validate_dir "$dir"; then
        exit 1
    fi

    # Change to the directory first
    if ! cd "$dir" 2>/dev/null; then
        echo "Cannot access '$dir'" >&2
        exit 1
    fi

    # Output based on mode
    if [ "$mode" = "physical" ]; then
        get_physical .
    else
        get_logical .
    fi
}

# Run main function with all arguments
pwd_rewrite "$@"