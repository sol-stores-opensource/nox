defmodule NoxWeb.LokiAllowedIpsLive.Index do
  use NoxWeb, :live_view

  defmodule Form do
    use Ecto.Schema
    import Ecto.Changeset

    defmodule IP do
      use Ecto.Schema
      import Ecto.Changeset

      @primary_key false
      embedded_schema do
        field :ip, :string
      end

      def changeset(scope, attrs) do
        scope
        |> cast(attrs, [:ip])
        |> validate_required([:ip])
        |> validate_change(:ip, fn :ip, ip ->
          res =
            ip
            |> String.to_charlist()
            |> :inet_parse.ipv4strict_address()

          case res do
            {:ok, _} -> []
            _ -> [ip: "must be a valid IP"]
          end
        end)
      end
    end

    @primary_key false
    embedded_schema do
      field :enabled, :boolean
      field :secret, :string

      embeds_many :allowed_ips, IP, on_replace: :delete
    end

    def changeset(scope, attrs) do
      scope
      |> cast(attrs, [:enabled, :secret])
      |> cast_embed(:allowed_ips)
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> reset_page()
    |> okreply()
  end

  @impl true
  def handle_event("validate", %{"form" => params}, %{assigns: %{changeset: changeset}} = socket) do
    changeset =
      changeset.data
      |> Form.changeset(params)
      |> Map.put(:action, :validate)

    socket
    |> assign(changeset: changeset)
    |> noreply()
  end

  @impl true
  def handle_event("save", %{"form" => params}, %{assigns: %{changeset: changeset}} = socket) do
    changeset =
      changeset.data
      |> Form.changeset(params)
      |> Map.put(:action, :save)

    if changeset.valid? do
      form =
        changeset
        |> Ecto.Changeset.apply_changes()

      NoxWeb.LearnEarnSocket.put_loki_auth_enabled(form.enabled)
      NoxWeb.LearnEarnSocket.put_loki_secret(form.secret)

      form.allowed_ips
      |> Enum.map(fn x -> x.ip end)
      |> NoxWeb.LearnEarnSocket.put_loki_auth_allowed_ips()

      socket
      |> reset_page()
      |> noreply()
    else
      socket
      |> assign(changeset: changeset)
      |> noreply()
    end
  end

  @impl true
  def handle_event("add_allowed_ip", _, socket) do
    x = Ecto.Changeset.get_field(socket.assigns.changeset, :allowed_ips) || []

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_embed(:allowed_ips, x ++ [%{ip: ""}])

    socket
    |> assign(changeset: changeset)
    |> noreply()
  end

  @impl true
  def handle_event("delete_allowed_ip", %{"i" => i}, socket) do
    x = Ecto.Changeset.get_field(socket.assigns.changeset, :allowed_ips) || []

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_embed(:allowed_ips, List.delete_at(x, String.to_integer(i)))

    socket
    |> assign(changeset: changeset)
    |> noreply()
  end

  def reset_page(socket) do
    config = NoxWeb.LearnEarnSocket.get_loki_auth_config()

    form = %Form{
      enabled: Map.get(config, :enabled, false),
      secret: Map.get(config, :secret),
      allowed_ips:
        Map.get(config, :allowed_ips, [])
        |> Enum.map(fn ip -> %Form.IP{ip: ip} end)
    }

    socket
    |> assign(changeset: Form.changeset(form, %{}))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-row gap-x-5 mb-5">
      <.h2 class="grow">Kiosk Firewall</.h2>
    </div>
    <.p class="!mb-5">
      The Kiosk Firewall enables limiting access by Secret OR Allowed IPs.
      Tablets will use Allowed IPs.  Remote Access (debugging/testing) can use Secret.
    </.p>

    <div class="bg-white shadow overflow-hidden sm:rounded-lg">
      <div class="px-4 py-5 sm:px-6">
        <.form
          :let={f}
          for={@changeset}
          id="loki-allowed-ips-form"
          phx-change="validate"
          phx-submit="save"
        >
          <.form_field type="switch" form={f} field={:enabled} label="Firewall Enabled" />

          <.form_field type="text_input" form={f} field={:secret} placeholder="Secret" />

          <div class="flex flex-row items-center justify-end gap-x-4 mb-3">
            <div class="flex-grow">
              <.h5 class="!m-0">Allowed IP Addresses</.h5>
            </div>
            <.button icon type="button" phx-click="add_allowed_ip">
              <HeroiconsV1.Outline.plus class="w-5 h-5" /> IP
            </.button>
          </div>

          <%= inputs_for f, :allowed_ips, [], fn fp  -> %>
            <div id={fp.id} class="flex flex-row gap-x-4">
              <div class="flex-grow">
                <.text_input form={fp} field={:ip} placeholder="IP address" />
                <.form_field_error form={fp} field={:key} class="mt-1" />
              </div>

              <div class="mt-1">
                <.a
                  to="#"
                  phx-click="delete_allowed_ip"
                  phx-value-i={fp.index}
                  data-confirm="Are you sure?"
                >
                  <HeroiconsV1.Outline.trash class="h-6 w-6" />
                </.a>
              </div>
            </div>
          <% end %>

          <div class="flex flex-row justify-end">
            <.button type="submit" color="primary" label="Save" phx-disable-with="Saving..." />
          </div>
        </.form>
      </div>
    </div>
    """
  end
end
