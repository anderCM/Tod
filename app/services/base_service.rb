# frozen_string_literal: true

class BaseService
  attr_reader :errors, :valid

  def call
    raise NotImplementedError, "#{self.class} must implement #call"
  end

  # Retrieves validation status of the service
  def valid?
    @valid
  end

  private

  # Sets the service status as true
  def set_as_valid!
    @valid = true
  end

  # Sets the service status as false
  def set_as_invalid!
    @valid = false
  end

  # Sets an error message to service
  #
  # @params error [String] - The error message to set
  #
  # @return [void]
  def set_error_message(error)
    @errors = { message: error }
  end
end