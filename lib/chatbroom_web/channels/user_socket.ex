defmodule ChatbroomWeb.UserSocket do
  @moduledoc """
  The socket that browser clients connect to at `/socket`.

  Chatbroom has no accounts. The server picks a random user name when it
  renders a room page and signs that name with `sign_user/2`. The client
  sends the signed token back when it connects, so a client cannot choose
  its own name.
  """
  use Phoenix.Socket

  channel "room:*", ChatbroomWeb.RoomChannel

  @salt "user socket"
  @max_age 86_400

  @doc "Signs a user name so that `connect/3` can trust it later."
  def sign_user(endpoint_or_conn, user), do: Phoenix.Token.sign(endpoint_or_conn, @salt, user)

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case Phoenix.Token.verify(socket, @salt, token, max_age: @max_age) do
      {:ok, user} -> {:ok, assign(socket, :user, user)}
      {:error, _reason} -> {:error, :invalid_token}
    end
  end

  def connect(_params, _socket, _connect_info), do: {:error, :invalid_token}

  @impl true
  def id(_socket), do: nil
end
