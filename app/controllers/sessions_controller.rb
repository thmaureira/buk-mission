class SessionsController < ApplicationController
  def update
    session[:actor_id] = Employee.find(params[:actor_id]).id
    redirect_to root_path
  end
end
