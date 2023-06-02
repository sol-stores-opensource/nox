# Nox

![The Nox](./TheNox.jpeg?raw=true)

To start your Phoenix server:

- Install dependencies with `mix deps.get`
- Install javascript dependencies with `(cd assets && npm install)`
- Create and migrate your database with `mix ecto.setup`
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

To setup local https development:

- Install local https deps: `brew install caddy mkcert nss dnsmasq`
- Initialize mkcert: `mkcert -install`
- Create dev cert: `(cd /opt/homebrew/etc && mkcert '*.localtest.me')`
- Edit files:

/opt/homebrew/etc/dnsmasq.conf:

```
port=53
```

/opt/homebrew/etc/Caddyfile:

```
nox.localtest.me {
  tls /opt/homebrew/etc/_wildcard.localtest.me.pem /opt/homebrew/etc/_wildcard.localtest.me-key.pem
  reverse_proxy 127.0.0.1:4000
}
```

- `sudo brew services start dnsmasq`:
- `brew services restart caddy`:

- Now visit [`https://nox.localtest.me`](https://nox.localtest.me)

## Connecting with the authorized google domain and making the account an `admin` role

```elixir
Nox.Users.get_by_email(your_email_address) |> Nox.Users.add_role!("admin")
```

- Now reload the page and you should have admin.

## Deploy

    git push origin +HEAD:release-prod

## Learn more

- Official website: https://www.phoenixframework.org/
- Guides: https://hexdocs.pm/phoenix/overview.html
- Docs: https://hexdocs.pm/phoenix
- Forum: https://elixirforum.com/c/phoenix-forum
- Source: https://github.com/phoenixframework/phoenix
