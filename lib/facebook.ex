defmodule Facebook do
  use Application
  use Supervisor

  @moduledoc """
  Provides API wrappers for the Facebook Graph API

  See: https://developers.facebook.com/docs/graph-api
  """

  alias Facebook.Config

  @doc "Start hook"
  def start(_type, _args) do
    start_link([])
  end

  @doc "Supervisor start"
  def start_link(_) do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_) do
    children = [
      worker(Facebook.Graph, [])
    ]

    supervise(children, strategy: :one_for_one)
  end

  @type fields :: list
  @type access_token :: String.t
  @type response :: {:json, HashDict.t} | {:body, String.t}
  @type options :: list
  @type using_appsecret :: boolean

  @doc """
  If you want to use an appsecret proof, pass it into set_appsecret:
  Facebook.set_appsecret("appsecret")

  See: https://developers.facebook.com/docs/graph-api/securing-requests
  """
  def set_appsecret(appsecret) do
    Config.appsecret(appsecret)
  end

  @doc """
  Basic user infos of the logged in user (specified by the access_token)

  See: https://developers.facebook.com/docs/graph-api/reference/user/
  """
  @spec me(fields, access_token) :: response
  def me(fields, access_token) when is_binary(fields) do
    me([fields: fields], access_token, [])
  end

  def me(fields, access_token) do
    me(fields, access_token, [])
  end

  @doc """
  Basic user infos of the logged in user (specified by the access_token).

  See: https://developers.facebook.com/docs/graph-api/reference/user/
  """
  @spec me(fields :: String.t, access_token, options) :: response
  def me(fields, access_token, options) when is_binary(fields) do
    me([fields: fields], access_token, options)
  end

  @doc """
  Basic user infos of the logged in user (specified by the access_token).

  See: https://developers.facebook.com/docs/graph-api/reference/user/
  """
  @spec me(fields, access_token, options) :: response
  def me(fields, access_token, options) do
    if !is_nil(Config.appsecret) do
      fields = fields ++ [appsecret_proof: encrypt(access_token)]
    end

    Facebook.Graph.get("/me", fields ++ [access_token: access_token], options)
  end

  @doc """
  Generate long-lived token

  See: https://developers.facebook.com/docs/facebook-login/access-tokens/expiration-and-extension#long-via-code
  """
  @spec long_lived_access_token(access_token, options) :: response
  def long_lived_access_token(access_token, options) do

    Facebook.Graph.get("/oauth/access_token", [ grant_type: "fb_exchange_token", client_id: Config.client_id, client_secret: Config.appsecret, appsecret_proof: encrypt(access_token), fb_exchange_token: access_token], options)
  end

  @doc """
  Likes of the currently logged in user (specified by the access_token)

  See: https://developers.facebook.com/docs/graph-api/reference/user/likes
  """
  @spec myLikes(access_token) :: response
  def myLikes(access_token) do
    myLikes(access_token, [])
  end

  @doc """
  Likes of the currently logged in user (specified by the access_token)

  See: https://developers.facebook.com/docs/graph-api/reference/user/likes
  """
  @spec myLikes(access_token, options) :: response
  def myLikes(access_token, options) do
    fields = [access_token: access_token]
    if !is_nil(Config.appsecret) do
      fields = fields ++ [appsecret_proof: encrypt(access_token)]
    end
    Facebook.Graph.get("/me/likes", fields, options)
  end

  @doc """
  Retrieves a list of granted permissions

  See: https://developers.facebook.com/docs/graph-api/reference/user/permissions
  """
  @spec permissions(user_id :: integer | String.t, access_token) :: response
  def permissions(user_id, access_token) do
    permissions(user_id, access_token, [])
  end

  @doc """
  Retrieves a list of granted permissions

  See: https://developers.facebook.com/docs/graph-api/reference/user/permissions
  """
  @spec permissions(user_id :: integer | String.t, access_token, options) :: response
  def permissions(user_id, access_token, options) do
    fields = [access_token: access_token]
    if !is_nil(Config.appsecret) do
      fields = fields ++ [appsecret_proof: encrypt(access_token)]
    end
    Facebook.Graph.get(~s(/#{user_id}/permissions), fields, options)
  end

  @doc """
  Get the number of likes for the provided page_id
  """
  @spec pageLikes(page_id :: integer | String.t, access_token) :: integer
  def pageLikes(page_id, access_token) do
    {:json, %{"likes" => likes}} = page(page_id, access_token, ["likes"], [])
    likes
  end

  @doc """
  Basic page information for the provided page_id

  See: https://developers.facebook.com/docs/graph-api/reference/page
  """
  @spec page(page_id :: integer | String.t, access_token) :: response
  def page(page_id, access_token) do
    page(page_id, access_token, [], [])
  end

  @doc """
  Get page information for the specified fields for the provided page_id

  See: https://developers.facebook.com/docs/graph-api/reference/page
  """
  @spec page(page_id :: integer | String.t, access_token, fields, options) :: response
  def page(page_id, access_token, fields, options) do
    params = [fields: fields, access_token: access_token]
    if !is_nil(Config.appsecret) do
      params = params ++ [appsecret_proof: encrypt(access_token)]
    end
    Facebook.Graph.get(~s(/#{page_id}), params, options)
  end


  defp encrypt(token) do
    :crypto.hmac(:sha256, Config.appsecret, token)
    |> Base.encode16(case: :lower)
  end
end
