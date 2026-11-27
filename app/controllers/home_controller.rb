class HomeController < ApplicationController
  def index
    if current_actor.hr?
      redirect_to employees_path
    elsif current_actor.manager?
      redirect_to team_path
    else
      redirect_to my_balance_path
    end
  end
end
