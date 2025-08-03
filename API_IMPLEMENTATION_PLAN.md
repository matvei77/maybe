# Maybe Finance API Implementation Plan - Safe Addition Strategy

## Overview
This document outlines the plan to add new API endpoints to Maybe Finance WITHOUT modifying any existing functionality. All changes are additive only.

## Core Principles
1. **CREATE NEW FILES ONLY** - Never modify existing files except routes.rb (additive only)
2. **COPY EXISTING PATTERNS** - Follow TransactionsController patterns exactly
3. **USE EXISTING MODELS** - No model changes, use what's already there
4. **NO MIGRATIONS** - Database already has everything we need
5. **INHERIT PROPERLY** - All new controllers inherit from `Api::V1::BaseController`

## New Files to Create

### Controllers
```
app/controllers/api/v1/
├── categories_controller.rb     (NEW)
├── tags_controller.rb          (NEW)
├── merchants_controller.rb     (NEW)
├── transfers_controller.rb     (NEW)
└── budgets_controller.rb       (NEW)
```

### Views (Jbuilder)
```
app/views/api/v1/
├── categories/
│   ├── index.json.jbuilder    (NEW)
│   ├── show.json.jbuilder     (NEW)
│   └── _category.json.jbuilder (NEW)
├── tags/
│   ├── index.json.jbuilder    (NEW)
│   ├── show.json.jbuilder     (NEW)
│   └── _tag.json.jbuilder     (NEW)
├── merchants/
│   ├── index.json.jbuilder    (NEW)
│   ├── show.json.jbuilder     (NEW)
│   └── _merchant.json.jbuilder (NEW)
├── transfers/
│   ├── index.json.jbuilder    (NEW)
│   ├── show.json.jbuilder     (NEW)
│   └── _transfer.json.jbuilder (NEW)
└── budgets/
    ├── index.json.jbuilder     (NEW)
    ├── show.json.jbuilder      (NEW)
    └── _budget.json.jbuilder   (NEW)
```

## Routes Addition (config/routes.rb)

Add these lines inside `namespace :api do namespace :v1 do` block:

```ruby
# Categories API
resources :categories, only: [:index, :show, :create, :update, :destroy] do
  post :bootstrap, on: :collection
end

# Tags API
resources :tags, only: [:index, :show, :create, :update, :destroy]

# Merchants API (family merchants only)
resources :merchants, only: [:index, :show, :create, :update, :destroy]

# Transfers API
resources :transfers, only: [:index, :show, :create, :update, :destroy] do
  member do
    post :confirm
    post :reject
  end
end

# Budgets API (special param format)
resources :budgets, only: [:index, :show, :create, :update], param: :month_year do
  resources :budget_categories, only: [:index, :update]
end
```

## Controller Implementation Patterns

### Base Pattern (All Controllers)
```ruby
class Api::V1::ResourceController < Api::V1::BaseController
  include Pagy::Backend
  
  # Scope authorization
  before_action :ensure_read_scope, only: [:index, :show]
  before_action :ensure_write_scope, only: [:create, :update, :destroy]
  before_action :set_resource, only: [:show, :update, :destroy]
  
  # Error handling
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  
  private
  
  def ensure_read_scope
    authorize_scope!(:read)
  end
  
  def ensure_write_scope
    authorize_scope!(:write)
  end
  
  def set_resource
    @resource = current_resource_owner.family.resources.find(params[:id])
  end
end
```

### Categories Specific Considerations
- Handle parent/subcategory relationships
- Validate classification matches parent
- Max 2 levels of nesting
- Color inheritance from parent
- Bootstrap default categories endpoint

### Tags Specific Considerations
- Simple flat structure
- Many-to-many with transactions
- Name uniqueness within family

### Merchants Specific Considerations
- Only handle FamilyMerchant type
- Cannot modify ProviderMerchant
- Filter by type in queries

### Transfers Specific Considerations
- Use Transfer::Creator service
- Handle two linked transactions
- Status workflow (pending/confirmed)
- Different transfer types

### Budgets Specific Considerations
- Special param format (jan-2024)
- Use Budget.param_to_date helper
- Auto-create budget categories
- Handle budget calculations

## JSON Response Formats

### Success Response
```json
{
  "data": {
    // resource data
  },
  "meta": {
    "pagination": {
      "page": 1,
      "per_page": 25,
      "total_count": 100,
      "total_pages": 4
    }
  }
}
```

### Error Response
```json
{
  "error": "validation_failed",
  "message": "Human readable message",
  "details": {
    "field": ["error message"]
  }
}
```

## Security Patterns

### Family Scoping (CRITICAL)
```ruby
# ALWAYS use:
current_resource_owner.family.resources

# NEVER use:
Resource.find(params[:id])
```

### Strong Parameters
```ruby
def category_params
  params.require(:category).permit(:name, :color, :parent_id, :classification, :lucide_icon)
end

def tag_params
  params.require(:tag).permit(:name, :color)
end

def merchant_params
  params.require(:merchant).permit(:name, :color)
end

def transfer_params
  params.require(:transfer).permit(:from_account_id, :to_account_id, :amount, :date, :notes)
end

def budget_params
  params.require(:budget).permit(:budgeted_spending, :expected_income)
end
```

## Testing Commands

### Categories
```bash
# List categories
curl -X GET http://localhost:4000/api/v1/categories \
  -H "X-Api-Key: YOUR_KEY"

# Create category
curl -X POST http://localhost:4000/api/v1/categories \
  -H "X-Api-Key: YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"category": {"name": "Groceries", "color": "#e99537", "classification": "expense"}}'

# Update transaction with category
curl -X PATCH http://localhost:4000/api/v1/transactions/TRANSACTION_ID \
  -H "X-Api-Key: YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"transaction": {"category_id": "CATEGORY_ID"}}'
```

### Tags
```bash
# List tags
curl -X GET http://localhost:4000/api/v1/tags \
  -H "X-Api-Key: YOUR_KEY"

# Create tag
curl -X POST http://localhost:4000/api/v1/tags \
  -H "X-Api-Key: YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"tag": {"name": "Tax Deductible", "color": "#4da568"}}'
```

## Implementation Timeline

- **Day 1-2**: Categories API (PRIORITY - needed for MCP)
- **Day 3**: Tags API
- **Day 4**: Merchants API
- **Day 5-6**: Transfers API
- **Day 7-8**: Budgets API
- **Day 9-10**: Testing & Documentation

## Verification Checklist

- [ ] Existing API endpoints still work
- [ ] New endpoints follow authentication patterns
- [ ] Family scoping enforced on all queries
- [ ] Error responses match existing format
- [ ] Pagination works consistently
- [ ] No N+1 queries (use includes)
- [ ] All actions logged properly
- [ ] Rate limiting applies to new endpoints

## Common Pitfalls to Avoid

1. **Direct Model Access**: Always scope through family
2. **Missing Includes**: Prevent N+1 queries
3. **Type Issues**: FamilyMerchant vs ProviderMerchant
4. **Parent Validation**: Categories must validate hierarchy
5. **Transaction Safety**: Use database transactions for complex operations

## MCP Integration Requirements

For the MCP to work properly, these are the minimum requirements:

1. **Categories API**: 
   - GET /api/v1/categories (returns id, name, classification)
   - POST /api/v1/categories (create new categories)

2. **Transaction Categorization**:
   - PATCH /api/v1/transactions/:id with category_id

3. **Tags API**:
   - GET /api/v1/tags (returns id, name)
   - POST /api/v1/tags (create new tags)

4. **Merchants API**:
   - GET /api/v1/merchants (returns id, name)
   - POST /api/v1/merchants (create new merchants)

## Notes

- This plan ensures NO breaking changes to existing functionality
- All new code is isolated in new files
- Follows existing patterns from TransactionsController
- Uses existing authentication and scoping mechanisms
- Maintains backward compatibility