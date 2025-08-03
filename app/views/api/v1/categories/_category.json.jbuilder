# frozen_string_literal: true

json.id category.id
json.name category.name
json.color category.color
json.classification category.classification
json.lucide_icon category.lucide_icon

# Parent category information
if category.parent.present?
  json.parent do
    json.id category.parent.id
    json.name category.parent.name
    json.color category.parent.color
    json.classification category.parent.classification
  end
else
  json.parent nil
end

# Subcategories
json.subcategories category.subcategories do |subcategory|
  json.id subcategory.id
  json.name subcategory.name
  json.color subcategory.color
  json.classification subcategory.classification
  json.lucide_icon subcategory.lucide_icon
end

# Additional metadata
json.created_at category.created_at.iso8601
json.updated_at category.updated_at.iso8601