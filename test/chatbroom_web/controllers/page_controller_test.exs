defmodule ChatbroomWeb.PageControllerTest do
  use ChatbroomWeb.ConnCase, async: true

  test "GET / explains how rooms work", %{conn: conn} do
    html = conn |> get(~p"/") |> html_response(200)

    assert html =~ "Welcome to Chatbroom!"
    assert html =~ "No history will be saved"
    assert html =~ ~s(href="/rooms/whatever-you-like")
  end

  test "GET / links to a random room from the page and the navbar", %{conn: conn} do
    html = conn |> get(~p"/") |> html_response(200)

    assert html =~ "Create a random room"
    assert html =~ "New Room"
    assert html =~ ~s(href="/rooms")
  end

  test "the layout credits the author", %{conn: conn} do
    html = conn |> get(~p"/") |> html_response(200)

    assert html =~ "Geoffrey Lessel"
    assert html =~ ~s(href="https://geoffreylessel.com")
    assert html =~ ~s(href="https://twitter.com/geolessel")
  end
end
