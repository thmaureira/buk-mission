class HomeController < ApplicationController
  def index
    if current_actor.hr?
      redirect_to employees_path
    else
      render html: "Las vistas de jefatura y colaborador llegan en un PR siguiente.", layout: true
    end
  end
end
