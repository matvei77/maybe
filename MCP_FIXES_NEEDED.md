# Maybe MCP Fixes Needed

The Maybe MCP needs several fixes to work with the newly added API endpoints:

## 1. CategorySchema Fix

The current CategorySchema expects:
```typescript
{
  id: string,
  familyId: string,
  name: string,
  color: string,
  isSystem: boolean,
  createdAt: string,
  updatedAt: string
}
```

But the actual API returns:
```json
{
  "id": "335d3d7f-aeb4-4e46-be4b-fd9df772f49d",
  "name": "Entertainment",
  "color": "#df4e92",
  "classification": "expense",
  "lucide_icon": "drama",
  "parent": null,
  "subcategories": [],
  "created_at": "2025-08-01T17:57:38Z",
  "updated_at": "2025-08-01T17:57:38Z"
}
```

## 2. getCategories() Implementation

Currently returns hardcoded categories. Needs to:
```typescript
async getCategories() {
  const data = await this.client.get<any>('/categories');
  // The response has a "categories" array
  return data.categories;
}
```

## 3. Transaction Categorization

Currently uses:
```typescript
updateTransaction(id, { category: params.category })
```

Should use:
```typescript
updateTransaction(id, { category_id: params.categoryId })
```

## 4. HTTP Method for Updates

The API uses PATCH for updates, not PUT:
```typescript
// Change from:
await this.client.put<any>(`/transactions/${id}`, { transaction: data });

// To:
await this.client.patch<any>(`/transactions/${id}`, { transaction: data });
```

## 5. Response Structure

All API responses follow this pattern:
```json
{
  "categories": [...],
  "pagination": { ... }
}
```

Not just an array.

## Summary

Without these fixes, the MCP will:
- ❌ Not be able to fetch real categories
- ❌ Not be able to categorize transactions (wrong field name)
- ❌ Not be able to update transactions (wrong HTTP method)
- ✅ Can still fetch transactions (this works)

The critical functionality for categorization is broken until these fixes are applied.