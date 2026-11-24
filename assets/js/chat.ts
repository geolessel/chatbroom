import {Presence, Socket} from "phoenix"

type ChatMessage = {user: string; message: string}

export function startChat(root: HTMLElement): void {
  const {room, token} = root.dataset
  const messages = root.querySelector<HTMLElement>("#messages")!
  const form = root.querySelector<HTMLFormElement>("#message-form")!
  const input = root.querySelector<HTMLInputElement>("#message-input")!
  const showUsers = root.querySelector<HTMLInputElement>("#show-user-list")!
  const userList = root.querySelector<HTMLElement>("#user-list")!
  const users = root.querySelector<HTMLElement>("#users")!
  const userCount = root.querySelector<HTMLElement>("#user-count")!

  const socket = new Socket("/socket", {params: {token}})
  socket.connect()

  const channel = socket.channel(`room:${room}`)
  const presence = new Presence(channel)

  // The first sync lists everyone already in the room. Only later
  // changes are announced, so a new arrival does not see "joined"
  // for every person who was there before them.
  let announce = false

  presence.onJoin((name: string, current: unknown) => {
    if (announce && !current) appendNotice(messages, `${name} joined`)
  })

  presence.onLeave((name: string, current: {metas: unknown[]}) => {
    if (announce && current.metas.length === 0) appendNotice(messages, `${name} left`)
  })

  presence.onSync(() => {
    announce = true
    const names: string[] = presence.list((name: string) => name)
    userCount.textContent = String(names.length)
    users.replaceChildren(...names.map(name => element("span", {}, name)))
  })

  channel.on("new_message", ({user, message}: ChatMessage) => {
    appendLine(messages, element("div", {class: "flex"},
      element("strong", {class: "pr-2"}, `${user}:`),
      element("div", {}, message),
    ))
  })

  channel.join()
    .receive("ok", () => console.log(`Joined ${room}`))
    .receive("error", (resp: unknown) => console.log("Unable to join", resp))

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

function appendNotice(messages: HTMLElement, text: string): void {
  appendLine(messages, element("div", {class: "italic text-[#6c757d]"}, text))
}

function appendLine(messages: HTMLElement, line: HTMLElement): void {
  const atBottom = messages.scrollHeight - messages.scrollTop - messages.clientHeight < 20
  messages.append(line)
  if (atBottom) messages.scrollTop = messages.scrollHeight
}

// Text goes in through text nodes, never innerHTML, because messages
// and room names come from other users.
function element(tag: string, attrs: Record<string, string>, ...children: (Node | string)[]): HTMLElement {
  const el = document.createElement(tag)
  for (const [name, value] of Object.entries(attrs)) el.setAttribute(name, value)
  el.append(...children)
  return el
}
