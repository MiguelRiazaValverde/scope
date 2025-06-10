defmodule ScopeWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use ScopeWeb, :html

  embed_templates "page_html/*"

  def mount(socket) do
    {:ok, assign(socket, %{node: "node@127.0.0.1"})}
  end
end
