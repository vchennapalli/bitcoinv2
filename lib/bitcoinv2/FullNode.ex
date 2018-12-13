defmodule FullNode do
  alias Block, as: B
  alias Transaction, as: T
  alias Helper, as: H

  @moduledoc """
  contains the definitons and functions for wallet, blockchain handling, mining etc
  """
  use GenServer

  @doc """
  first step
  """
  def start_link(status) do
    GenServer.start_link(__MODULE__, status)
  end

  @doc """
  initialize the process
  """
  def init(args) do
    {:ok, args}
  end

  def handle_cast({tag, message}, state) do
    new_state =
    case tag do
       :receive_transaction -> T.receive_transaction(message, state)
       :receive_block -> B.receive(message, 1, state)
    end

    {:noreply, new_state}
  end

  def handle_cast(:initiate_transaction, state) do
    new_state = T.initiate_transaction(state)
    {:noreply, new_state}
  end

  def handle_info(:genesis, state) do
    IO.puts "HERE"
    new_state = B.create(state)
    {:noreply, new_state}
  end

end
