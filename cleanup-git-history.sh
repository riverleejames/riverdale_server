#!/bin/bash
# Script to remove sensitive data from Git history
# This will rewrite Git history to replace the sensitive GitLab token

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${RED}⚠️  WARNING: This will rewrite Git history!${NC}"
echo ""
echo "This script will:"
echo "1. Replace the GitLab token in all commits"
echo "2. Force push to remote (if you choose)"
echo ""
echo -e "${YELLOW}Before proceeding:${NC}"
echo "- Make sure you have a backup"
echo "- Inform collaborators (they'll need to re-clone)"
echo "- This operation cannot be easily undone"
echo ""
read -p "Do you want to continue? (yes/no): " confirm

if [[ "$confirm" != "yes" ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo -e "${YELLOW}Step 1: Committing current changes to .env.example${NC}"
git add .env.example
git commit -m "Remove sensitive GitLab token from .env.example" || echo "No changes to commit"

echo ""
echo -e "${YELLOW}Step 2: Rewriting Git history${NC}"
echo "This may take a few moments..."

# Use git filter-branch to replace the sensitive token in all commits
git filter-branch --force --index-filter \
  'git ls-files -s | \
   sed "s/glrt-JmQ7AhBZ-W0_ga1af3SNY286MQpwOjE5NDFiNQp0OjMKdTpnNGNmchg.01.1j1i31u9c/your-registration-token-here/g" | \
   GIT_INDEX_FILE=$GIT_INDEX_FILE.new git update-index --index-info && \
   if [ -f "$GIT_INDEX_FILE.new" ]; then mv "$GIT_INDEX_FILE.new" "$GIT_INDEX_FILE"; fi' \
  --msg-filter 'cat' \
  --tag-name-filter cat \
  -- --all

echo ""
echo -e "${GREEN}✓ Git history rewritten${NC}"
echo ""
echo -e "${YELLOW}Step 3: Cleanup${NC}"
# Remove backup refs
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo ""
echo -e "${GREEN}✓ Cleanup complete${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review the changes: git log --all --oneline -- .env.example"
echo "2. Force push to remote: git push origin --force --all"
echo "3. Force push tags: git push origin --force --tags"
echo ""
echo -e "${RED}⚠️  IMPORTANT:${NC}"
echo "All collaborators will need to:"
echo "  git fetch origin"
echo "  git reset --hard origin/main"
echo "Or simply re-clone the repository"
echo ""
read -p "Do you want to force push to remote now? (yes/no): " push_confirm

if [[ "$push_confirm" == "yes" ]]; then
    echo ""
    echo -e "${YELLOW}Force pushing to remote...${NC}"
    git push origin --force --all
    git push origin --force --tags
    echo -e "${GREEN}✓ Force push complete${NC}"
else
    echo ""
    echo "Skipped force push. You can do it later with:"
    echo "  git push origin --force --all"
    echo "  git push origin --force --tags"
fi

echo ""
echo -e "${GREEN}Done!${NC}"
