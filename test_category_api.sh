#!/bin/bash

# Test script for Categories API and transaction categorization
API_KEY="d214f0fb6565d8be7c438fd27d4810868d75131c4ea7f288924b7defddd6310a"
BASE_URL="http://localhost:4000/api/v1"

echo "Testing Maybe Finance Categories API..."
echo "======================================="

# 1. First, let's get existing transactions
echo -e "\n1. Getting existing transactions:"
TRANSACTIONS=$(curl -s -X GET "$BASE_URL/transactions?per_page=5" \
  -H "X-Api-Key: $API_KEY" \
  -H "Accept: application/json")

echo "$TRANSACTIONS" | jq '.transactions[] | {id, name, amount, category}' || echo "Failed to get transactions"

# Get the first transaction ID
TRANSACTION_ID=$(echo "$TRANSACTIONS" | jq -r '.transactions[0].id' 2>/dev/null)
echo -e "\nFirst transaction ID: $TRANSACTION_ID"

# 2. Get existing categories
echo -e "\n2. Getting existing categories:"
CATEGORIES=$(curl -s -X GET "$BASE_URL/categories" \
  -H "X-Api-Key: $API_KEY" \
  -H "Accept: application/json")

echo "$CATEGORIES" | jq '.categories[] | {id, name, classification}' || echo "Failed to get categories"

# Check if we have categories, if not, bootstrap them
CATEGORY_COUNT=$(echo "$CATEGORIES" | jq '.categories | length' 2>/dev/null || echo "0")
if [ "$CATEGORY_COUNT" = "0" ] || [ -z "$CATEGORY_COUNT" ]; then
    echo -e "\n3. No categories found. Bootstrapping default categories:"
    curl -s -X POST "$BASE_URL/categories/bootstrap" \
      -H "X-Api-Key: $API_KEY" \
      -H "Accept: application/json" | jq '.categories[] | {id, name, classification}' || echo "Failed to bootstrap"
    
    # Get categories again
    CATEGORIES=$(curl -s -X GET "$BASE_URL/categories" \
      -H "X-Api-Key: $API_KEY" \
      -H "Accept: application/json")
fi

# Get a category ID (prefer "Food & Drink" or first expense category)
CATEGORY_ID=$(echo "$CATEGORIES" | jq -r '.categories[] | select(.name == "Food & Drink") | .id' 2>/dev/null)
if [ -z "$CATEGORY_ID" ] || [ "$CATEGORY_ID" = "null" ]; then
    CATEGORY_ID=$(echo "$CATEGORIES" | jq -r '.categories[] | select(.classification == "expense") | .id' | head -1)
fi
echo -e "\nSelected category ID: $CATEGORY_ID"

# 3. Create a new category
echo -e "\n4. Creating a new category:"
NEW_CATEGORY=$(curl -s -X POST "$BASE_URL/categories" \
  -H "X-Api-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"category": {"name": "MCP Test Category", "color": "#e99537", "classification": "expense", "lucide_icon": "test"}}')

echo "$NEW_CATEGORY" | jq '.' || echo "Failed to create category"
NEW_CATEGORY_ID=$(echo "$NEW_CATEGORY" | jq -r '.id' 2>/dev/null)

# 4. Update transaction with category (THE CRITICAL TEST)
if [ ! -z "$TRANSACTION_ID" ] && [ "$TRANSACTION_ID" != "null" ] && [ ! -z "$CATEGORY_ID" ] && [ "$CATEGORY_ID" != "null" ]; then
    echo -e "\n5. CRITICAL TEST - Updating transaction $TRANSACTION_ID with category $CATEGORY_ID:"
    UPDATE_RESULT=$(curl -s -X PATCH "$BASE_URL/transactions/$TRANSACTION_ID" \
      -H "X-Api-Key: $API_KEY" \
      -H "Content-Type: application/json" \
      -H "Accept: application/json" \
      -d "{\"transaction\": {\"category_id\": \"$CATEGORY_ID\"}}")
    
    echo "$UPDATE_RESULT" | jq '{id, name, amount, category}' || echo "Failed to update transaction"
    
    # Verify the update
    echo -e "\n6. Verifying the category was saved:"
    curl -s -X GET "$BASE_URL/transactions/$TRANSACTION_ID" \
      -H "X-Api-Key: $API_KEY" \
      -H "Accept: application/json" | jq '{id, name, amount, category}' || echo "Failed to verify"
else
    echo -e "\n5. Cannot test transaction update - missing transaction or category ID"
fi

# 5. Test Tags API
echo -e "\n7. Testing Tags API - Creating a tag:"
NEW_TAG=$(curl -s -X POST "$BASE_URL/tags" \
  -H "X-Api-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"tag": {"name": "MCP Test Tag", "color": "#4da568"}}')

echo "$NEW_TAG" | jq '.' || echo "Failed to create tag"

# 6. List all tags
echo -e "\n8. Listing all tags:"
curl -s -X GET "$BASE_URL/tags" \
  -H "X-Api-Key: $API_KEY" \
  -H "Accept: application/json" | jq '.tags[] | {id, name, color}' || echo "Failed to list tags"

# 7. Test Merchants API
echo -e "\n9. Testing Merchants API - Creating a merchant:"
NEW_MERCHANT=$(curl -s -X POST "$BASE_URL/merchants" \
  -H "X-Api-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"merchant": {"name": "MCP Test Merchant"}}')

echo "$NEW_MERCHANT" | jq '.' || echo "Failed to create merchant"

# 8. List all merchants
echo -e "\n10. Listing all merchants:"
curl -s -X GET "$BASE_URL/merchants" \
  -H "X-Api-Key: $API_KEY" \
  -H "Accept: application/json" | jq '.merchants[] | {id, name, type}' || echo "Failed to list merchants"

echo -e "\n======================================="
echo "Testing complete!"
echo ""
echo "KEY RESULT: Check if step 5/6 successfully updated the transaction category."
echo "This is the critical functionality needed for the MCP integration."