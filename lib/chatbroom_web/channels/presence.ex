defmodule ChatbroomWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](https://phoenix.hexdocs.pm/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence,
    otp_app: :chatbroom,
    pubsub_server: Chatbroom.PubSub
end
