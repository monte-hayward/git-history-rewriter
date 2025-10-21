#!/bin/bash

# Define usage function
usage() {
  echo "Usage: $0 \"NAME_GOOD\" \"EMAIL_GOOD\" \"EMAIL_BAD\" \"REPOS_DIR\""
  echo "Example: $0 \"Jane Doe\" \"jane@correct.com\" \"john@wrong.com\" ~/my-git-projects"
  exit 1
}

# Check if 4 arguments are supplied
if [ "$#" -ne 4 ]; then
  usage
fi

NAME_GOOD="$1"
EMAIL_GOOD="$2"
EMAIL_BAD="$3"
REPOS_DIR="$4"

echo "--- 1. CONFIGURATION AND STATUS CHECK ---"
echo "Target Directory: $REPOS_DIR"
echo "Setting Identity: $NAME_GOOD <$EMAIL_GOOD>"

# Navigate to the target directory
cd "$REPOS_DIR" || { echo "Error: Directory '$REPOS_DIR' not found."; exit 1; }

# Loop through all subdirectories
for dir in */; do
  # Check if the subdirectory exists and contains a .git folder
  if [ -d "$dir" ] && [ -d "$dir/.git" ]; then
    echo -e "\n[Repo: $dir]"
    
    # Enter the repo directory
    cd "$dir"
    
    # Check for uncommitted changes
    if ! git diff --quiet HEAD || ! git diff-index --quiet HEAD --; then
      echo "⚠️ $(basename "$dir") WARNING: UNCOMMITTED CHANGES EXIST. Stash or commit before proceeding."
    fi
    
    # Read current local config
    CURRENT_NAME=$(git config --local user.name)
    CURRENT_EMAIL=$(git config --local user.email)

    # Correct email if needed
    if [ "$CURRENT_EMAIL" != "$EMAIL_GOOD" ]; then
      echo "❌ Incorrect/Missing Email: '$CURRENT_EMAIL'. Setting to '$EMAIL_GOOD'."
      git config user.email "$EMAIL_GOOD"
    fi
    # Correct name if needed
    if [ "$CURRENT_NAME" != "$NAME_GOOD" ]; then
      echo "❌ Incorrect/Missing Name: '$CURRENT_NAME'. Setting to '$NAME_GOOD'."
      git config user.name "$NAME_GOOD"
    fi
    
    # Final check of local config
    echo "✅ Local Config: $(git config --local user.name) <$(git config --local user.email)>"
    
    # Return to the parent directory ($REPOS_DIR)
    cd ..
  fi
done

echo -e "\n--- Configuration check complete. ---"
