class OrderScreenRequirementSerializer < ActiveModel::Serializer
  attributes :id, :sqm_required, :dimensions_rows, :dimensions_columns, :screen_inventory_id

  # Optional: include basic screen type info
  belongs_to :screen_inventory
end
