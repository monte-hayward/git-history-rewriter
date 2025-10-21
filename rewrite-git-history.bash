# Define bad and good commit identities
EMAIL_BAD="$1"
NAME_BAD="$2"
EMAIL_GOOD="$3"
NAME_GOOD="$4"

# Define usage function
usage() {
  echo "Usage: $0 <EMAIL_BAD> <NAME_BAD> <EMAIL_GOOD> <NAME_GOOD>"
  echo "Example: $0 'john.wrong@example.com' 'john wrong' 'jane@correct.com' 'Jane Doe'"
  exit 1
}

# Check if 4 arguments are supplied
if [ "$#" -ne 4 ]; then
  usage
fi

echo -e "\n--- 3. REWRITING HISTORY (Repo: $(basename $(pwd))) ---"

# Execute the history rewrite
git filter-repo --commit-callback '
    # Define byte literals for comparison
    NAME_GOOD = b"'"$NAME_GOOD"'"
    EMAIL_GOOD = b"'"$EMAIL_GOOD"'"
    NAME_BAD = b"'"$NAME_BAD"'"
    EMAIL_BAD = b"'"$EMAIL_BAD"'"

    if commit.author_email == EMAIL_BAD or commit.author_name == NAME_BAD:
        commit.author_name = NAME_GOOD
        commit.author_email = EMAIL_GOOD

    if commit.committer_email == EMAIL_BAD or commit.committer_name == NAME_BAD:
        commit.committer_name = NAME_GOOD
        commit.committer_email = EMAIL_GOOD
'
# ⚠️ THE FIX FOR FALSE ALERTS:
echo -e "\n--- 4. CLEANING UP BACKUP HISTORY ---"
# git filter-repo saves the old history under 'refs/original'. 
# Running 'git for-each-ref --format="%(refname)" refs/original' should show these refs.
# Force a garbage collection (gc) to prune the old, unreachable objects.
git reflog expire --expire=now --all && git gc --prune=now

echo -e "\n--- VERIFICATION ---"

if git log --all --pretty=raw | grep -q -i "$EMAIL_BAD" || \
   git log --all --pretty=raw | grep -q -i "$NAME_BAD"; then
    echo "❌ FAILURE: Bad commits still exist! DO NOT PUSH."
    echo "    Please inspect log for email: git log --all --pretty=raw | grep -q -i $EMAIL_BAD"
    echo "    Please inspect log for name: git log --all --pretty=raw | grep -q -i $NAME_BAD"
else
    echo "✅ SUCCESS: No commits found for $EMAIL_BAD or $NAME_BAD in any branch."

    # Verification: Print the last 3 commits to confirm the good identity
    echo -e "\nLast 3 Commits (Should all show $NAME_GOOD and $EMAIL_GOOD identity):"
    git log -3 --pretty=fuller
    echo
    echo "Next Steps"
    echo -e "\n--- FORCE PUSH COMMAND (History Rewrite) ---"
    echo "To overwrite the remote repository with this new, clean history, run the following command:"
    echo "git push --force-with-lease --all"
    echo -e "\nTHIS IS A DESTRUCTIVE OPERATION. PROCEED WITH CAUTION."
    echo "Refer to README.md if this fails: git push --force-with-lease --all"
    echo "After successful push, can update tags:"
    echo "git push --force --tags"
fi
