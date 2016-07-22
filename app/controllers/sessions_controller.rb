class SessionsController < ApplicationController
  def create
    user = FacebookSessionHandler.new(request.env["omniauth.auth"].credentials.token)
    user = user.find || user.create
    session[:user_id] = user.id
    redirect_to root_url
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_url
  end
end
