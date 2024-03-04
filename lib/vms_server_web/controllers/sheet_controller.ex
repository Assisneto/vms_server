defmodule VmsServerWeb.SheetController do
  use VmsServerWeb, :controller

  def get_characteristics_fields(conn, %{"race_id" => race_id}) do
    case VmsServer.Sheet.get_characteristics_fields(race_id) do
      [] -> handle_response([], conn, :characteristics_fields, :no_content)
      characteristics -> handle_response(characteristics, conn, :characteristics_fields, :ok)
    end
  end

  defp handle_response(response, conn, view, status),
    do:
      conn
      |> put_status(status)
      |> render(view, fields: response)
end