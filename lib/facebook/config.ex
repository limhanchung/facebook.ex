defmodule Facebook.Config do
  use LibEx.Config, application: :facebook

  @doc """
    iex> Facebook.Config.graph_url
    "graph_url"
  """
  defkey :graph_url

  @doc """
    iex> Facebook.Config.client_id
    "client_id"
  """
  defkey :client_id

  @doc """
    iex> Facebook.Config.appsecret
    "appsecrettokenhere"
  """
  defkey :appsecret
end
