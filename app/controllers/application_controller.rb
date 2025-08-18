# frozen_string_literal: true

class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods
  
  private

  def authenticate_store!
    unless store_signed_in?
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

  def store_signed_in?
    current_store.present?
  end

  def current_store
    @current_store ||= authenticate_with_http_token do |token, options|
      Store.find_by(authentication_token: token)
    end
  end
end
