defmodule Bitcoin do
  @moduledoc """
  main module from where the peerss are created
  """
  use Supervisor
  @doc """
  main function
  """
  def main(num_users,max_blocks) do
    #num_users = 100
    # max_blocks = 10
    {:ok, agent_pid} = Neighbors.start_link(nil)
    {:ok, super_pid} = start_link(num_users - 1, max_blocks, agent_pid)
    # [child|_children] = Supervisor.which_children(super_pid)
    # IO.inspect child.get(1)
    # IO.inspect :sys.get_state(child.get(1))
    
    public_addresses = update_agent(Supervisor.which_children(super_pid), agent_pid, [])

    begin(agent_pid, public_addresses)
    listen(num_users)
  end


  def listen(n) do
    receive do
      :close ->
        if n > 1 do
          listen(n-1)
        end
    end
  end

  @doc """
  init for Supervisor
  """
  def init([]) do
    nil
  end

  @doc """
  creates users in the peer-to-peer network
  """
  def start_link(num_users, max_blocks, agent_pid) do
    {private_keys, public_keys, public_addresses} = generate_keys(num_users, [], [], [])

    keys = %{
      "private_keys" => private_keys,
      "public_keys" => public_keys,
      "public_addresses" => public_addresses
    }

    users = create_users(num_users, max_blocks, agent_pid, keys, [])
    Supervisor.start_link(users, strategy: :one_for_one)
  end

  @doc """
  generates required number of triplets
  """
  def generate_keys(num_users, private_keys, public_keys, public_addresses) do
    if num_users >= 0 do
      {private_key, public_key, public_address} = KeyGenerator.everything()
      generate_keys(num_users - 1, private_keys ++ [private_key], 
      public_keys ++ [public_key], public_addresses ++ [public_address])
    else
      {private_keys, public_keys, public_addresses}
    end
  end


  @doc """
  returns an array of users with initial state
  """
  def create_users(n, max_blocks, agent_pid, keys, users) do
    if n >= 0 do
      public_addresses = Map.get(keys, "public_addresses")
      {my_public_address, other_public_addresses} = List.pop_at(public_addresses, n)

      users = [
        %{
          id: my_public_address,
          start: {User, :start_link,
            [%{
             :wallet => %{
               :private_key => Map.get(keys, "private_keys") |> Enum.at(n),
               :public_key => Map.get(keys, "public_keys") |> Enum.at(n),
               :public_address => my_public_address,
               :my_UTXOs => [],
             },
              :blockchain => [],
              :mempool => %{},
              :public_addresses => other_public_addresses,
              :agent_pid => agent_pid,
              :all_UTXOs => %{},
              :parent => self(),
              :max_blocks => max_blocks,
              :in_progress_block => %{},
              :continue_mining => false,
              :blockhash => [],
              :mining_begin_time => 0
            }]
          }
        }
        | users]

      create_users(n-1, max_blocks, agent_pid, keys, users)
    else
      users
    end
  end

  @doc """
  adds neighbors to the agent map
  """
  def update_agent([child | children], agent_pid, public_addresses) do
    {public_address, pid, _, _} = child
    public_addresses = [public_address] ++ public_addresses
    Neighbors.put(agent_pid, public_address, pid)
    update_agent(children, agent_pid, public_addresses)
  end

  def update_agent([], _, public_addresses), do: public_addresses

  @doc """
  beginning of the bitcoin creation
  """
  def begin(agent_pid, public_addresses) do

    satoshi = Enum.random(public_addresses)
    satoshi_pid = Neighbors.get(agent_pid, satoshi)
    Process.send(satoshi_pid, :genesis, [])
    
  end
end


