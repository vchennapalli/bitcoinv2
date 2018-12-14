defmodule User do
  alias Block, as: B
  alias Transaction, as: T
  # alias Helper, as: H
  alias Mining, as: M

  @moduledoc """
  contains the definitions and functions for wallet
  """
  use GenServer

  @first_tx_after 1000
  @create_second_block_after 2000
  @block_mining_rate 1500 # one per 1.5 secs
  @initiate_tx_dur_range 100..600 # new tx initiated per a 0.1 to 0.6 secs

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
    Process.send_after(self(), :initiate_transaction, @first_tx_after)
    Process.send_after(self(), :create_block, @create_second_block_after)
    :timer.start
    {:ok, args}
  end


  def handle_info({:receive_transaction, transaction}, state) do
    state = T.receive_transaction(state, transaction)
    {:noreply, state}
  end

  def handle_info({:receive_block, block, height}, state) do
    new_state = B.receive(state, block, height)
    Process.send(self(), :create_block, [])
    {:noreply, new_state}
  end

  def handle_info(tag, state) do
    
    state = 
    case tag do
      :genesis -> genesis_wrapper(state)
      :initiate_transaction -> initiate_transaction_wrapper(state)
      :create_block -> create_block_wrapper(state)
      :mine_block -> mine_block_wrapper(state)    
    end

    {:noreply, state}
  end

  def create_block_wrapper(state) do
    bc_size = length(state[:blockchain])
    max_blocks = state[:max_blocks]
    mempool_size = state[:mempool] |> map_size()

    cond do
      bc_size == max_blocks ->
        parent = state[:parent]
        Process.send(parent, :close, [])
        state
      mempool_size >= 4 ->
        state = B.create(state)
        start_time = :os.system_time(:micro_seconds)
        state = Map.put(state, :mining_begin_time, start_time)
        Process.send(self(), :mine_block, [])
        state
      true ->
        state
    end
  end

  def genesis_wrapper(state) do
    {new_state, new_block, height} = B.create_genesis_block(state)
    neighbors = Map.get(state, :public_addresses)
    agent_pid = Map.get(state, :agent_pid)
    IO.puts "Broadcasting the genesis block . ."
    broadcast_block(new_block, height, agent_pid, neighbors)
    Process.send_after(self(), :create_block, @block_mining_rate)
    new_state
  end

  def initiate_transaction_wrapper(state) do
    Process.send_after(self(), :initiate_transaction, Enum.random(@initiate_tx_dur_range))
    {new_transaction, new_state} = T.initiate_transaction(state)
    if new_transaction != nil do
      neighbors = Map.get(new_state, :public_addresses)
      agent_pid = Map.get(new_state, :agent_pid)
      broadcast_transaction(new_transaction, agent_pid, neighbors)
      Process.send(self(), {:receive_transaction, new_transaction}, [])  
    end
    new_state
  end

  def mine_block_wrapper(state) do
    if state[:continue_mining] do
      {is_pow_valid, state} = M.check_proof_of_work(state)
      new_state = 
      if is_pow_valid do
        end_time = :os.system_time(:micro_seconds)
        start_time = state[:mining_begin_time]

        Bitcoinv2Web.Endpoint.broadcast "miningChannel:","mining:time",%{
          time: end_time - start_time
        }

        {new_state, block, height} = B.add_to_blockchain(state)
        new_state = Map.put(new_state, :continue_mining, false)
        agent_pid = Map.get(new_state, :agent_pid)
        neighbors = Map.get(new_state, :public_addresses)
        broadcast_block(block, height, agent_pid, neighbors)
        IO.puts "Broadcasting the newly mined block"
        Process.send_after(self(), :create_block, @block_mining_rate)
        new_state
      else
        Process.send(self(), :mine_block, [])
        state
      end
    else
      state
    end 
  end


   @doc """
  sends the transaction to all the neighbors in the network
  """
  def broadcast_transaction(transaction, agent_pid, [neighbor | neighbors]) do
    neigh_pid = Neighbors.get(agent_pid, neighbor)
    Process.send(neigh_pid, {:receive_transaction, transaction}, [])
    broadcast_transaction(transaction, agent_pid, neighbors)
  end

  def broadcast_transaction(_, _, []) do
    true
  end

  @doc """
  sends the block to all the neighbors in the network
  """
  def broadcast_block(block, height, agent_pid, [neighbor | neighbors]) do
    neigh_pid = Neighbors.get(agent_pid, neighbor)
    Process.send(neigh_pid, {:receive_block, block, height}, [])
    broadcast_block(block, height, agent_pid, neighbors)
  end

  def broadcast_block(block,height, _, []) do
    # IO.puts "//////////////////////////"
    # mr = block.header.merkle_root
    # IO.inspect block
    # Bitcoinv2Web.Endpoint.broadcast "miningChannel:" , "mining", %{
    #   bits: block.header.bits,
    #   merkle_root: Base.encode16(mr),    
    #   height: height,

    #   prev_blockHash: block,header.previous_block_hash,
    #   timeS: block.header.timestamp
    #   num_transactions: block.num_transactions

    # }
    true
  end

end
