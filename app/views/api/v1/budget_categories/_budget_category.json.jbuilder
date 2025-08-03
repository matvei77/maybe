# frozen_string_literal: true

json.id budget_category.id
json.budgeted_spending budget_category.budgeted_spending
json.actual_spending budget_category.actual_spending
json.available_to_spend budget_category.available_to_spend
json.percent_of_budget_spent budget_category.percent_of_budget_spent
json.avg_monthly_expense budget_category.avg_monthly_expense
json.median_monthly_expense budget_category.median_monthly_expense

# Category information
json.category do
  json.id budget_category.category.id
  json.name budget_category.category.name
  json.color budget_category.category.color
  json.classification budget_category.category.classification
  json.parent_id budget_category.category.parent_id
end

# Additional metadata
json.created_at budget_category.created_at.iso8601
json.updated_at budget_category.updated_at.iso8601