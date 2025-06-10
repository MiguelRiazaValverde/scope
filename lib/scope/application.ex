defmodule Scope.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ScopeWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:scope, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Scope.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Scope.Finch},
      # Start a worker by calling: Scope.Worker.start_link(arg)
      # {Scope.Worker, arg},
      # Start to serve requests, typically the last entry
      ScopeWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Scope.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ScopeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
