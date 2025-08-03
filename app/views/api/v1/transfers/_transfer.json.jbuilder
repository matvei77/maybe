# frozen_string_literal: true

json.id transfer.id
json.status transfer.status
json.date transfer.date
json.amount transfer.amount_abs.format
json.currency transfer.inflow_transaction.entry.currency
json.name transfer.name
json.transfer_type transfer.transfer_type
json.categorizable transfer.categorizable?

# From account (source)
json.from_account do
  json.id transfer.from_account.id
  json.name transfer.from_account.name
  json.account_type transfer.from_account.accountable_type.underscore
end

# To account (destination)
json.to_account do
  json.id transfer.to_account.id
  json.name transfer.to_account.name
  json.account_type transfer.to_account.accountable_type.underscore
end

# Associated transactions
json.inflow_transaction do
  json.id transfer.inflow_transaction.id
  json.amount transfer.inflow_transaction.entry.amount_money.format
end

json.outflow_transaction do
  json.id transfer.outflow_transaction.id
  json.amount transfer.outflow_transaction.entry.amount_money.format
  
  # Category (if categorizable)
  if transfer.categorizable? && transfer.outflow_transaction.category.present?
    json.category do
      json.id transfer.outflow_transaction.category.id
      json.name transfer.outflow_transaction.category.name
    end
  else
    json.category nil
  end
end

# Additional metadata
json.created_at transfer.created_at.iso8601
json.updated_at transfer.updated_at.iso8601