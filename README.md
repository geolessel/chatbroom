# Chatbroom

Anonymous, throwaway chat rooms. There are no accounts, no pre-created
rooms, and no database:

- Visit `/rooms/anything-you-like` and you are in a room with that name.
  Anyone who visits the same URL joins you.
- `/rooms` sends you to a room with a random three-word name.
- Every page load gives you a random two-word user name.
- Messages go straight to whoever is connected. Nothing is stored, so a
  page refresh clears the chat.

This app is also a small, complete example of **Phoenix Channels used
directly, without LiveView**: a plain socket, a channel, Presence, and a
framework-free JavaScript client with no npm dependencies.

## How it works

| Step | Where |
| --- | --- |
| The controller picks a random user name, signs it with `Phoenix.Token`, and renders static markup with the room, user, and token in `data-` attributes. | `lib/chatbroom_web/controllers/room_controller.ex`, `room_html/show.html.heex` |
| The client connects to `/socket` with the token. The socket verifies the token and assigns the user, so a client cannot choose its own name. | `assets/js/chat.js`, `lib/chatbroom_web/channels/user_socket.ex` |
| The client joins the `room:<name>` topic. Any topic is valid; a room exists while someone is in it. | `lib/chatbroom_web/channels/room_channel.ex` |
| On join, the channel pushes the current `presence_state` and tracks the user. The client's `Presence` instance keeps the user list and shows join/leave notices. | `room_channel.ex`, `lib/chatbroom_web/channels/presence.ex` |
| `new_message` is broadcast to the topic with the user name from the socket, never from the payload. | `room_channel.ex` |

The `phoenix` JavaScript client is resolved from `deps/phoenix` by
esbuild (see `NODE_PATH` in `config/config.exs`), so there is no
`package.json`.

## Running it

Versions are pinned in `.tool-versions` (for mise or asdf).

```sh
mix setup        # deps, plus the esbuild and tailwind binaries
mix phx.server   # or: iex -S mix phx.server
```

Then visit [`localhost:4000`](http://localhost:4000).

### When esbuild can't be downloaded

`mix setup` downloads esbuild from the npm registry. If that is not
possible, install esbuild yourself and point `MIX_ESBUILD_PATH` at it,
for example in an `.envrc` (ignored by git) for direnv:

```sh
npm install -g esbuild
echo 'export MIX_ESBUILD_PATH="$(which esbuild)"' >> .envrc
```

## Metrics

Each sent message emits a `[:chatbroom, :message, :sent]` telemetry
event. In development, the count is on the "Chatbroom" tab of
[LiveDashboard's metrics page](http://localhost:4000/dev/dashboard/metrics?nav=chatbroom).

## Tests

```sh
mix test         # or `mix precommit` to also check warnings and formatting
```

## History

Chatbroom first ran in 2018 as a Phoenix 1.3 app with a React chat UI.
This repository is an update of that eight-year-old codebase: the same
behaviour and look, rewritten on current Elixir and Phoenix. It is also
the first time the code has been public; the original repository was
private.

## License

MIT. See [LICENSE](LICENSE).
