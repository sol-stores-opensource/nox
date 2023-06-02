defmodule Nox.DevDisableLog do
  @moduledoc """
  Disable and re-enable logging in dev mode.  Will not enable logging
  if logging was disabled previously.

  ```
    was_log_enabled = Nox.DevDisableLog.disable_in_dev()
    ... do stuff ...
    Nox.DevDisableLog.reenable_in_dev(was_log_enabled)
  ```
  """
  @disable_log Application.compile_env!(:nox, :env) == :dev

  def disable_in_dev() do
    was_log_enabled = Logger.enabled?(self())
    if @disable_log, do: Logger.disable(self())
    was_log_enabled
  end

  def reenable_in_dev(was_log_enabled) do
    if was_log_enabled && @disable_log, do: Logger.enable(self())
  end
end
