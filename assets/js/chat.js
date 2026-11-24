import {Presence, Socket} from "phoenix"

export function startChat(root) {
  const {room, token} = root.dataset
  const messages = root.querySelector("#messages")
  const form = root.querySelector("#message-form")
  const input = root.querySelector("#message-input")
  const showUsers = root.querySelector("#show-user-list")
  const userList = root.querySelector("#user-list")
  const users = root.querySelector("#users")
  const userCount = root.querySelector("#user-count")

  const socket = new Socket("/socket", {params: {token}})
  socket.connect()

  const channel = socket.channel(`room:${room}`)
  const presence = new Presence(channel)

  // The first sync lists everyone already in the room. Only later
  // changes are announced, so a new arrival does not see "joined"
  // for every person who was there before them.
  let announce = false

  presence.onJoin((name, current) => {
    if (announce && !current) appendNotice(messages, `${name} joined`)
  })

  presence.onLeave((name, current) => {
    if (announce && current.metas.length === 0) appendNotice(messages, `${name} left`)
  })

  presence.onSync(() => {
    announce = true
    const names = presence.list(name => name)
    userCount.textContent = String(names.length)
    users.replaceChildren(...names.map(name => element("span", {}, name)))
  })

  channel.on("new_message", ({user, message}) => {
    appendLine(messages, element("div", {class: "flex"},
      element("strong", {class: "pr-2"}, `${user}:`),
      element("div", {}, message),
    ))
  })

  channel.join()
    .receive("ok", () => console.log(`Joined ${room}`))
    .receive("error", resp => console.log("Unable to join", resp))

  form.addEventListener("submit", event => {
    event.preventDefault()
    if (input.value.trim() === "") return

    channel.push("new_message", {message: input.value})
    input.value = ""
  })

  showUsers.addEventListener("change", () => {
    userList.hidden = !showUsers.checked
  })
}

function appendNotice(messages, text) {
  appendLine(messages, element("div", {class: "italic text-[#6c757d]"}, text))
}

function appendLine(messages, line) {
  const atBottom = messages.scrollHeight - messages.scrollTop - messages.clientHeight < 20
  messages.append(line)
  if (atBottom) messages.scrollTop = messages.scrollHeight
}

// Text goes in through text nodes, never innerHTML, because messages
// and room names come from other users.
function element(tag, attrs, ...children) {
  const el = document.createElement(tag)
  for (const [name, value] of Object.entries(attrs)) el.setAttribute(name, value)
  el.append(...children)
  return el
}
