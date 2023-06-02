defmodule NoxWeb.LearnEarnController do
  use NoxWeb, :controller

  def session(conn, %{"sessionId" => session_id}) do
    case Nox.LokiSession.get(session_id) do
      %{selected_tutorial: %{"tutorial_store_id" => tutorial_store_id}} = session ->
        tutorial_store = Nox.Tutorials.get_tutorial_store!(tutorial_store_id)
        address = Map.get(session, :address)

        if address do
          rewards =
            Nox.LearnEarn.rewards_by_tutorial_id_address(tutorial_store.tutorial.id, address)

          response = %{address: address, rewardsToDate: rewards}

          conn
          |> put_resp_content_type("application/json")
          |> resp(
            200,
            Jason.encode!(response)
          )
        else
          conn
          |> put_resp_content_type("application/json")
          |> resp(
            200,
            Jason.encode!(%{address: nil, rewardsToDate: %{}})
          )
        end

      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> resp(
          500,
          Jason.encode!(%{ok: false})
        )
    end
  end

  @doc """
  THIS IS FOR LOCAL DEVELOPMENT
  """
  def tuts_data(conn, %{"sessionId" => "LOCAL_MODE:" <> tutorial_store_id}) do
    tutorial_store = Nox.Tutorials.get_tutorial_store!(tutorial_store_id)

    data = Nox.Tutorials.get_tuts_data(tutorial_store)

    response = %{data: data}

    conn
    |> put_resp_content_type("application/json")
    |> resp(
      200,
      Jason.encode!(response)
    )
  end

  def tuts_data(conn, %{"sessionId" => session_id}) do
    case Nox.LokiSession.get(session_id) do
      %{selected_tutorial: %{"tutorial_store_id" => tutorial_store_id}} ->
        tutorial_store = Nox.Tutorials.get_tutorial_store!(tutorial_store_id)

        data = Nox.Tutorials.get_tuts_data(tutorial_store)

        response = %{data: data}

        conn
        |> put_resp_content_type("application/json")
        |> resp(
          200,
          Jason.encode!(response)
        )

      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> resp(
          500,
          Jason.encode!(%{ok: false})
        )
    end
  end

  def setup(conn, %{"sessionId" => session_id, "steps" => steps}) do
    Enum.each(steps, fn %{"id" => _id, "title" => _title, "description" => _description} ->
      :ok
    end)

    Nox.LokiSession.put_steps(session_id, steps)

    NoxWeb.Endpoint.broadcast("learn_earn:#{session_id}", "steps", %{steps: steps})

    conn
    |> put_resp_content_type("application/json")
    |> resp(
      200,
      Jason.encode!(%{
        ok: true
      })
    )
  end

  def step(conn, %{
        "sessionId" => session_id,
        "step" => step,
        "status" => status
      })
      when is_integer(step) do
    Nox.LokiSession.put_step_status(session_id, step, status)

    if status == "COMPLETE" do
      Nox.LearnEarn.track_session_step!(session_id, step)
    end

    conn
    |> put_resp_content_type("application/json")
    |> resp(
      200,
      Jason.encode!(%{
        ok: true
      })
    )
  end

  def collect(
        conn,
        %{
          "sessionId" => session_id,
          "event" => event,
          "data" => %{} = data
        }
      ) do
    Nox.LearnEarn.track_session_collect!(session_id, event, data)

    conn
    |> put_resp_content_type("application/json")
    |> resp(
      200,
      Jason.encode!(%{
        ok: true
      })
    )
  end

  def reward(conn, %{
        "sessionId" => session_id,
        "amount" => amount,
        "token" => token
      }) do
    case Nox.LokiSession.get(session_id) do
      %{selected_tutorial: %{"tutorial_store_id" => tutorial_store_id}} = session ->
        tutorial_store = Nox.Tutorials.get_tutorial_store!(tutorial_store_id)
        address = Map.get(session, :address)

        if address do
          Nox.LearnEarn.track_reward(
            tutorial_store.tutorial.id,
            address,
            token,
            amount,
            session_id
          )

          Nox.LearnEarn.track_session_external_reward!(session_id, token, amount)

          conn
          |> put_resp_content_type("application/json")
          |> resp(
            200,
            Jason.encode!(%{
              ok: true
            })
          )
        else
          conn
          |> put_resp_content_type("application/json")
          |> resp(
            500,
            Jason.encode!(%{ok: false})
          )
        end

      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> resp(
          500,
          Jason.encode!(%{ok: false})
        )
    end
  end

  def mark_redeemed(conn, %{
        "wallet_address" => wallet_address,
        "token" => token
      }) do
    res = Nox.LearnEarn.track_ext_redeemed(wallet_address, token)

    conn
    |> put_resp_content_type("application/json")
    |> resp(
      200,
      Jason.encode!(%{
        ok: res
      })
    )
  end

  def complete(conn, %{"sessionId" => session_id} = params) do
    case Nox.LokiSession.get(session_id) do
      %{selected_tutorial: %{"tutorial_store_id" => tutorial_store_id}} = session ->
        tutorial_store = Nox.Tutorials.get_tutorial_store!(tutorial_store_id)
        address = Map.get(session, :address)

        status =
          case Map.get(params, "status") do
            true -> true
            "true" -> true
            _ -> false
          end

        Nox.LearnEarn.track_session_complete!(session_id, status)

        if address do
          spaces_nft_reward_count =
            Nox.LearnEarn.get_spaces_nft_reward_count(address, [
              status && tutorial_store.on_complete_nft
            ])

          conn
          |> put_resp_content_type("application/json")
          |> resp(
            200,
            Jason.encode!(%{
              ok: true,
              spaces_nft_reward_count: spaces_nft_reward_count
            })
          )
        else
          conn
          |> put_resp_content_type("application/json")
          |> resp(
            200,
            Jason.encode!(%{
              ok: true,
              spaces_nft_reward_count: 0
            })
          )
        end

      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> resp(
          500,
          Jason.encode!(%{
            ok: false
          })
        )
    end
  end

  def kiosker_settings(conn, _) do
    kiosk_url = Application.fetch_env!(:nox, :kiosk_url)

    settings = %{
      "autoOffTime" => %{"hour" => 0, "minute" => 0},
      "favorites" => [],
      "disableSelect" => true,
      "flicActive" => false,
      "flicMode" => 0,
      "statusbarMode" => 0,
      "autoOff" => false,
      "disableSwipeToNavigate" => true,
      "printOrientation" => 0,
      "restrictDomain" => 0,
      "localIndex" => "index.html",
      "disableZoom" => true,
      "screensaverStyle" => 1,
      "screenMenuHome" => false,
      "showStatusBar" => false,
      "useiCloud" => false,
      "screenMenuHide" => false,
      "flicUrl" => nil,
      "hideNavBarOnHome" => false,
      "disableScreenSleep" => false,
      "url" => kiosk_url,
      "popupInNewWindow" => false,
      "password" => "",
      "disableTouch" => false,
      "navBar" => false,
      "screenMenuFavorite" => false,
      "disableDoubleTap" => false,
      "browserLimit" => false,
      "autoReload" => false,
      "noCache" => false,
      "motionDetection" => 0,
      "disableScroll" => false,
      "useLocal" => false,
      "screenMenuNavigation" => false,
      "showSettingsOnStart" => true,
      "disableContactLinks" => false,
      "customUserAgentString" => "",
      "autoReloadError" => false,
      "disableScrollBounce" => true,
      "screensaverSlideshowTimeout" => 5,
      "allowInsecureSSL" => true,
      "metaTime" => 1_659_370_999.562536,
      "passwordProtect" => false,
      "audioVideoPermission" => 1,
      "screensaverMode" => 0,
      "allowedDomains" => [],
      "showLoader" => false,
      "deniedDomains" => [],
      "idleTimeout" => true,
      "idleTimeoutSeconds" => 1200,
      "allowLocation" => false,
      "javaScriptIntegration" => false,
      "customUserAgent" => false,
      "autoOffTimeoutSeconds" => 30,
      "screensaverAnimationPeriod" => 3600,
      "timeOutMessage" => "Browsing time limit exceeded",
      "browserLimitSeconds" => 300,
      "orientation" => 0,
      "screenMenuSettings" => false,
      "autoOnTime" => %{"hour" => 0, "minute" => 0},
      "silentPrint" => false,
      "autoReloadSeconds" => 43200,
      "disablePullToRefresh" => false,
      "showTimeOutMessage" => true,
      "disableCustomLinks" => false,
      "autoDeleteCookies" => false,
      "allowBiometrics" => false,
      "autoSingleAppMode" => false,
      "screenMenuPrint" => false
    }

    conn
    |> put_resp_content_type("application/octet-stream")
    |> put_resp_header("Content-Disposition", "attachment; filename=\"kiosker.settings\"")
    |> resp(
      200,
      Jason.encode!(settings)
    )
  end
end
