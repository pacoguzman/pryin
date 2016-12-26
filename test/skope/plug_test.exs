defmodule Skope.PlugTest do
  use Skope.Case
  use Phoenix.ConnTest
  alias Skope.InteractionStore

  @endpoint Skope.TestEndpoint

  setup _ do
    Skope.TestEndpoint.start_link
    :ok
  end

  test "generates a request" do
    build_conn(:get, "/")
    |> Skope.Plug.call([])
    |> send_resp(:ok, "")

    [interaction] = InteractionStore.get_state.finished_interactions
    assert interaction.start_time
    assert interaction.duration
  end

  describe "action and controller" do
    test "in plug apps" do
      conn = build_conn(:get, "/test")
      Skope.TestPlugApp.call(conn, [])

      [interaction] = InteractionStore.get_state.finished_interactions
      assert interaction.controller == nil
      assert interaction.action == nil
    end

    test "in phoenix apps" do
      get build_conn(), "/test"

      [interaction] = InteractionStore.get_state.finished_interactions
      assert interaction.action == :test_action
      assert interaction.controller == "Skope.TestController"
    end
  end

  describe "request_id" do
    test "uses the request_id generated by plug if present" do
      request_id = "abcd-1234"
      Logger.metadata(request_id: request_id)
      build_conn(:get, "/test")
      |> Skope.Plug.call([])
      |> send_resp(:ok, "")

      [interaction] = InteractionStore.get_state.finished_interactions
      assert interaction.interaction_id == request_id
    end

    test "generates an interaction_id if none is in loggers metadata" do
      build_conn(:get, "/test")
      |> Skope.Plug.call([])
      |> send_resp(:ok, "")

      [interaction] = InteractionStore.get_state.finished_interactions
      assert interaction.interaction_id
    end
  end
end