# Define bad commit identity
EMAIL_BAD="$1"
NAME_BAD="$2"

# Define usage function
usage() {
  echo "Usage: $0 <EMAIL_BAD> <NAME_BAD>"
  echo "Example: $0 'john.wrong@example.com' 'john wrong' ~/my-git-projects"
  exit 1
}

if [ "$#" -ne 2 ]; then
  usage
fi

if [ -d "./.git" ]; then
    echo "$(pwd) should be the PARENT of the repos to fix." 
    echo "found a .git dir"
    exit 1
fi

echo "\n--- 2. HISTORY SCAN FOR BAD COMMITS with $EMAIL_BAD or $NAME_BAD ---"

BAD_REPOS=()

for dir in */; do
  if [ -d "$dir/.git" ]; then
    cd "$dir"
    
# ⚠️ Search raw commit data for EITHER the bad email OR the bad name
if git log --all --pretty=raw | grep -q -i "$EMAIL_BAD" || \
   git log --all --pretty=raw | grep -q -i "$NAME_BAD"; then

    echo "❌ Repo '$dir': FOUND bad string in commit metadata for"
    git remote -v
    echo "examples (raw output with grep):"
    
    # Print the specific lines that triggered the failure for inspection
    git log --all --pretty=raw | grep -i "$EMAIL_BAD"
    git log --all --pretty=raw | grep -i "$NAME_BAD"
    echo
    BAD_REPOS+=("$dir")
else
    echo "✅ Repo '$dir': Clean history."
    echo
fi
    cd ..
  fi
done

echo -e "\n--- Scan complete. ---"

if [ ${#BAD_REPOS[@]} -eq 0 ]; then
    echo -e "\n🎉 GLOBAL SUCCESS: ALL repositories are clean."
    echo "No further action is required."
else
    echo -e "\n🚨 ACTION REQUIRED: The following repos need history rewrite:"
    for repo in "${BAD_REPOS[@]}"; do
        echo "  - $repo"
    done
    echo -e "\n Next step: Run the rewrite script on these directories."
fi