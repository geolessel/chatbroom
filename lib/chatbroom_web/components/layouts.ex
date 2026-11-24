defmodule ChatbroomWeb.Layouts do
  @moduledoc """
  Layouts for the application: the HTML skeleton in `root.html.heex`
  and the navbar-and-footer page frame in `app/1`.
  """
  use ChatbroomWeb, :html

  embed_templates "layouts/*"

  @doc """
  Renders the page frame: a fixed navbar, the page content filling the
  remaining height, and the footer.

  ## Examples

      <Layouts.app>
        <h1>Content</h1>
      </Layouts.app>

  """
  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <nav class="fixed inset-x-0 top-0 z-10 flex h-[54px] items-center gap-4 bg-[#343a40] px-4">
      <a href={~p"/"} class="text-xl text-white">ChatBroom</a>
      <a href={~p"/rooms"} class="text-white/50 hover:text-white/75">New Room</a>
    </nav>

    <div class="mt-[54px] flex h-[calc(100vh-54px)] flex-col">
      <main class="flex min-h-0 flex-1 flex-col overflow-y-auto">
        {render_slot(@inner_block)}
      </main>

      <footer class="p-4 text-center text-[0.8em] [font-variant:all-small-caps]">
        Created by <a href="https://geoffreylessel.com" class={link_class()}>Geoffrey Lessel</a>
        (<a href="https://twitter.com/geolessel" class={link_class()}>@geolessel</a>)
      </footer>
    </div>
    """
  end

  @doc "Classes for an inline text link, styled as in Bootstrap 4."
  def link_class, do: "text-[#007bff] hover:text-[#0056b3] hover:underline"
end
