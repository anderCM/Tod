# frozen_string_literal: true

class ReconciliationDetailSerializer < ReconciliationSerializer
  has_many :matched_items, serializer: ReconciliationItemSerializer
  has_many :unmatched_items, serializer: ReconciliationItemSerializer
  has_many :disputed_items, serializer: ReconciliationItemSerializer

  attributes :store_name, :initiated_by

  def store_name
    object.store&.name
  end

  def matched_items
    object.reconciliation_items.matched
  end

  def unmatched_items
    object.reconciliation_items.unmatched
  end

  def disputed_items
    object.reconciliation_items.disputed
  end
end