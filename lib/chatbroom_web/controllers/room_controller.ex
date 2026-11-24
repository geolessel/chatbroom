defmodule ChatbroomWeb.RoomController do
  use ChatbroomWeb, :controller

  alias ChatbroomWeb.UserSocket

  def new(conn, _params) do
    redirect(conn, to: ~p"/rooms/#{MnemonicSlugs.generate_slug(3)}")
  end

  def show(conn, %{"id" => room}) do
    user = MnemonicSlugs.generate_slug(2)

    render(conn, :show,
      page_title: room,
      room: room,
      user: user,
      token: UserSocket.sign_user(conn, user)
    )
  end
end
