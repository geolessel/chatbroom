defmodule ChatbroomWeb.RoomChannelTest do
  use ChatbroomWeb.ChannelCase, async: true

  alias ChatbroomWeb.{Presence, RoomChannel, UserSocket}

  setup do
    topic = "room:#{System.unique_integer([:positive])}"

    {:ok, _, socket} =
      UserSocket
      |> socket(nil, %{user: "brave-otter"})
      |> subscribe_and_join(RoomChannel, topic)

    %{socket: socket, topic: topic}
  end

  test "joining pushes the presence state and tracks the user", %{topic: topic} do
    assert_push "presence_state", %{}
    assert_push "presence_diff", %{joins: %{"brave-otter" => _}}
    assert Map.has_key?(Presence.list(topic), "brave-otter")
  end

  test "new_message broadcasts the message from the socket's user", %{socket: socket} do
    ref = push(socket, "new_message", %{"message" => "hello"})

    assert_reply ref, :ok
    assert_broadcast "new_message", %{user: "brave-otter", message: "hello"}
  end

  test "new_message ignores a user name sent by the client", %{socket: socket} do
    push(socket, "new_message", %{"message" => "hi", "user" => "impostor"})

    assert_broadcast "new_message", %{user: "brave-otter"}
  end

  test "new_message refuses a blank message", %{socket: socket} do
    ref = push(socket, "new_message", %{"message" => "   "})

    assert_reply ref, :error, %{reason: "empty message"}
    refute_broadcast "new_message", _
  end

  test "new_message refuses a payload without a string message", %{socket: socket} do
    ref = push(socket, "new_message", %{"message" => 42})

    assert_reply ref, :error, %{reason: "empty message"}
    refute_broadcast "new_message", _
  end

  describe "message telemetry" do
    setup do
      ref = :telemetry_test.attach_event_handlers(self(), [[:chatbroom, :message, :sent]])
      on_exit(fn -> :telemetry.detach(ref) end)
      %{ref: ref}
    end

    test "a sent message emits a sent event", %{socket: socket, ref: ref} do
      push(socket, "new_message", %{"message" => "hello"}) |> assert_reply(:ok)

      assert_received {[:chatbroom, :message, :sent], ^ref, %{count: 1}, %{}}
    end

    test "a refused message emits no event", %{socket: socket, ref: ref} do
      push(socket, "new_message", %{"message" => ""}) |> assert_reply(:error)

      refute_received {[:chatbroom, :message, :sent], ^ref, _, _}
    end

    test "LiveDashboard metrics count sent messages" do
      assert Enum.any?(
               ChatbroomWeb.Telemetry.metrics(),
               &(&1.event_name == [:chatbroom, :message, :sent])
             )
    end
  end
end
