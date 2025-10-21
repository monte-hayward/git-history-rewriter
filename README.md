# git-history-rewriter

Use this software and guide at your own risk. If you are not sure, do not.

`rewrite-git-history.md`: Definitive Guide to Cleaning Git History

This guide provides a robust, end-to-end process for permanently removing a "bad" user identity (Name or Email) from your Git repository history using `git-filter-repo`, ensuring verification and safe remote push.

Operations are performed on new clones of the repos to clean.

Prerequisites
-------------

1.  **Install `git-filter-repo`:** You must have `git-filter-repo` installed (e.g., via `pip install git-filter-repo` OR `sudo at install git-filter-repo`).

2.  make a dir REPO_CLEANUP and clone the repos into it
3.  **Parent Directory:** All commands are run from the **parent directory** that contains the repository (or repositories) you need to scan and fix.

4.  **Define Identities:** Know the exact bad and correct identities.

1\. The Definitive Scanner Script
---------------------------------

This script scans your repositories, identifies those containing the bad data (using the most robust method: searching the raw commit object), and stores the names of the bad repositories.

```bash
chmod +x bad-git-history-scanner.bash
cd REPO_CLEANUP
<path to script>/bad-git-history-scanner.bash bad-email@xample.com 'Bad Name'
```

*Note the list of "bad" repositories in the output*

2\. The Rewrite Script
----------------------

This command uses `git-filter-repo` with the callback logic to ensure both **Author** and **Committer** fields are fixed, and then executes the absolutely critical local cleanup steps.

### **Manual Step 2: Rewrite History (Run inside EACH Bad Repo)**

Navigate into one of the repositories identified by the scanner (e.g., `cd trust-ledger/`) and run the following block of commands.

```bash
cd repo-dir-to-fix
chmod +x <path to script>rewrite-git-history.bash
<path to script>rewrite-git-history.bash
```

Verify it is clean. The repo you just fixed should appear clean in the results.

```bash
chmod +x bad-git-history-scanner.bash
cd REPO_CLEANUP
<path to script>/bad-git-history-scanner.bash bad-email@xample.com 'Bad Name'
```

3\. Definitive Remote Push (Deployment)
---------------------------------------

After running the rewrite and purge steps inside the repository, the local history is clean. Now, we must safely overwrite the remote history.

### **Manual Step 3: Set/Verify Remote (if needed)**

If `git remote -v` fails to show an `origin`, you must add it now:

```bash
# Check:
git remote -v

# If no output:
# Replace <REMOTE_URL> with your repo's HTTPS or SSH URL
git remote add origin <REMOTE_URL>
```

### **Definitive Shell Commands to Put it in Remote**

Use the **safest** push method first.

```bash
# fetch remote state
# This updates your local 'lease' on the remote's head
git fetch origin

# safer push
# Pushes all branches, but fails if someone else pushed new commits
git push --force-with-lease --all

echo -e "\n--- 3C. FORCE PUSH TAGS ---"
# Ensures all local tags (if any) are pushed/overwritten
git push --force --tags
```

If `push --force-with-lease` fails with 'stale info', immediately re-run the fetch and the force-with-lease.
If it continues to fail, use the unconditional push:
`git push --force --all`

4\. Remote Verification
-----------------------------

The final verification must be done on a clean environment and directly on the remote service.

### **Manual Step 4: Verify on Remote**

1.  **Browse to the repository** on GitHub, GitLab, or Bitbucket.

2.  **Bypass Cache:** Use a browser **Incognito/Private window** or perform a **hard refresh** (Ctrl+Shift+R or Cmd+Shift+R).

3.  **Inspect Commit List:**

    -   Go to the **Commits** tab/view.
    -   Use the commit search filter and search for the **`EMAIL_BAD`** and **`NAME_BAD`**.
    -   **Result:** The search should return **0 results**.

4.  **Inspect a Known-Bad Commit:**

    -   Find a commit that was historically done by the bad user (it will have a new SHA).
    -   Click on the commit and verify the Author and Committer fields both show **`Your Correct Name <correct@email.com>`**.

### **Manual Step 5: Final Local Check (Optional but Recommended)**

Clone the repository to a new, clean directory and run the scanner again.

1.  Navigate back to the parent directory: `cd ..`
2.  Clone the repository: `git clone <REMOTE_URL> clean-repo-test`
3.  Navigate into the test clone: `cd clean-repo-test`
4.  Run the following commands, which search copious output:

    ```bash
    git log --all --pretty=raw | grep -q -i "$EMAIL_BAD" || echo "✅ Clean clone."
    git log --all --pretty=raw | grep -q -i "$NAME_BAD" || echo "✅ Clean clone."
    ```
5. Clean up a working repo dir

If working locally on a clone in a temp dir like REPO_CLEANUP, the usual working directory will be out of sync. Depending on repo size, it might be easier to start with a fresh clone. Else these commands should bring it into agreement with the new remote history. These steps need to be performed on all branches.

```bash
    git fetch origin
    git reset --hard origin/main
    git reflog expire --expire=now --all
```
