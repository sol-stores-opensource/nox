defmodule Nox.Presence do
  use Phoenix.Presence,
    otp_app: :nox,
    pubsub_server: Nox.PubSub
end
