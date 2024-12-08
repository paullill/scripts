#!/bin/bash
# Usage: ./scriptName.sh <access_token> <owner> <repo> <path> [branch]
# Example: ./scriptName.sh ghp_YourAccessToken ownername reponame path/to/folder main
# Note: path can be a file or directory

ACCESS_TOKEN=$1
OWNER=$2
REPO=$3
PATH_TO_DOWNLOAD=$4
BRANCH=${5:-main}  # Default to 'main' branch if not specified

if [ -z "$ACCESS_TOKEN" ] || [ -z "$OWNER" ] || [ -z "$REPO" ] || [ -z "$PATH_TO_DOWNLOAD" ]; then
    echo "Error: Missing required arguments"
    echo "Usage: $0 <access_token> <owner> <repo> <path> [branch]"
    exit 1
fi

# Function to create directory if it doesn't exist
create_directory() {
    local dir=$1
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
    fi
}

# Function to download a single file
download_file() {
    local path=$1
    local output_path=$2
    
    echo "Downloading: $path to $output_path"
    
    # Create directory structure if needed
    create_directory "$(dirname "$output_path")"
    
    # Download the file
    curl -H "Authorization: token $ACCESS_TOKEN" \
         -H "Accept: application/vnd.github.v3.raw" \
         -o "$output_path" \
         -L "https://api.github.com/repos/$OWNER/$REPO/contents/$path?ref=$BRANCH" \
         -s
    
    if [ $? -eq 0 ]; then
        echo "Successfully downloaded: $path"
    else
        echo "Failed to download: $path"
    fi
}

# Function to list and download directory contents recursively
process_directory() {
    local path=$1
    
    # Get directory contents
    local contents=$(curl -H "Authorization: token $ACCESS_TOKEN" \
                         -H "Accept: application/vnd.github.v3+json" \
                         -s \
                         "https://api.github.com/repos/$OWNER/$REPO/contents/$path?ref=$BRANCH")
    
    # Check if we got an error response (look specifically for error message)
    if echo "$contents" | jq -e '.message and .documentation_url' >/dev/null 2>&1; then
        echo "Error: $(echo "$contents" | jq -r '.message')"
        exit 1
    fi
    
    # Process each item in the directory
    echo "$contents" | jq -r '.[] | select(. != null) | "\(.type)|\(.path)"' 2>/dev/null | while IFS='|' read -r type path; do
        if [ "$type" = "file" ]; then
            download_file "$path" "$path"
        elif [ "$type" = "dir" ]; then
            process_directory "$path"
        fi
    done
}

# Main execution
echo "Starting download from GitHub..."
echo "Repository: $OWNER/$REPO"
echo "Path: $PATH_TO_DOWNLOAD"
echo "Branch: $BRANCH"

# Check if jq is executable
if ! type jq >/dev/null 2>&1; then
    echo "Error: This script requires 'jq' to be installed."
    echo "Please install it using your package manager:"
    echo "  For Ubuntu/Debian: sudo apt-get install jq"
    echo "  For MacOS: brew install jq"
    exit 1
fi

# Get information about the path
path_info=$(curl -H "Authorization: token $ACCESS_TOKEN" \
                 -H "Accept: application/vnd.github.v3+json" \
                 -s \
                 "https://api.github.com/repos/$OWNER/$REPO/contents/$PATH_TO_DOWNLOAD?ref=$BRANCH")

# Check for API errors first
if echo "$path_info" | jq -e '.message and .documentation_url' >/dev/null 2>&1; then
    echo "Error: $(echo "$path_info" | jq -r '.message')"
    exit 1
fi

# Determine if it's a file or directory
if echo "$path_info" | jq -e 'type == "object" and has("type") and .type == "file"' >/dev/null 2>&1; then
    # It's a file
    download_file "$PATH_TO_DOWNLOAD" "$PATH_TO_DOWNLOAD"
else
    # Try to process as directory
    process_directory "$PATH_TO_DOWNLOAD"
fi

echo "Download complete!"
