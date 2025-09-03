#!/bin/bash

# Gemini Prompt Runner Script
# Usage: ./gemini-prompt.sh "your prompt here"
# or: bash gemini-prompt.sh "your prompt here"

# Check if GOOGLE_CLOUD_PROJECT is set
if [ -z "$GOOGLE_CLOUD_PROJECT" ]; then
    echo "Error: GOOGLE_CLOUD_PROJECT environment variable is not set."
    echo "Please set it by running: export GOOGLE_CLOUD_PROJECT=\"your-project-id\""
    echo "Example: export GOOGLE_CLOUD_PROJECT=\"vn-codeassist\""
    exit 1
fi

# Check if a prompt was provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 \"your prompt here\""
    echo "Example: $0 \"What is the weather today?\""
    exit 1
fi

# Run gemini with the provided prompt
gemini -p "$1"
