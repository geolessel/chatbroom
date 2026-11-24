defmodule ChatbroomWeb.RoomChannel do
  @moduledoc """
  One channel process for each browser tab in a room.

  Rooms are not created ahead of time: any `room:<name>` topic is a room,
  and it exists while somebody is connected to it. Messages go straight
  to the connected clients and are never stored.
  """
  use ChatbroomWeb, :channel

  alias ChatbroomWeb.Presence

  @impl true
  def join("room:" <> _room, _params, socket) do
    send(self(), :after_join)
    {:ok, socket}
  end

  @impl true
  def handle_in("new_message", %{"message" => message}, socket) when is_binary(message) do
    case String.trim(message) do
      "" ->
        {:reply, {:error, %{reason: "empty message"}}, socket}

      message ->
        broadcast!(socket, "new_message", %{user: socket.assigns.user, message: message})
        {:reply, :ok, socket}
    end
  end

  def handle_in("new_message", _payload, socket) do
    {:reply, {:error, %{reason: "empty message"}}, socket}
  end

  # Tracking must happen after join/3 returns, because the channel cannot
  # push to the client until the join reply goes out.
  @impl true
  def handle_info(:after_join, socket) do
    push(socket, "presence_state", Presence.list(socket))

    {:ok, _ref} =
      Presence.track(socket, socket.assigns.user, %{
        online_at: System.system_time(:second)
      })

    {:noreply, socket}
  end
end
