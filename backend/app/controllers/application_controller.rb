class ApplicationController < ActionController::API
  before_action :authenticate_request, except: [:login, :signup]

  private

  def authenticate_request
    header = request.headers['Authorization']
    if header
      header = header.split(' ').last if header.include?(' ')
      decoded = JsonWebToken.decode(header)
      if decoded
        @current_user = User.find(decoded[:user_id])
      else
        render json: { errors: 'Invalid token' }, status: :unauthorized
      end
    else
      render json: { errors: 'Missing token' }, status: :unauthorized
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: { errors: e.message }, status: :unauthorized
  end

  def current_user
    @current_user
  end
end

