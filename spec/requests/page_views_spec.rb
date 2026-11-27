require "rails_helper"

RSpec.describe "Métricas de uso", type: :request do
  let(:company) { create(:company) }
  let!(:types) { setup_types(company) }
  let!(:hr) { create(:employee, company: company, role: "hr") }
  let!(:worker) { create(:employee, company: company) }

  it "registra cada página vista con el mismo visitante entre solicitudes" do
    expect { get "/employees" }.to change(PageView, :count).by(1)
    get "/employees/#{worker.id}"

    first, second = PageView.order(:id).last(2)
    expect(first).to have_attributes(request_method: "GET", path: "/employees", controller_action: "employees#index",
                                     status: 200, actor: hr, actor_role: "hr", external: false)
    expect(second.visitor_id).to eq(first.visitor_id)
  end

  it "cuenta las acciones y marca las visitas que llegan por ngrok" do
    host! "abc.ngrok-free.app"
    patch "/session", params: { actor_id: worker.id }
    get "/mi-saldo"

    action, visit = PageView.order(:id).last(2)
    expect(action).to have_attributes(request_method: "PATCH", controller_action: "sessions#update", status: 302,
                                      external: true)
    expect(visit).to have_attributes(actor: worker, external: true)
  end

  it "muestra los totales a RRHH" do
    get "/employees"
    get "/metricas"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Visitantes únicos")
  end
end
