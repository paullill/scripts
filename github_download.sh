#!/bin/bash

# Usage: ./scriptName.sh <access_token> <owner> <repo> <file_path> [branch]
# Example: ./scriptName.sh ghp_YourAccessToken ownername reponame path/to/file.txt main

ACCESS_TOKEN=$1
OWNER=$2
REPO=$3
FILE_PATH=$4
BRANCH=${5:-main}  # Default to 'main' branch if not specified

# Construct the API URL
API_URL="https://api.github.com/repos/$OWNER/$REPO/contents/$FILE_PATH?ref=$BRANCH"

# Use curl to download the file
curl -H "Authorization: token $ACCESS_TOKEN" \
     -H "Accept: application/vnd.github.v3.raw" \
     -o "$(basename $FILE_PATH)" \
     -L $API_URL
