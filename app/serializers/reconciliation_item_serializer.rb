# frozen_string_literal: true

class ReconciliationItemSerializer < ActiveModel::Serializer
  attributes :id, :match_status, :amount_difference, :match_rule_applied, 
             :source_info, :target_info, :notes_parsed

  def source_info
    return nil unless object.source
    
    {
      type: object.source_type,
      id: object.source_id,
      details: source_details
    }
  end

  def target_info
    return nil unless object.target
    
    {
      type: object.target_type,
      id: object.target_id,
      details: target_details
    }
  end

  def notes_parsed
    return nil if object.notes.blank?
    JSON.parse(object.notes) rescue object.notes
  end

  private

  def source_details
    case object.source_type
    when 'Sale'
      {
        sale_number: object.source.sale_number,
        amount: object.source.total_amount,
        date: object.source.sale_date,
        customer: object.source.customer&.name
      }
    when 'Transaction'
      {
        reference: object.source.reference,
        amount: object.source.amount,
        date: object.source.transaction_date,
        type: object.source.transaction_type,
        customer: object.source.customer&.name
      }
    when 'Wallet'
      {
        wallet_type: object.source.wallet_type,
        balance: object.source.balance,
        owner: object.source.owner&.name
      }
    else
      {}
    end
  end

  def target_details
    case object.target_type
    when 'Sale'
      {
        sale_number: object.target.sale_number,
        amount: object.target.total_amount,
        date: object.target.sale_date,
        customer: object.target.customer&.name
      }
    when 'Transaction'
      {
        reference: object.target.reference,
        amount: object.target.amount,
        date: object.target.transaction_date,
        type: object.target.transaction_type,
        customer: object.target.customer&.name
      }
    else
      {}
    end
  end
end