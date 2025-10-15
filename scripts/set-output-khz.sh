#!/bin/bash

# set-output-khz.sh - Shell script wrapper for setting macOS audio output frequency
# This script provides a convenient interface to set audio sample rates using the main Swift tool

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TOOL_PATH="$PROJECT_DIR/mac-audio-default"

# Default sample rates commonly used in audio production
SAMPLE_RATES=(44100 48000 88200 96000 176400 192000)

usage() {
    echo "Usage: $0 [OPTIONS] <sample_rate>"
    echo ""
    echo "Set the sample rate for the default macOS audio output device"
    echo ""
    echo "OPTIONS:"
    echo "  -l, --list      List all available audio devices"
    echo "  -s, --show      Show current default output device"
    echo "  -h, --help      Display this help message"
    echo ""
    echo "SAMPLE_RATES:"
    echo "  Common rates: ${SAMPLE_RATES[*]} Hz"
    echo ""
    echo "Examples:"
    echo "  $0 48000       Set output to 48kHz"
    echo "  $0 -l          List all audio devices"
    echo "  $0 -s          Show current default device"
    echo ""
}

# Check if the main tool exists
check_tool() {
    if [ ! -f "$TOOL_PATH" ]; then
        echo "Error: mac-audio-default tool not found at $TOOL_PATH"
        echo "Please run 'make' to build the project first"
        exit 1
    fi
}

# Validate sample rate
validate_sample_rate() {
    local rate="$1"
    
    # Check if it's a number
    if ! [[ "$rate" =~ ^[0-9]+$ ]]; then
        echo "Error: Sample rate must be a positive integer"
        exit 1
    fi
    
    # Check if it's within reasonable range (8kHz to 384kHz)
    if [ "$rate" -lt 8000 ] || [ "$rate" -gt 384000 ]; then
        echo "Error: Sample rate must be between 8000 and 384000 Hz"
        exit 1
    fi
}

# Main script logic
main() {
    case "${1:-}" in
        -h|--help)
            usage
            exit 0
            ;;
        -l|--list)
            check_tool
            "$TOOL_PATH" list
            exit 0
            ;;
        -s|--show)
            check_tool
            "$TOOL_PATH" default
            exit 0
            ;;
        "")
            echo "Error: No arguments provided"
            usage
            exit 1
            ;;
        -*)
            echo "Error: Unknown option $1"
            usage
            exit 1
            ;;
        *)
            # Assume it's a sample rate
            local sample_rate="$1"
            validate_sample_rate "$sample_rate"
            check_tool
            
            echo "Setting audio output sample rate to ${sample_rate} Hz..."
            if "$TOOL_PATH" set-rate "$sample_rate"; then
                echo "Successfully set sample rate to ${sample_rate} Hz"
            else
                echo "Failed to set sample rate"
                exit 1
            fi
            ;;
    esac
}

# Run main function with all arguments
main "$@"