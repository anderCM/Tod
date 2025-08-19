# frozen_string_literal: true

class ReconciliationSerializer < ActiveModel::Serializer
  attributes :id, :status, :reconciliation_type, :period, :totals, :completed_at

  def period
    {
      start_date: object.start_date,
      end_date: object.end_date
    }
  end

  def totals
    {
      matched: object.total_matched || 0,
      unmatched: object.total_unmatched || 0,
      amount_matched: object.total_amount_matched || 0,
      amount_unmatched: object.total_amount_unmatched || 0,
      success_rate: calculate_success_rate
    }
  end

  private

  def calculate_success_rate
    total = (object.total_matched || 0) + (object.total_unmatched || 0)
    return 0 if total.zero?
    
    ((object.total_matched.to_f / total) * 100).round(2)
  end
end