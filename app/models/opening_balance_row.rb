class OpeningBalanceRow < ApplicationRecord
  belongs_to :opening_balance_import
  belongs_to :employee, optional: true

  def computed_total = legal_days + progressive_days + administrative_days
  def difference = excel_total.nil? ? 0 : (excel_total - computed_total)
  def message_list = messages.to_s.split("\n")
end
