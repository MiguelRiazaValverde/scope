# Scope

To start the server, run the following command in your terminal:

```bash
elixir --name scope@127.0.0.1 --cookie asdf -S mix phx.server
```

Important:

The --cookie value must match the cookie of the node you want to connect to.

Make sure the node name (--name scope@127.0.0.1) is unique and fits your network configuration.

This will start the server and allow it to communicate with the remote node to fetch information.
