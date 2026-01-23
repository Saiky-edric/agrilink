#!/bin/bash
# Simple script to add overflow handling to Text widgets
# This is a safer, more conservative approach

echo "🔧 Adding overflow handling to Text widgets..."

# Find all Text widgets without overflow
# This will generate a report first

cd "$(dirname "$0")/.."

echo "📊 Scanning for Text widgets without overflow..."

# Count Text widgets without overflow
COUNT=$(find lib -name "*.dart" -exec grep -h "Text(" {} \; | grep -v "overflow:" | grep -v "maxLines:" | wc -l)

echo "Found approximately $COUNT Text widgets that might need overflow handling"
echo ""
echo "⚠️  Manual review recommended for:"
echo "  - Button labels (usually don't need overflow)"
echo "  - Short static text (may not need overflow)"
echo "  - Already constrained widgets"
echo ""
echo "✅ Should definitely add overflow to:"
echo "  - Product names"
echo "  - User-generated content"
echo "  - Addresses"
echo "  - Descriptions"
echo "  - Long dynamic text"
echo ""
echo "📝 Generating detailed report..."

# Create report file
REPORT_FILE="overflow_fix_report.txt"

echo "Overflow Fix Report - $(date)" > $REPORT_FILE
echo "================================" >> $REPORT_FILE
echo "" >> $REPORT_FILE

# Find files with Text widgets
find lib -name "*.dart" | while read file; do
  # Check if file has Text widgets without overflow
  if grep -q "Text(" "$file"; then
    COUNT=$(grep "Text(" "$file" | grep -v "overflow:" | grep -v "maxLines:" | wc -l)
    if [ $COUNT -gt 0 ]; then
      echo "File: $file" >> $REPORT_FILE
      echo "  Text widgets needing overflow: $COUNT" >> $REPORT_FILE
      grep -n "Text(" "$file" | grep -v "overflow:" | grep -v "maxLines:" | head -5 >> $REPORT_FILE
      echo "" >> $REPORT_FILE
    fi
  fi
done

echo "✅ Report generated: $REPORT_FILE"
echo ""
echo "Next steps:"
echo "1. Review the report"
echo "2. Manually add overflow to critical Text widgets"
echo "3. Focus on user-facing dynamic content first"
