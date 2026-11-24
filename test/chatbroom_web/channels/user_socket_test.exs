defmodule ChatbroomWeb.UserSocketTest do
  use ChatbroomWeb.ChannelCase, async: true

  alias ChatbroomWeb.UserSocket

  test "connect assigns the user from a valid token" do
    token = UserSocket.sign_user(@endpoint, "brave-otter")

    assert {:ok, socket} = connect(UserSocket, %{"token" => token})
    assert socket.assigns.user == "brave-otter"
  end

  test "connect refuses a token that was not signed by the server" do
    assert {:error, :invalid_token} = connect(UserSocket, %{"token" => "forged"})
  end

  test "connect refuses a missing token" do
    assert {:error, :invalid_token} = connect(UserSocket, %{"user" => "brave-otter"})
  end
end
