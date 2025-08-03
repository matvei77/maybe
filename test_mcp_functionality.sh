#!/bin/bash

# Test script for MCP critical functionality: Transaction categorization
API_KEY="d214f0fb6565d8be7c438fd27d4810868d75131c4ea7f288924b7defddd6310a"
BASE_URL="https://maybe.lapushinskii.com/api/v1"

echo "Testing Maybe Finance MCP Critical Functionality"
echo "================================================"
echo "This test verifies that we can:"
echo "1. Fetch categories"
echo "2. Create categories if needed"
echo "3. Update transaction categories (CRITICAL for MCP)"
echo ""

# Test 1: Check if categories endpoint exists
echo "Test 1: Checking if Categories API endpoint exists..."
CATEGORIES_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X GET "$BASE_URL/categories" \
  -H "X-Api-Key: $API_KEY" \
  -H "Accept: application/json")

HTTP_STATUS=$(echo "$CATEGORIES_RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)
RESPONSE_BODY=$(echo "$CATEGORIES_RESPONSE" | sed -n '1,/HTTP_STATUS:/p' | sed '$d')

echo "Response Status: $HTTP_STATUS"
if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ Categories API is accessible!"
    echo "Response preview: $(echo "$RESPONSE_BODY" | head -c 200)..."
else
    echo "❌ Categories API returned status $HTTP_STATUS"
    echo "Response: $RESPONSE_BODY"
fi

# Test 2: Get a transaction to test with
echo -e "\nTest 2: Getting a transaction to test categorization..."
TRANSACTIONS_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X GET "$BASE_URL/transactions?per_page=1" \
  -H "X-Api-Key: $API_KEY" \
  -H "Accept: application/json")

HTTP_STATUS=$(echo "$TRANSACTIONS_RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)
RESPONSE_BODY=$(echo "$TRANSACTIONS_RESPONSE" | sed -n '1,/HTTP_STATUS:/p' | sed '$d')

if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ Transactions API is accessible!"
    # Try to extract transaction ID (basic parsing without jq)
    TRANSACTION_ID=$(echo "$RESPONSE_BODY" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    echo "First transaction ID: $TRANSACTION_ID"
else
    echo "❌ Transactions API returned status $HTTP_STATUS"
fi

# Test 3: Try to create a test category
echo -e "\nTest 3: Creating a test category..."
CREATE_CATEGORY_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "$BASE_URL/categories" \
  -H "X-Api-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"category": {"name": "MCP Test Category", "color": "#e99537", "classification": "expense", "lucide_icon": "test"}}')

HTTP_STATUS=$(echo "$CREATE_CATEGORY_RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)
RESPONSE_BODY=$(echo "$CREATE_CATEGORY_RESPONSE" | sed -n '1,/HTTP_STATUS:/p' | sed '$d')

if [ "$HTTP_STATUS" = "201" ] || [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ Category creation successful!"
    # Try to extract category ID
    CATEGORY_ID=$(echo "$RESPONSE_BODY" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    echo "Created category ID: $CATEGORY_ID"
else
    echo "❌ Category creation returned status $HTTP_STATUS"
    echo "Response: $RESPONSE_BODY"
fi

# Test 4: The CRITICAL test - Update transaction with category
if [ ! -z "$TRANSACTION_ID" ] && [ ! -z "$CATEGORY_ID" ]; then
    echo -e "\nTest 4: CRITICAL TEST - Updating transaction with category..."
    echo "Transaction ID: $TRANSACTION_ID"
    echo "Category ID: $CATEGORY_ID"
    
    UPDATE_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X PATCH "$BASE_URL/transactions/$TRANSACTION_ID" \
      -H "X-Api-Key: $API_KEY" \
      -H "Content-Type: application/json" \
      -H "Accept: application/json" \
      -d "{\"transaction\": {\"category_id\": \"$CATEGORY_ID\"}}")
    
    HTTP_STATUS=$(echo "$UPDATE_RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)
    RESPONSE_BODY=$(echo "$UPDATE_RESPONSE" | sed -n '1,/HTTP_STATUS:/p' | sed '$d')
    
    if [ "$HTTP_STATUS" = "200" ]; then
        echo "✅ Transaction update successful!"
        echo "Response preview: $(echo "$RESPONSE_BODY" | head -c 200)..."
        
        # Verify the category was saved
        echo -e "\nVerifying category was saved..."
        VERIFY_RESPONSE=$(curl -s -X GET "$BASE_URL/transactions/$TRANSACTION_ID" \
          -H "X-Api-Key: $API_KEY" \
          -H "Accept: application/json")
        
        if echo "$VERIFY_RESPONSE" | grep -q "\"category_id\":\"$CATEGORY_ID\"" || echo "$VERIFY_RESPONSE" | grep -q "\"id\":\"$CATEGORY_ID\""; then
            echo "✅ VERIFIED: Category was successfully saved to transaction!"
        else
            echo "⚠️  Category might not have been saved. Check response:"
            echo "$VERIFY_RESPONSE" | head -c 500
        fi
    else
        echo "❌ Transaction update failed with status $HTTP_STATUS"
        echo "Response: $RESPONSE_BODY"
    fi
else
    echo -e "\nTest 4: SKIPPED - Need both transaction ID and category ID"
fi

# Test 5: Test other endpoints
echo -e "\nTest 5: Testing Tags API..."
TAGS_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X GET "$BASE_URL/tags" \
  -H "X-Api-Key: $API_KEY" \
  -H "Accept: application/json")

HTTP_STATUS=$(echo "$TAGS_RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)
if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ Tags API is accessible!"
else
    echo "❌ Tags API returned status $HTTP_STATUS"
fi

echo -e "\nTest 6: Testing Merchants API..."
MERCHANTS_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X GET "$BASE_URL/merchants" \
  -H "X-Api-Key: $API_KEY" \
  -H "Accept: application/json")

HTTP_STATUS=$(echo "$MERCHANTS_RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)
if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ Merchants API is accessible!"
else
    echo "❌ Merchants API returned status $HTTP_STATUS"
fi

echo -e "\n================================================"
echo "Test Summary:"
echo "- The CRITICAL test is #4: updating a transaction with a category"
echo "- This is what the MCP needs to work properly"
echo "- If test #4 passed, the MCP integration should work!"