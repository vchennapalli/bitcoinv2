defmodule Helper do

  @moduledoc """
  contains common helper functions
  """

  @doc """
  facilitates piping
  """
  def hash(data, algorithm), do: :crypto.hash(algorithm, data)

  @doc """
  facilitates merkle parent calculation
  """
  def double_hash(data, algorithm) do
    data |> hash(algorithm) |> hash(algorithm)
  end
  
  @doc """
  returns hash of a normal transaction
  """
  def transaction_hash(transaction, algorithm) do
    cond do
      is_map(transaction) ->
        v = transaction[:version]
        ic = transaction[:input_counter]
        i = get_inputs_string(transaction[:inputs], "")
        oc = transaction[:output_counter]
        o = get_outputs_string(transaction[:outputs], "")
        "#{v}#{ic}#{i}#{oc}#{o}" |> double_hash(algorithm)
      is_binary(transaction) ->
        transaction |> double_hash(algorithm)    
    end
  end

  @doc """
  returns inputs in string format
  """
  def get_inputs_string(inputs, string) do
    if length(inputs) == 0 do
      string
    else
      [input | r_inputs] = inputs
      tx = input[:tx_hash]
      n = input[:tx_output_n]
      s = 
        if input[:script_sig] == nil do
          input[:coinbase]
        else
          input[:script_sig]
        end
      
      string = string <> "#{tx}#{n}#{s}"
      get_inputs_string(r_inputs, string)
    end
  end

  @doc """
  returns outputs in string format
  """
  def get_outputs_string(outputs, string) do
    if length(outputs) == 0 do
      string
    else
      [output | r_outputs] = outputs
      v = output[:value]
      n = output[:tx_output_n]
      k = output[:script_pub_key]

      string = string <> "#{v}#{n}#{k}"
      get_outputs_string(r_outputs, string)
    end
  end


end
