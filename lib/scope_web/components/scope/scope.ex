defmodule ScopeWeb.Scope do
  use ScopeWeb, :live_view

  def mount(_params, _session, socket) do
    if connected?(socket), do: schedule_ping()

    node = "scope@127.0.0.1"

    {:ok,
     assign(socket,
       node: node,
       status: String.contains?(node, "@") and Node.connect(String.to_atom(node)),
       processes: [],
       selected_pid: nil,
       windows: MapSet.new([])
     )}
  end

  def handle_event("update_node", %{"node" => node}, socket) do
    status = String.contains?(node, "@") and Node.connect(String.to_atom(node))

    {:noreply, assign(socket, node: node, status: status)}
  end

  def handle_event("select_pid", %{"pid" => pid}, socket) do
    windows =
      if pid === socket.assigns.selected_pid && MapSet.member?(socket.assigns.windows, pid) do
        MapSet.delete(socket.assigns.windows, pid)
      else
        MapSet.put(socket.assigns.windows, pid)
      end

    {:noreply, assign(socket, selected_pid: pid, windows: windows)}
  end

  def handle_info(:check_connection, socket) do
    processes =
      if socket.assigns.status do
        node = String.to_atom(socket.assigns.node)

        :rpc.call(node, :erlang, :processes, [], 5000)
        |> Enum.map(fn pid ->
          info = :rpc.call(node, :erlang, :process_info, [pid], 5000)
          {pid, info}
        end)
        |> Enum.filter(fn {_pid, info} -> info != :undefined end)
      else
        []
      end

    schedule_ping()
    {:noreply, assign(socket, processes: Map.new(processes))}
  end

  defp schedule_ping() do
    Process.send_after(self(), :check_connection, 500)
  end

  def render_pid_info(processes, pid, selected_pid) do
    case Map.get(processes, pid) do
      nil ->
        raw("PID inválido")

      data ->
        links =
          Keyword.get(data, :links, [])
          |> Enum.reject(&is_nil/1)
          |> Enum.filter(&is_pid/1)
          |> Enum.map(&format_pid(&1, selected_pid))

        links_html =
          links
          |> Enum.map(&Phoenix.HTML.safe_to_string/1)
          |> Enum.join("\n")

        raw("""
          <tr>
            <td>Reductions</td>
            <td>#{data[:reductions]}</td>
          </tr>
          <tr>
            <td>Current function</td>
            <td>#{format_fun(data[:current_function])}</td>
          </tr>
          <tr>
            <td>Initial call</td>
            <td>#{format_fun(data[:initial_call])}</td>
          </tr>
          <tr>
            <td>Status</td>
            <td>#{data[:status]}</td>
          </tr>
          <tr>
            <td>Priority</td>
            <td>#{data[:priority]}</td>
          </tr>
          <tr>
            <td>Message queue</td>
            <td>#{data[:message_queue_len]}</td>
          </tr>
          <tr>
            <td>Links</td>
            <td>#{links_html}</td>
          </tr>
          <tr>
            <td>Trap exit</td>
            <td>#{data[:trap_exit]}</td>
          </tr>
          <tr>
            <td>Error handler</td>
            <td>#{data[:error_handler]}</td>
          </tr>
          <tr>
            <td>Stack size</td>
            <td>#{data[:stack_size]}</td>
          </tr>
          <tr>
            <td>Heap size</td>
            <td>#{data[:heap_size]}</td>
          </tr>

        """)
    end
  end

  defp pid_from_str(pid_str) do
    charlist = String.to_charlist("<#{pid_str}>")
    pid = :erlang.list_to_pid(charlist)
    pid
  end

  defp pid_parts(pid) do
    case :erlang.pid_to_list(pid) do
      ~c'<' ++ rest ->
        [a, b, c] =
          rest
          |> to_string()
          |> String.trim_trailing(">")
          |> String.split(".")
          |> Enum.map(&String.to_integer/1)

        {a, b, c}
    end
  end

  defp format_pid(pid, selected_pid) do
    {a, b, c} = pid_parts(pid)
    pid_str = "#{a}.#{b}.#{c}"

    class =
      if pid_str === selected_pid do
        "selected-pid"
      else
        ""
      end

    raw("""
    <div class="pid #{class}" phx-click="select_pid" phx-value-pid="#{pid_str}">
      &lt;
        <span class="pid-component">#{a}</span>.
        <span class="pid-component">#{b}</span>.
        <span class="pid-component">#{c}</span>
      &gt;
    </div>
    """)
  end

  defp format_fun({mod, fun, arity}), do: "#{mod}.#{fun}/#{arity}"
  defp format_fun(_), do: "-"
end
