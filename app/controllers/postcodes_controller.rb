class PostcodesController < ApplicationController
  rescue_from StandardError, with: :internal_error

  def check
    checker = ::PostcodeChecker.new(params[:postcode])

    if checker.allowed?
      redirect_back(fallback_location: root_path, notice: "Postcode #{params[:postcode]} is allowed.")
    else
      redirect_back(fallback_location: root_path, alert: "Postcode #{params[:postcode]} isn't allowed.")
    end
  end

  private

  def internal_error(exception)
    Rails.logger.error "Runtime error: #{exception.message}"
    redirect_back(fallback_location: root_path, alert: 'Internal Error. Please try later.')
  end
end
