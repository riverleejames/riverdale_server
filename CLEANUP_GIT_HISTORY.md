# Remove Sensitive Data from Git History

Your `.env.example` file contains a sensitive GitLab Runner token that needs to be removed from Git history.

## Quick Summary

The sensitive token has been removed from the current version of `.env.example`, but it still exists in Git history. You need to rewrite history to completely remove it.

## Option 1: Using the Cleanup Script (Recommended)

```bash
# Run the automated cleanup script
./scripts/cleanup-git-history.sh
```

This script will:
1. Commit the cleaned `.env.example`
2. Rewrite Git history to replace the token
3. Clean up Git references
4. Prompt you to force push

## Option 2: Manual Cleanup

### Step 1: Commit Current Changes

```bash
git add .env.example
git commit -m "Remove sensitive tokens from .env.example"
```

### Step 2: Search for the Token in History

```bash
# Verify the token exists in history
git log --all -S 'glrt-JmQ7AhBZ' -- .env.example
```

### Step 3: Rewrite History

**Method A: Using git filter-branch (built-in)**

```bash
git filter-branch --force --tree-filter '
  if [ -f .env.example ]; then
    sed -i "s/glrt-JmQ7AhBZ-W0_ga1af3SNY286MQpwOjE5NDFiNQp0OjMKdTpnNGNmchg\.01\.1j1i31u9c/your-registration-token-here/g" .env.example
  fi
' --tag-name-filter cat -- --all
```

**Method B: Using BFG Repo-Cleaner (faster, requires installation)**

1. Install BFG:
   ```bash
   # Download from https://rtyley.github.io/bfg-repo-cleaner/
   wget https://repo1.maven.org/maven2/com/madgag/bfg/1.14.0/bfg-1.14.0.jar
   ```

2. Create a replacements file:
   ```bash
   echo "glrt-JmQ7AhBZ-W0_ga1af3SNY286MQpwOjE5NDFiNQp0OjMKdTpnNGNmchg.01.1j1i31u9c==>your-registration-token-here" > replacements.txt
   ```

3. Run BFG:
   ```bash
   java -jar bfg-1.14.0.jar --replace-text replacements.txt
   ```

### Step 4: Cleanup

```bash
# Remove backup refs
rm -rf .git/refs/original/

# Expire reflog
git reflog expire --expire=now --all

# Garbage collect
git gc --prune=now --aggressive
```

### Step 5: Verify

```bash
# This should return no results
git log --all -S 'glrt-JmQ7AhBZ' -- .env.example
```

### Step 6: Force Push to Remote

⚠️ **WARNING:** This will rewrite remote history!

```bash
# Force push all branches
git push origin --force --all

# Force push all tags
git push origin --force --tags
```

## Option 3: Simple Alternative - Remove File from History Completely

If you want to completely remove `.env.example` from history and start fresh:

```bash
# Remove the file from all history
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch .env.example' \
  --prune-empty --tag-name-filter cat -- --all

# Cleanup
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Add it back
git add .env.example
git commit -m "Re-add .env.example without sensitive data"

# Force push
git push origin --force --all
git push origin --force --tags
```

## Important Notes

### After Rewriting History

All collaborators will need to:

```bash
# Option 1: Re-clone the repository
git clone <repository-url>

# Option 2: Reset their local copy
git fetch origin
git reset --hard origin/main
```

### Invalidate the Token

Even after removing from Git history, you should:

1. **Revoke the GitLab Runner token** in GitLab:
   - Go to GitLab > Settings > CI/CD > Runners
   - Unregister or delete the runner
   - Create a new registration token

2. **Update your runner** with the new token:
   ```bash
   docker exec gitlab-runner gitlab-runner unregister --all-runners
   # Then register with new token
   ```

### Check GitHub/GitLab Mirrors

If your repository is mirrored elsewhere:
- Force push to all remotes
- Check GitHub/GitLab web interface to verify

### Alternative: Make Repository Private

If the token exposure is limited and recent:
- Make the repository private (if it's public)
- Revoke the exposed token
- Continue with a fresh token

## Verify Token is Gone

After cleanup, verify across all history:

```bash
# Search entire history for the token
git log --all --full-history --source --all -S 'glrt-JmQ7AhBZ'

# Search all file contents in history
git grep 'glrt-JmQ7AhBZ' $(git rev-list --all)
```

If these return no results, you're clean! ✅

## Need Help?

Run the automated script for the easiest approach:
```bash
./scripts/cleanup-git-history.sh
```
