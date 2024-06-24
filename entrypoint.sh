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
echo "Cloning source repository..."
git clone "https://x-access-token:${SOURCE_REPO_TOKEN}@github.com/${SOURCE_REPO}.git" "$CLONE_DIR" || { echo "::error:: Failed to clone source repository"; exit 1; }
echo "Source repository cloned successfully."

# Create the destination directory if it doesn't exist
echo "Creating destination directory..."
mkdir -p "${DESTINATION_PATH}"

# Copy files from source to destination
echo "Copying files from source to destination..."
cp -r "$CLONE_DIR/${SOURCE_PATH}" "${DESTINATION_PATH}"
echo "Files copied successfully."

# Configure git
echo "Configuring git user..."
git config --global user.name "${GITHUB_ACTOR}"
git config --global user.email "${GITHUB_ACTOR}@users.noreply.github.com"

# Check if there are changes or untracked files
echo "Checking for changes..."
git status 

if git diff-index --quiet HEAD --; then
    echo "No changes or untracked files found. Exiting gracefully."
    exit 0
fi

# Create Pull Request
if [ "${CREATE_PR}" == "true" ]; then
  OWNER=$(echo "$GITHUB_REPOSITORY" | cut -d'/' -f1)
  REPO=$(echo "$GITHUB_REPOSITORY" | cut -d'/' -f2)
  HEAD="auto-file-copy-$(date +'%Y%m%d%H%M%S')-$(openssl rand -hex 3)"

  # Create a new branch for the PR
  echo "Creating new branch for Pull Request..."
  git checkout -b "${HEAD}"

  # Add and commit changes
  echo "Adding and committing changes..."
  git add -A
  git commit -m "${COMMIT_MESSAGE}"
  
  git push --set-upstream origin "${HEAD}"

  # Create the PR
  echo "Creating Pull Request..."
  PR_RESPONSE=$(curl -X POST -sSf -H "Authorization: token ${DEST_REPO_TOKEN}" \
       -d "{\"title\":\"${PR_TITLE}\", \"head\":\"${HEAD}\", \"base\":\"main\"}" \
       "https://api.github.com/repos/${OWNER}/${REPO}/pulls")
  
  PR_URL=$(echo "${PR_RESPONSE}" | jq -r '.html_url')

  if [ -n "$PR_URL" ]; then
    echo "Pull Request created successfully: ${PR_URL}"
  else
    echo "::error:: Failed to create Pull Request"
    exit 1
  fi
else 
    # Pull with rebase from the main branch and pushing changes to the main branch
    echo "Pulling with rebase from main and pushing changes to main..."
    git pull --rebase origin main
    git push || { echo "::error:: Failed to push changes"; exit 1; }
fi
