# frozen_string_literal: true

json.id tag.id
json.name tag.name
json.color tag.color

# Transaction count
json.transaction_count tag.transactions.count

# Additional metadata
json.created_at tag.created_at.iso8601
json.updated_at tag.updated_at.iso8601