#!/bin/bash

# Test script for new API endpoints
# This script tests that the new endpoints are accessible and don't break existing ones

API_KEY="YOUR_API_KEY_HERE"
BASE_URL="http://localhost:4000/api/v1"

echo "Testing Maybe Finance API endpoints..."
echo "======================================="

# Test existing endpoints still work
echo -e "\n1. Testing existing /accounts endpoint (should still work):"
curl -s -X GET "$BASE_URL/accounts" \
  -H "X-Api-Key: $API_KEY" \
  -H "Accept: application/json" | jq . || echo "Failed"

echo -e "\n2. Testing existing /transactions endpoint (should still work):"
curl -s -X GET "$BASE_URL/transactions" \
  -H "X-Api-Key: $API_KEY" \
  -H "Accept: application/json" | jq . || echo "Failed"

# Test new endpoints
echo -e "\n3. Testing new /categories endpoint:"
curl -s -X GET "$BASE_URL/categories" \
  -H "X-Api-Key: $API_KEY" \
  -H "Accept: application/json" | jq . || echo "Failed"

echo -e "\n4. Testing new /tags endpoint:"
curl -s -X GET "$BASE_URL/tags" \
  -H "X-Api-Key: $API_KEY" \
  -H "Accept: application/json" | jq . || echo "Failed"

echo -e "\n5. Testing new /merchants endpoint:"
curl -s -X GET "$BASE_URL/merchants" \
  -H "X-Api-Key: $API_KEY" \
  -H "Accept: application/json" | jq . || echo "Failed"

echo -e "\n6. Testing new /transfers endpoint:"
curl -s -X GET "$BASE_URL/transfers" \
  -H "X-Api-Key: $API_KEY" \
  -H "Accept: application/json" | jq . || echo "Failed"

echo -e "\n7. Testing new /budgets endpoint:"
curl -s -X GET "$BASE_URL/budgets" \
  -H "X-Api-Key: $API_KEY" \
  -H "Accept: application/json" | jq . || echo "Failed"

# Test creating a category
echo -e "\n8. Testing category creation:"
curl -s -X POST "$BASE_URL/categories" \
  -H "X-Api-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"category": {"name": "Test Category", "color": "#e99537", "classification": "expense"}}' | jq . || echo "Failed"

# Test creating a tag
echo -e "\n9. Testing tag creation:"
curl -s -X POST "$BASE_URL/tags" \
  -H "X-Api-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"tag": {"name": "Test Tag", "color": "#4da568"}}' | jq . || echo "Failed"

echo -e "\n======================================="
echo "API endpoint testing complete!"
echo ""
echo "NOTE: Replace YOUR_API_KEY_HERE with a valid API key before running this script."
echo "To get an API key, log into Maybe Finance and go to Settings > API Keys."