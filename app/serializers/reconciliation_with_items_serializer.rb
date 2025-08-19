# frozen_string_literal: true

class ReconciliationWithItemsSerializer < ActiveModel::Serializer
  attributes :id, :status, :reconciliation_type, :period, :totals, :completed_at, :items_summary

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

  def items_summary
    {
      matched_items: serialize_items(object.reconciliation_items.matched),
      unmatched_items: serialize_items(object.reconciliation_items.unmatched),
      disputed_items: serialize_items(object.reconciliation_items.disputed)
    }
  end

  private

  def calculate_success_rate
    total = (object.total_matched || 0) + (object.total_unmatched || 0)
    return 0 if total.zero?
    
    ((object.total_matched.to_f / total) * 100).round(2)
  end

  def serialize_items(items)
    items.map do |item|
      {
        id: item.id,
        match_status: item.match_status,
        amount_difference: item.amount_difference,
        match_rule_applied: item.match_rule_applied,
        source_info: source_info(item),
        target_info: target_info(item)
      }
    end
  end

  def source_info(item)
    return nil unless item.source
    
    case item.source_type
    when 'Sale'
      {
        type: 'Sale',
        sale_number: item.source.sale_number,
        amount: item.source.total_amount,
        customer: item.source.customer&.name
      }
    when 'Transaction'
      {
        type: 'Transaction',
        reference: item.source.reference,
        amount: item.source.amount,
        customer: item.source.customer&.name
      }
    else
      { type: item.source_type }
    end
  end

  def target_info(item)
    return nil unless item.target

    case item.target_type
    when 'Sale'
      {
        type: 'Sale',
        sale_number: item.target.sale_number,
        amount: item.target.total_amount,
        customer: item.target.customer&.name
      }
    when 'Transaction'
      {
        type: 'Transaction',
        reference: item.target.reference,
        amount: item.target.amount,
        customer: item.target.customer&.name
      }
    else
      { type: item.target_type }
    end
  end
end
