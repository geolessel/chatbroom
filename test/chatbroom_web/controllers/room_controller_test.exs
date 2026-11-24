defmodule ChatbroomWeb.RoomControllerTest do
  use ChatbroomWeb.ConnCase, async: true

  require Phoenix.ChannelTest

  alias ChatbroomWeb.UserSocket

  test "GET /rooms redirects to a random three-word room", %{conn: conn} do
    conn = get(conn, ~p"/rooms")

    assert "/rooms/" <> room = redirected_to(conn)
    assert room =~ ~r/^[a-z]+-[a-z]+-[a-z]+$/
  end

  describe "GET /rooms/:id" do
    test "renders the room with a random two-word user", %{conn: conn} do
      html = conn |> get(~p"/rooms/secret-hideout") |> html_response(200)

      assert [room] = attribute(html, "#chat", "data-room")
      assert room == "secret-hideout"

      assert [user] = attribute(html, "#chat", "data-user")
      assert user =~ ~r/^[a-z]+-[a-z]+$/
    end

    test "renders a socket token that verifies as the shown user", %{conn: conn} do
      html = conn |> get(~p"/rooms/secret-hideout") |> html_response(200)

      [user] = attribute(html, "#chat", "data-user")
      [token] = attribute(html, "#chat", "data-token")

      assert {:ok, socket} = Phoenix.ChannelTest.connect(UserSocket, %{"token" => token})
      assert socket.assigns.user == user
    end

    test "escapes the room name", %{conn: conn} do
      html = conn |> get(~p"/rooms/#{"<script>x</script>"}") |> html_response(200)

      refute html =~ "<script>x</script>"
    end
  end

  defp attribute(html, selector, name) do
    html
    |> LazyHTML.from_document()
    |> LazyHTML.query(selector)
    |> LazyHTML.attribute(name)
  end
end
