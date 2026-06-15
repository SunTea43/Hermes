class Payment < ApplicationRecord
  belongs_to :sales_order
  belongs_to :recorded_by, class_name: "User", optional: true
end
