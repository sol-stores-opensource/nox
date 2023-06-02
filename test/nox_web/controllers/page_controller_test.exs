defmodule NoxWeb.PageControllerTest do
  use NoxWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "In dev go to"
  end
end
