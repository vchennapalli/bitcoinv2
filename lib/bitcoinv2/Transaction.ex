defmodule Transaction do
  alias KeyGenerator, as: KG
  alias Helper, as: H
  alias Block, as: B
  @moduledoc """
  contains all the functionality relevant to transactions
  """
  @templates %{
    :transaction => %{
      :version => 1,
      :input_counter => 0,
      :inputs => [],
      :output_counter => 0,
      :outputs => [],
    },

    :input => %{
      :tx_hash => nil,
      :tx_output_n => nil,
      :value => nil,
      :script_sig => nil
    },

    :output => %{
      :value => nil,
      :tx_output_n => nil,
      :script_pub_key => nil
    },

    :coinbase_transaction => %{
      :version => 1,
      :input_counter => 1,
      :inputs => [%{
        :tx_hash => 0x00,
        :tx_output_n => 0xFFFFFFFF,
        :coinbase => nil
      }],
      :output_counter => 1,
      :outputs => [%{
        :value => 500000000,
        :tx_output_n => 0,
        :script_pub_key => nil
      }]
    },

    :UTXO => %{
      :tx_hash => nil,
      :tx_output_n => nil,
      :script_pub_key => nil,
      :value => nil,
      :confirmations => nil
    }
  }


  @doc """
  creates a transaction
  """
  def initiate_transaction(state) do
    receiver_address = select_receiver(state)
    {my_UTXOs, state} = select_UTXOs(state)
    transaction = Map.get(@templates, :transaction)

    {inputs, value} = construct_transaction_inputs(state, my_UTXOs, [], 0)
    
    my_address = get_in(state, [:wallet, :public_address])

    if value > 3 do
      transaction_fee = max(:math.floor(0.02 * value) |> round(), 1)
      change = (value - transaction_fee) / 2 |> round()
      non_change = value - change - transaction_fee
      value_split = [non_change, change]
      receiver_addresses = [receiver_address, my_address]
      outputs = construct_transaction_outputs(value_split, receiver_addresses, [], 0)

      transaction = Map.put(transaction, :input_counter, length(inputs))
      transaction = Map.put(transaction, :output_counter, length(outputs))
      transaction = Map.put(transaction, :inputs, inputs)
      transaction = Map.put(transaction, :outputs, outputs)
      #IO.puts "Transaction of value #{value} initiated by #{my_address}. #{non_change} sent to #{receiver_address}. #{change} sent back to #{my_address}. #{transaction_fee} left for the miner"
      {transaction, state}
    else
      {nil, state}
    end
  end


  @doc """
  uses UTXOs to construct input list for a transaction
  """
  def construct_transaction_inputs(state, my_UTXOs, inputs, value) do
    if my_UTXOs == nil or length(my_UTXOs) == 0 do
      {inputs, value}
    else
      [single_UTXO | remaining_UTXOs] = my_UTXOs
      input = Map.get(@templates, :input)

      tx_hash = single_UTXO[:tx_hash]
      input = Map.put(input, :tx_hash, tx_hash)

      tx_output_n = single_UTXO[:tx_output_n]
      input = Map.put(input, :tx_output_n, tx_output_n)

      message = "#{tx_hash}:#{tx_output_n}"
      public_key = get_in(state, [:wallet, :public_key])
      private_key = get_in(state, [:wallet, :private_key])
      signature = :crypto.sign(:ecdsa, :sha256, message, [private_key, :secp256k1])
      script_sig = public_key <> signature
      input = Map.put(input, :script_sig, script_sig)
      
      v = Map.get(single_UTXO, :value)
      input = Map.put(input, :value, v)

      value = value + v

      inputs = inputs ++ [input]
      construct_transaction_inputs(state, remaining_UTXOs, inputs, value)
    end

  end

  @doc """
  uses the value_split and the receiver addresses to construct
  the output list of a transaction
  """
  def construct_transaction_outputs(value_split, receiver_addresses, outputs, idx) do
    if length(value_split) == 0 do
      outputs
    else
      [value | remaining_value_split] = value_split
      [receiver_address | remaining_receiver_addresses] = receiver_addresses
      output = Map.get(@templates, :output)
      output = Map.put(output, :value, value)
      output = Map.put(output, :tx_output_n, idx)
      output = Map.put(output, :script_pub_key, receiver_address)
      outputs = outputs ++ [output]
      construct_transaction_outputs(remaining_value_split, remaining_receiver_addresses, outputs, idx+1)
    end
  end

  @doc """
  selects a receiver from a list of public addresses
  """
  def select_receiver(state) do
    public_addresses = Map.get(state, :public_addresses)
    Enum.random(public_addresses)
  end

  @doc """
  selects an unused UTXO
  TODO: - more than one UTXO if possible
        - selecting based on number of confirmations
  """
  def select_UTXOs(state) do
    my_UTXOs = get_in(state, [:wallet, :my_UTXOs])
    len = length(my_UTXOs)
    if len > 0 do
      input = Enum.random(my_UTXOs)
      remaining_UTXOs = List.delete(my_UTXOs, input)
      state = put_in(state, [:wallet, :my_UTXOs], remaining_UTXOs)
      {[input], state}
    else
      {nil, state}
    end
  end


  @doc """
  generates new UTXOs from a transaction and adds them TO GLOBAL UTXOs
  """
  def add_UTXOs(all_UTXOs, transaction) do
    tx_hash = H.transaction_hash(transaction, :sha256)
    outputs = transaction[:outputs]
    new_UTXOs = extract_UTXOs(tx_hash, outputs, 0, %{})
    Map.merge(all_UTXOs, new_UTXOs)
  end


  @doc """
  extracts UTXOs from the outputs of a transaction and returns them
  """
  def extract_UTXOs(tx_hash, outputs, idx, new_UTXOs) do
    if length(outputs) == 0 do
      new_UTXOs
    else
      [output | r_outputs] = outputs
      new_UTXO = @templates[:UTXO]
      new_UTXO = Map.merge(new_UTXO, %{
        :tx_hash => tx_hash,
        :tx_output_n => idx,
        :script_pub_key => output[:script_pub_key],
        :value => output[:value],
        :confirmations => 0
      })
      
      new_UTXOs = Map.put(new_UTXOs, "#{tx_hash}:#{idx}", new_UTXO)
      extract_UTXOs(tx_hash, r_outputs, idx+1, new_UTXOs)
    end
  end

  @doc """
  removes the UTXOs corresponding to the inputs FROM GLOBAL UTXOs
  """
  def remove_input_UTXOs(all_UTXOs, inputs) do
    if length(inputs) == 0 do
      all_UTXOs
    else
      [input | r_inputs] = inputs
      tx_hash = Map.get(input, :tx_hash)
      tx_output_n = Map.get(input, :tx_output_n)

      all_UTXOs = Map.delete(all_UTXOs, "#{tx_hash}:#{tx_output_n}")
      remove_input_UTXOs(all_UTXOs, r_inputs)
    end
  end
  

  @doc """
  updates the global UTXOs by removing UTXO that corresponds
  to input and adding output as new UTXO
  """
  def update_global_UTXOs(state, transaction) do
    all_UTXOs = Map.get(state, :all_UTXOs)

    inputs = Map.get(transaction, :inputs)
    all_UTXOs = remove_input_UTXOs(all_UTXOs, inputs)

    state = Map.put(state, :all_UTXOs, all_UTXOs)
    all_UTXOs = add_UTXOs(all_UTXOs, transaction)
    Map.put(state, :all_UTXOs, all_UTXOs)
  end


  @doc """
  updates local mempool afte
  """
  def update_local_UTXOs(state, tx_hash, outputs) do
    if length(outputs) == 0 do
      state
    else
      [output | r_outputs] = outputs
      script_pub_key = output[:script_pub_key]
      my_public_address = get_in(state, [:wallet, :public_address])
      
      state = 
      if script_pub_key == my_public_address do
        my_UTXOs = get_in(state, [:wallet, :my_UTXOs])

        new_UTXO = @templates[:UTXO]
        new_UTXO = Map.merge(new_UTXO, %{
          :tx_hash => tx_hash,
          :tx_output_n => output[:tx_output_n],
          :script_pub_key => output[:script_pub_key],
          :value => output[:value],
          :confirmations => 0
        })
        my_UTXOs = my_UTXOs ++ [new_UTXO]
        put_in(state, [:wallet, :my_UTXOs], my_UTXOs)
      else
        state
      end

      update_local_UTXOs(state, tx_hash, r_outputs)
    end
  end


  @doc """
  receives transaction sent by a user to anonymous user
  """
  def receive_transaction(state, transaction) do
    if validate_transaction(transaction) do # TODO and verify_transaction(state, transaction) do
      trasaction_hash = H.transaction_hash(transaction, :sha256)
      mempool = Map.get(state, :mempool)
      mempool = Map.put(mempool, trasaction_hash, transaction)
      outputs = transaction[:outputs]
      tx_hash = H.transaction_hash(transaction, :sha256)
      state = update_local_UTXOs(state, tx_hash,outputs)
      state = update_global_UTXOs(state, transaction)
      Map.put(state, :mempool, mempool)
    else
      state
    end
  end



  # --------------------VERIFICATION & VALIDATION BEGIN----------------------

  @doc """
  validates every transaction before adding to mempool
  - input_counter = len(inputs)
  - output_counter = len(outputs)
  - validation of structure
  """
  def validate_transaction(transaction) do
    v = Map.get(transaction, :version)
    ic = Map.get(transaction, :input_counter)
    i = Map.get(transaction, :inputs)
    oc = Map.get(transaction, :output_counter)
    o = Map.get(transaction, :outputs)
    l = Map.get(transaction, :locktime)


    if (v == nil or
      i == [] or
      i == nil or
      ic == nil or
      oc == nil or
      o == [] or
      o == nil or
      map_size(transaction) != 5 or
      ic != length(i) or
      oc != length(o)) do
      false
    else
      validate_inputs(transaction) and validate_outputs(transaction)
    end
  end

  @doc """
  validate inputs in the transaction
  """
  def validate_inputs(transaction) do
    num_inputs = length(transaction[:inputs])
    input_counter = transaction[:input_counter]
    num_inputs == input_counter
  end

  @doc """
  validate outputs in the transaction
  """
  def validate_outputs(transaction) do
    num_outputs = length(transaction[:outputs])
    output_counter = transaction[:output_counter]
    num_outputs == output_counter
  end


  @doc """
  verifies every transaction by checking the two scripts
  - locking and unlocking script
  - presence of the input in the global pool
  - sum of inputs >= sum of outputs
  """
  def verify_transaction(state, transaction) do
    inputs = Map.get(transaction, :inputs)
    all_UTXOs = Map.get(state, :all_UTXOs)

    validity = verify_all_UTXOs(all_UTXOs, inputs, true)
    
    if validity do
      total_input_value = get_tx_input_value(inputs, 0)
      outputs = Map.get(transaction, :outputs)
      total_output_value = get_tx_output_value(outputs, 0)
      total_input_value >= total_output_value
    else
      validity
    end
  end

  @doc """
  verifies presence of input in the global UTXOs pool
  """
  def verify_all_UTXOs(all_UTXOs, inputs, validity) do
    if length(inputs) == 0 or validity == false do
      validity
    else
      [input | remaining_inputs] = inputs
      tx_hash = Map.get(input, :tx_hash)
      tx_output_n = Map.get(input, :tx_output_n)
      key = "#{tx_hash}:#{tx_output_n}"

      single_UTXO = Map.get(all_UTXOs, key)
      
      validity =
      if (single_UTXO !== nil) do
        verify_single_UTXO(single_UTXO, input, key)
      else
        false
      end

      verify_all_UTXOs(all_UTXOs, remaining_inputs, validity)
    end
  end

  @doc """
  verifies the combination of locking and unlocking script
  """
  def verify_single_UTXO(single_UTXO, input, message) do
    script_pub_key = Map.get(single_UTXO, :script_public_key)
    script_sig = Map.get(input, :script_sig)
    <<public_key::bytes-size(65), signature::binary>> = script_sig
    public_address = public_key |> KG.generate_public_hash() |> KG.generate_public_address()

    if public_address != script_pub_key do
      false
    else
      :crypto.verify(:ecdsa, :sha256, message, signature, [public_key, :secp256k1])
    end
  end


# --------------------VERIFICATION & VALIDATION END----------------------

# --------------------COINBASE TRANSACTION BEGIN-------------------------

  @doc """
  generates coinbase transaction
  """
  def generate_coinbase_transaction(state, transactions) do
    public_address = get_in(state, [:wallet, :public_address])
    transactions_fee = get_all_transactions_fee(transactions, 0)
    transaction = Map.get(@templates, :coinbase_transaction)
    outputs = Map.get(transaction, :outputs)
    [output | _] = outputs
    value = Map.get(output, :value)
    value = value + transactions_fee
    [input | _] = Map.get(transaction, :inputs)
    input = Map.put(input, :coinbase, "efa87c2618300197")
    transaction = Map.put(transaction, :inputs, [input])
    output = Map.put(output, :value, value)
    output = Map.put(output, :script_pub_key, public_address)
    transaction = Map.put(transaction, :outputs, [output])
    
    {state, transaction}
  end


  @doc """
  verifies and validates coinbase transaction
  """
  def validate_coinbase(transaction) do
    input_counter = Map.get(transaction, :input_counter)
    output_counter = Map.get(transaction, :output_counter)
    inputs = Map.get(transaction, :inputs)
    outputs = Map.get(transaction, :outputs)
    version = Map.get(transaction, :version)
    length(inputs) == input_counter and length(outputs) == output_counter and version != nil
  end

  @doc """
  returns the transaction fees of all transactions
  """
  def get_all_transactions_fee(transactions, fees) do
    if length(transactions) == 0 do
      fees
    else
      [transaction | transactions] = transactions
      single_tx_fee = get_one_transaction_fee(transaction)
      get_all_transactions_fee(transactions, fees + single_tx_fee)
    end
  end

  @doc """
  returns fee of single transaction
  """
  def get_one_transaction_fee(transaction) do
    inputs = Map.get(transaction, :inputs)
    outputs = Map.get(transaction, :outputs)
    input_value = get_tx_input_value(inputs, 0)
    output_value = get_tx_output_value(outputs, 0)
    input_value - output_value
  end

  @doc """
  returns total input value of single transaction
  """
  def get_tx_input_value(inputs, value) do
    if length(inputs) == 0 do
      value
    else
      [input | inputs] = inputs
      single_value = Map.get(input, :value)
      get_tx_input_value(inputs, value + single_value)
    end
  end

  @doc """
  returns total value of single transaction
  """
  def get_tx_output_value(outputs, value) do
    if length(outputs) == 0 do
      value
    else
      [output | outputs] = outputs
      single_value = Map.get(output, :value)
      get_tx_output_value(outputs, value + single_value)
    end
  end
end


# --------------------COINBASE TRANSACTION END---------------------------