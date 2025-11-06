#!/bin/bash
# Script to remove sensitive data from Git history using sed
# This is a simpler alternative that uses git filter-branch

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${RED}⚠️  WARNING: This will rewrite Git history!${NC}"
echo ""
echo "This script will replace sensitive data in .env.example across all Git history"
echo ""
echo -e "${YELLOW}Sensitive data to be replaced:${NC}"
echo "- GitLab Runner Token: glrt-JmQ7AhBZ-W0_ga1af3SNY286MQpwOjE5NDFiNQp0OjMKdTpnNGNmchg.01.1j1i31u9c"
echo ""
echo -e "${YELLOW}Before proceeding:${NC}"
echo "- ✓ Backup your repository"
echo "- ✓ Inform any collaborators"
echo "- ✓ Understand this rewrites history (force push needed)"
echo ""
read -p "Type 'YES' to continue: " confirm

if [[ "$confirm" != "YES" ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo -e "${YELLOW}Step 1: Committing current cleaned .env.example${NC}"
git add .env.example
git commit -m "Remove sensitive tokens from .env.example" || echo "Already committed or no changes"

echo ""
echo -e "${YELLOW}Step 2: Creating temporary script for filtering${NC}"
cat > /tmp/filter-sensitive-data.sh << 'FILTERSCRIPT'
#!/bin/bash
# Temporary filter script
git ls-files -z .env.example | while IFS= read -r -d '' file; do
    if [ -f "$file" ]; then
        # Replace the GitLab token
        sed -i 's/glrt-JmQ7AhBZ-W0_ga1af3SNY286MQpwOjE5NDFiNQp0OjMKdTpnNGNmchg\.01\.1j1i31u9c/your-registration-token-here/g' "$file"
        git add "$file"
    fi
done
FILTERSCRIPT

chmod +x /tmp/filter-sensitive-data.sh

echo ""
echo -e "${YELLOW}Step 3: Rewriting Git history (this may take a while)${NC}"

# Use git filter-branch with tree-filter
git filter-branch --force --tree-filter '/tmp/filter-sensitive-data.sh' --tag-name-filter cat -- --all

echo ""
echo -e "${GREEN}✓ Git history rewritten${NC}"

echo ""
echo -e "${YELLOW}Step 4: Cleaning up${NC}"
# Clean up
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now --aggressive
rm /tmp/filter-sensitive-data.sh

echo ""
echo -e "${GREEN}✓ Cleanup complete!${NC}"
echo ""
echo -e "${YELLOW}Verification:${NC}"
echo "Check if the token still exists in history:"
git log --all -S 'glrt-JmQ7AhBZ-W0_ga1af3SNY286MQpwOjE5NDFiNQp0OjMKdTpnNGNmchg' -- .env.example

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Verify the changes look correct"
echo "2. Force push to remote:"
echo "   ${GREEN}git push origin --force --all${NC}"
echo "   ${GREEN}git push origin --force --tags${NC}"
echo ""
echo -e "${RED}⚠️  All collaborators must re-clone or reset their local repos!${NC}"
