defmodule Bitcoinv2Web.PageController do
  use Bitcoinv2Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

end
