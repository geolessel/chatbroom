This is a Phoenix web application: anonymous, throwaway chat rooms with no
accounts and no database. It is also meant to be read as an **example of
Phoenix Channels used without LiveView**, so keep it small and keep the
channel code easy to follow. See `README.md` for how the pieces fit together.

## Project guidelines

- Use `mix precommit` alias when you are done with all changes and fix any pending issues
- Write tests first. Channel tests use `ChatbroomWeb.ChannelCase` (`Phoenix.ChannelTest`); page tests use `ChatbroomWeb.ConnCase`
- Nothing is persisted. Do not add a database, message history, or any server-side storage of messages
- This app makes no outbound HTTP requests and has no HTTP client dependency. Do not add one without a reason

### Architecture

- Pages are plain controllers with HEEx templates (`PageController`, `RoomController`). **Do not** add LiveViews or a `LiveSocket` for app pages. LiveView is a dependency only because LiveDashboard needs it
- Real-time behaviour lives in `ChatbroomWeb.UserSocket` (mounted at `/socket`), `ChatbroomWeb.RoomChannel` (`room:*`), and `ChatbroomWeb.Presence`
- The user name is chosen by the server, signed with `UserSocket.sign_user/2`, and verified in `UserSocket.connect/3`. **Always** read the user from `socket.assigns.user`. **Never** trust a user name from channel params or message payloads
- Validate every `handle_in` payload on the server, even when the client also validates it
- Room names are user input with no limit. **Never** use them as atoms, metric tags, or telemetry metadata

### Templates and layout

- Templates are wrapped in `<Layouts.app>`, which renders the fixed navbar, the full-height `main`, and the footer. It takes no `flash` or `current_scope` assign
- There are no core components (`<.input>`, `<.button>`, `<.icon>`, `<.flash>` etc. do not exist). Write plain HTML elements styled with Tailwind
- `Layouts.link_class/0` gives the standard inline link style

### JS and CSS guidelines

- The client is **plain JavaScript** in `assets/js/` (`app.js` is the entry, `chat.js` holds the chat client). Do not convert it to TypeScript and do not add a framework
- There is **no `package.json` and no npm**. esbuild resolves `phoenix` from `deps/` via `NODE_PATH` in `config/config.exs`
- Build DOM with `document.createElement` and text nodes. **Never** use `innerHTML` or similar with messages, user names, or room names, since they come from other users
- **Never write inline <script>custom js</script> tags within templates**. Data for the client goes in `data-` attributes
- If the esbuild download is not possible, set `MIX_ESBUILD_PATH` to a locally installed esbuild (for example in the git-ignored `.envrc`)
- Tailwind CSS v4 has **no tailwind.config.js** and uses this import syntax in `app.css`. **Always use and maintain it**:

      @import "tailwindcss" source(none);
      @source "../css";
      @source "../js";
      @source "../../lib/chatbroom_web";

- **Never** use `@apply` when writing raw css
- daisyUI is not installed. Do not add it, Bootstrap, or another CSS framework

### UI/UX & design guidelines

- The design deliberately recreates the original 2018 Bootstrap 4 look: dark `#343a40` navbar, `#dee2e6` page background, white chat panel, `gainsboro` input bar, `lightsteelblue` user list, Bootstrap blue `#007bff` links and buttons
- Keep new UI consistent with that look, using Tailwind arbitrary values for Bootstrap's colours and sizes. Do not redesign it unless asked

### Telemetry and LiveDashboard

- Sent messages emit `[:chatbroom, :message, :sent]`, counted by a metric in `ChatbroomWeb.Telemetry`
- LiveDashboard is available **in development only** (`/dev/dashboard`, behind `dev_routes`). **Never** expose it or any telemetry data publicly, and never move it out of the `dev_routes` block


<!-- usage-rules-start -->

<!-- phoenix:elixir-start -->
## Elixir guidelines

- Elixir lists **do not support index based access via the access syntax**

  **Never do this (invalid)**:

      i = 0
      mylist = ["blue", "green"]
      mylist[i]

  Instead, **always** use `Enum.at`, pattern matching, or `List` for index based list access, ie:

      i = 0
      mylist = ["blue", "green"]
      Enum.at(mylist, i)

- Elixir variables are immutable, but can be rebound, so for block expressions like `if`, `case`, `cond`, etc
  you *must* bind the result of the expression to a variable if you want to use it and you CANNOT rebind the result inside the expression, ie:

      # INVALID: we are rebinding inside the `if` and the result never gets assigned
      if connected?(socket) do
        socket = assign(socket, :val, val)
      end

      # VALID: we rebind the result of the `if` to a new variable
      socket =
        if connected?(socket) do
          assign(socket, :val, val)
        end

- **Never** nest multiple modules in the same file as it can cause cyclic dependencies and compilation errors
- **Never** use map access syntax (`changeset[:field]`) on structs as they do not implement the Access behaviour by default. For regular structs, you **must** access the fields directly, such as `my_struct.field` or use higher level APIs that are available on the struct if they exist, `Ecto.Changeset.get_field/2` for changesets
- Elixir's standard library has everything necessary for date and time manipulation. Familiarize yourself with the common `Time`, `Date`, `DateTime`, and `Calendar` interfaces by accessing their documentation as necessary. **Never** install additional dependencies unless asked or for date/time parsing (which you can use the `date_time_parser` package)
- Don't use `String.to_atom/1` on user input (memory leak risk)
- Predicate function names should not start with `is_` and should end in a question mark. Names like `is_thing` should be reserved for guards
- Elixir's builtin OTP primitives like `DynamicSupervisor` and `Registry`, require names in the child spec, such as `{DynamicSupervisor, name: MyApp.MyDynamicSup}`, then you can use `DynamicSupervisor.start_child(MyApp.MyDynamicSup, child_spec)`
- Use `Task.async_stream(collection, callback, options)` for concurrent enumeration with back-pressure. The majority of times you will want to pass `timeout: :infinity` as option

## Mix guidelines

- Read the docs and options before using tasks (by using `mix help task_name`)
- To debug test failures, run tests in a specific file with `mix test test/my_test.exs` or run all previously failed tests with `mix test --failed`
- `mix deps.clean --all` is **almost never needed**. **Avoid** using it unless you have good reason

## Test guidelines

- **Always use `start_supervised!/1`** to start processes in tests as it guarantees cleanup between tests
- **Avoid** `Process.sleep/1` and `Process.alive?/1` in tests
  - Instead of sleeping to wait for a process to finish, **always** use `Process.monitor/1` and assert on the DOWN message:

      ref = Process.monitor(pid)
      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}

   - Instead of sleeping to synchronize before the next call, **always** use `_ = :sys.get_state/1` to ensure the process has handled prior messages
<!-- phoenix:elixir-end -->

<!-- phoenix:phoenix-start -->
## Phoenix guidelines

- Remember Phoenix router `scope` blocks include an optional alias which is prefixed for all routes within the scope. **Always** be mindful of this when creating routes within a scope to avoid duplicate module prefixes.

- You **never** need to create your own `alias` for route definitions! The `scope` provides the alias, ie:

      scope "/admin", AppWeb.Admin do
        pipe_through :browser

        live "/users", UserLive, :index
      end

  the UserLive route would point to the `AppWeb.Admin.UserLive` module

- `Phoenix.View` no longer is needed or included with Phoenix, don't use it
<!-- phoenix:phoenix-end -->

<!-- phoenix:html-start -->
## Phoenix HTML guidelines

- Phoenix templates **always** use `~H` or .html.heex files (known as HEEx), **never** use `~E`
- **Always** use the imported `Phoenix.Component.form/1` and `Phoenix.Component.inputs_for/1` function to build forms. **Never** use `Phoenix.HTML.form_for` or `Phoenix.HTML.inputs_for` as they are outdated
- When building forms **always** use the already imported `Phoenix.Component.to_form/2` (`assign(socket, form: to_form(...))` and `<.form for={@form} id="msg-form">`), then access those forms in the template via `@form[:field]`
- **Always** add unique DOM IDs to key elements (like forms, buttons, etc) when writing templates, these IDs can later be used in tests (`<.form for={@form} id="product-form">`)
- For "app wide" template imports, you can import/alias into the `my_app_web.ex`'s `html_helpers` block, so they will be available to all LiveViews, LiveComponent's, and all modules that do `use MyAppWeb, :html` (replace "my_app" by the actual app name)

- Elixir supports `if/else` but **does NOT support `if/else if` or `if/elsif`**. **Never use `else if` or `elseif` in Elixir**, **always** use `cond` or `case` for multiple conditionals.

  **Never do this (invalid)**:

      <%= if condition do %>
        ...
      <% else if other_condition %>
        ...
      <% end %>

  Instead **always** do this:

      <%= cond do %>
        <% condition -> %>
          ...
        <% condition2 -> %>
          ...
        <% true -> %>
          ...
      <% end %>

- HEEx require special tag annotation if you want to insert literal curly's like `{` or `}`. If you want to show a textual code snippet on the page in a `<pre>` or `<code>` block you *must* annotate the parent tag with `phx-no-curly-interpolation`:

      <code phx-no-curly-interpolation>
        let obj = {key: "val"}
      </code>

  Within `phx-no-curly-interpolation` annotated tags, you can use `{` and `}` without escaping them, and dynamic Elixir expressions can still be used with `<%= ... %>` syntax

- HEEx class attrs support lists, but you must **always** use list `[...]` syntax. You can use the class list syntax to conditionally add classes, **always do this for multiple class values**:

      <a class={[
        "px-2 text-white",
        @some_flag && "py-5",
        if(@other_condition, do: "border-red-500", else: "border-blue-100"),
        ...
      ]}>Text</a>

  and **always** wrap `if`'s inside `{...}` expressions with parens, like done above (`if(@other_condition, do: "...", else: "...")`)

  and **never** do this, since it's invalid (note the missing `[` and `]`):

      <a class={
        "px-2 text-white",
        @some_flag && "py-5"
      }> ...
      => Raises compile syntax error on invalid HEEx attr syntax

- **Never** use `<% Enum.each %>` or non-for comprehensions for generating template content, instead **always** use `<%= for item <- @collection do %>`
- HEEx HTML comments use `<%!-- comment --%>`. **Always** use the HEEx HTML comment syntax for template comments (`<%!-- comment --%>`)
- HEEx allows interpolation via `{...}` and `<%= ... %>`, but the `<%= %>` **only** works within tag bodies. **Always** use the `{...}` syntax for interpolation within tag attributes, and for interpolation of values within tag bodies. **Always** interpolate block constructs (if, cond, case, for) within tag bodies using `<%= ... %>`.

  **Always** do this:

      <div id={@id}>
        {@my_assign}
        <%= if @some_block_condition do %>
          {@another_assign}
        <% end %>
      </div>

  and **Never** do this – the program will terminate with a syntax error:

      <%!-- THIS IS INVALID NEVER EVER DO THIS --%>
      <div id="<%= @invalid_interpolation %>">
        {if @invalid_block_construct do}
        {end}
      </div>
<!-- phoenix:html-end -->

<!-- usage-rules-end -->