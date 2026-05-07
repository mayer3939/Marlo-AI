#!/bin/bash
# Validate Phase Report Structure
# Checks that a phase report file has required fields and valid YAML frontmatter

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ $# -eq 0 ]; then
    echo "Usage: validate-phase-report.sh <path-to-phase-report.md>"
    echo ""
    echo "Validates that a phase report has:"
    echo "  - Valid YAML frontmatter (---...---)"
    echo "  - Required fields: phase, title, status, timestamp"
    echo "  - Status is one of: done, needs_input, blocked"
    exit 1
fi

report_path="$1"

if [ ! -f "$report_path" ]; then
    echo -e "${RED}Error: File not found: $report_path${NC}"
    exit 1
fi

echo "Validating: $report_path"
echo ""

# Check for frontmatter
if ! grep -q "^---$" "$report_path"; then
    echo -e "${RED}✗ Missing frontmatter delimiters (---)${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Frontmatter present"

# Extract frontmatter
frontmatter=$(sed -n '/^---$/,/^---$/p' "$report_path" | head -n -1 | tail -n +2)

# Check required fields
required_fields=("phase" "title" "status" "timestamp")
for field in "${required_fields[@]}"; do
    if echo "$frontmatter" | grep -q "^$field:"; then
        value=$(echo "$frontmatter" | grep "^$field:" | head -1 | cut -d: -f2- | xargs)
        echo -e "${GREEN}✓${NC} $field: $value"
    else
        echo -e "${RED}✗ Missing required field: $field${NC}"
        exit 1
    fi
done

# Validate status
status=$(echo "$frontmatter" | grep "^status:" | cut -d: -f2- | xargs)
if [[ "$status" =~ ^(done|needs_input|blocked)$ ]]; then
    echo -e "${GREEN}✓${NC} status is valid: $status"
else
    echo -e "${RED}✗ Invalid status: $status (must be one of: done, needs_input, blocked)${NC}"
    exit 1
fi

# Check for content after frontmatter
if ! tail -n +5 "$report_path" | grep -q .; then
    echo -e "${YELLOW}⚠${NC} Report has no content after frontmatter (consider adding summary)"
fi

echo ""
echo -e "${GREEN}Validation passed!${NC}"
