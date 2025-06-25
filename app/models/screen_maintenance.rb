class ScreenMaintenance < ApplicationRecord
  belongs_to :screen_inventory,
             class_name: 'ScreenInventory',
             foreign_key: 'screen_inventory_id'


  validates :maintenance_start_date, :maintenance_end_date, presence: true
  validate  :end_must_be_on_or_after_start

  private

  def end_must_be_on_or_after_start
    return if maintenance_end_date >= maintenance_start_date
    errors.add(:maintenance_end_date, "must be on or after start date")
  end
end
