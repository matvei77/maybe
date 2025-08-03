# frozen_string_literal: true

json.id merchant.id
json.name merchant.name
json.color merchant.color
json.type merchant.type

# Transaction count
json.transaction_count merchant.transactions.count

# Additional metadata
json.created_at merchant.created_at.iso8601
json.updated_at merchant.updated_at.iso8601