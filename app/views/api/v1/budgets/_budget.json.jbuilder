# frozen_string_literal: true

json.month_year budget.to_param
json.name budget.name
json.start_date budget.start_date
json.end_date budget.end_date
json.currency budget.currency
json.current budget.current?
json.initialized budget.initialized?

# Budget amounts
json.budgeted_spending budget.budgeted_spending
json.expected_income budget.expected_income
json.allocated_spending budget.allocated_spending
json.available_to_allocate budget.available_to_allocate
json.allocations_valid budget.allocations_valid?

# Actual amounts
json.actual_spending budget.actual_spending
json.actual_income budget.actual_income
json.available_to_spend budget.available_to_spend

# Percentages
json.percent_of_budget_spent budget.percent_of_budget_spent
json.overage_percent budget.overage_percent
json.allocated_percent budget.allocated_percent
json.actual_income_percent budget.actual_income_percent
json.surplus_percent budget.surplus_percent

# Navigation
json.previous_budget_param budget.previous_budget_param
json.next_budget_param budget.next_budget_param

# Additional metadata
json.created_at budget.created_at.iso8601
json.updated_at budget.updated_at.iso8601