#!/bin/bash

set -eu
set +x

# Required inputs
SOURCE_REPO="${1}"
SOURCE_PATH="${2}"
DESTINATION_PATH="${3}"
COMMIT_MESSAGE="${4}"
CREATE_PR="${5}"
PR_TITLE="${6}"
SOURCE_REPO_TOKEN="${7}"
DEST_REPO_TOKEN="${8}"

# Validate inputs
if [ -z "$SOURCE_REPO" ] || [ -z "$SOURCE_PATH" ] || [ -z "$DESTINATION_PATH" ] || [ -z "$COMMIT_MESSAGE" ] || [ -z "$CREATE_PR" ] || [ -z "$PR_TITLE" ] || [ -z "$SOURCE_REPO_TOKEN" ] || [ -z "$DEST_REPO_TOKEN" ]; then
    echo "::error:: One or more required inputs are missing."
    exit 1
fi

# Trust the current repository
git config --global --add safe.directory /github/workspace

CLONE_DIR=$(mktemp -d)

# Clone the source repository
git clone "https://x-access-token:${SOURCE_REPO_TOKEN}@github.com/${SOURCE_REPO}.git" "$CLONE_DIR" || { echo "Failed to clone source repository"; exit 1; }

# Create the destination directory if it doesn't exist
mkdir -p "${DESTINATION_PATH}"

# Copy files from source to destination
cp -r "$CLONE_DIR/${SOURCE_PATH}" "${DESTINATION_PATH}"

# Switch to destination directory
cd "$DESTINATION_PATH"

# Configure git
git config --global user.name "${GITHUB_ACTOR}"
git config --global user.email "${GITHUB_ACTOR}@users.noreply.github.com"

# Add, commit, and push changes
git add "${DESTINATION_PATH}"
git commit -m "${COMMIT_MESSAGE}"

# Check if there are changes or untracked files
if [[ -n $(git status --porcelain) ]]; then
    echo "Changes or untracked files found."
else
    echo "No changes or untracked files found. Exiting gracefully."
    exit 0
fi

# Create Pull Request
if [ "${CREATE_PR}" == "true" ]; then
  OWNER=$(echo "$GITHUB_REPOSITORY" | cut -d'/' -f1)
  REPO=$(echo "$GITHUB_REPOSITORY" | cut -d'/' -f2)
  HEAD="auto-file-copy-$(date +'%Y%m%d%H%M%S')-$(openssl rand -hex 3)"

  # Create a new branch for the PR
  git checkout -b "${HEAD}"
  git push --set-upstream origin "${HEAD}"

  # Create the PR
  curl -X POST -H "Authorization: token ${DEST_REPO_TOKEN}" \
       -d "{\"title\":\"${PR_TITLE}\", \"head\":\"${HEAD}\", \"base\":\"main\"}" \
       "https://api.github.com/repos/${OWNER}/${REPO}/pulls"
else 
    # Pull with rebase from the main branch
    git pull --rebase origin main
    git push || { echo "Failed to push changes"; exit 1; }
fi
