defmodule ChatbroomWeb.RoomHTML do
  @moduledoc """
  The chat room page. The server renders the static markup only;
  `assets/js/chat.ts` connects to the room channel and fills it in.
  """
  use ChatbroomWeb, :html

  embed_templates "room_html/*"
end
