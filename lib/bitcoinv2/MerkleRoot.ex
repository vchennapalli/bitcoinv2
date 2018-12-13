defmodule MerkleRoot do
  alias Helper, as: H
  @moduledoc """
  functionality for generating merkle root of a list of transactions
  """

  @doc """
  returns merkle root of raw transactions
  """
  def get_root(transactions) do
    if length(transactions) == 1 do
      [coinbase | _] = transactions
      coinbase |> H.transaction_hash(:sha256)
    else
      construct_tree(transactions, [])
    end
  end

  @doc """
  generates merkle parent(s) when there are multiple children
  """
  def construct_tree([child1, child2 | children], parents) do
    child1_hash = child1 |> H.transaction_hash(:sha256)
    child2_hash = child2 |> H.transaction_hash(:sha256)

    parent = "#{child1_hash}#{child2_hash}" |> H.transaction_hash(:sha256)
    parents = parents ++ [parent]
    construct_tree(children, parents)
  end

  @doc """
  generates merkle parent when there is one child
  """
  def construct_tree([child], parents) do
    if length(parents) == 0 do
      child
    else
      child_hash = child |> H.transaction_hash(:sha256)
      parent = "#{child_hash}#{child_hash}" |> H.transaction_hash(:sha256)
      parents = parents ++ [parent]
      construct_tree(parents, [])
    end
  end

  @doc """
  generates merkle grandparent(s)
  """
  def construct_tree([], parents) do
    construct_tree(parents, [])
  end
end
