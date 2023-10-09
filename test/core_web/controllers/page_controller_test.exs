defmodule CoreWeb.PageControllerTest do
  use CoreWeb.ConnCase

  alias Core.Expectations

  test "GET /", %{conn: conn} do
    Expectations.expect_get_random_posts()

    conn = get(conn, ~p"/")
    assert html_response(conn, 200)
  end
end
