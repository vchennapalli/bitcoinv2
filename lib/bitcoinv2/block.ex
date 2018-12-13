defmodule Block do
    alias Helper, as: H
    alias Transaction, as: T
    alias MerkleRoot, as: MR
    alias Mining, as: M

    @moduledoc """
    contains all functionality related to block handling
    """
    @template %{
      :new_block => %{
        :header => %{
          :version => 1,
          :previous_block_hash => "0000000000000000000000000000000000000000000000000000000000000000",
          :merkle_root => nil,
          :timestamp => nil,
          :bits => "0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
          :nonce => 0
        },
        :num_transactions => nil,
        :transactions => []
      }
    }

    @tpb 4 #transactions per block, including coinbase transaction

    @doc """
    creates a block
    """
    def create(state) do
      # 1st transaction is reward + fees
      mempool = Map.get(state, :mempool)
      mempool_list = Map.to_list(mempool)
      {transactions, keys} = select_transactions(mempool_list, [], [])
      mempool = Map.drop(mempool, keys)
      state = Map.put(state, :mempool, mempool)

      {state, coinbase_transaction} = T.generate_coinbase_transaction(state, transactions)
      transactions = [coinbase_transaction] ++ transactions
      merkle_root = transactions |> MR.get_root()
      block = Map.get(@template, :new_block)
      block = Map.merge(block, %{
        :num_transactions => length(transactions),
        :transactions => transactions
      })

      blockchain = Map.get(state, :blockchain)
      header = Map.get(block, :header)

      pbh = 
        if length(blockchain) == 0 do
          Map.get(header, :previous_block_hash)
        else
          [last_block] = Enum.take(blockchain, -1)
          calculate_block_hash(last_block[:header])
        end

      header = Map.merge(header, %{
        :merkle_root => merkle_root,
        :timestamp => DateTime.utc_now(),
        :previous_block_hash => pbh
      })

      block = Map.put(block, :header, header)

      state = Map.merge(state, 
        %{:in_progress_block => block,
          :continue_mining => true})
      
      state
    end

    def add_to_blockchain(state) do
      block = state[:in_progress_block]
      header = block[:header]
      my_address = get_in(state, [:wallet, :public_address])
      blockchain = state[:blockchain]
      blockchain = blockchain ++ [block]

      blockhash = state[:blockhash]
      # bH = state[:blockhash]
      # IO.puts "headerseeeee"
      # IO.inspect header
      # IO.inspect bH
      pbh = get_in(block, [:header, :previous_block_hash])
      blockhash = blockhash ++ [pbh]
      state = Map.put(state, :blockhash, blockhash)
      # IO.inspect pbh
      height = length(blockchain)
      
      state = Map.put(state, :blockchain, blockchain)
      [coinbase_tx | _] = block[:transactions]
      state = T.update_global_UTXOs(state, coinbase_tx)
      coinbase_tx_hash = H.transaction_hash(coinbase_tx, :sha256)
      state = T.update_local_UTXOs(state, coinbase_tx_hash, coinbase_tx[:outputs])

      IO.puts "Block mined by #{my_address} with #{height}"
      
      trans = GetTransactions.getTrans(block.transactions,[])
      
      mr = block.header.merkle_root
      [cblock] = Enum.take(blockchain, -1)
      chash = calculate_block_hash(cblock[:header])
      Bitcoinv2Web.Endpoint.broadcast "miningChannel:" , "mining", %{
        bits: block.header.bits,
        merkle_root: Base.encode16(mr),    
        height: height,
  
        prev_blockHash: header.previous_block_hash,
        timeS: block.header.timestamp,
        num_transactions: block.num_transactions,
        blockHash: chash,
        minedBy: my_address,
        nonce: block.header.nonce,
        transactions: trans
  
      }
      
      {state, block, height}

    end

    @doc """
    creates a genesis block
    """
    def create_genesis_block(state) do
      mempool = Map.get(state, :mempool)
      mempool_list = Map.to_list(mempool)
      {transactions, keys} = select_transactions(mempool_list, [], [])
      mempool = Map.drop(mempool, keys)
      state = Map.put(state, :mempool, mempool)

      {state, coinbase_transaction} = T.generate_coinbase_transaction(state, transactions)
      transactions = [coinbase_transaction] ++ transactions
      merkle_root = transactions |> MR.get_root()
      block = Map.get(@template, :new_block)
      block = Map.merge(block, %{
        :num_transactions => length(transactions),
        :transactions => transactions
      })

      blockchain = Map.get(state, :blockchain)
      header = Map.get(block, :header)

      pbh = 
        if length(blockchain) == 0 do
          Map.get(header, :previous_block_hash)
        else
          [last_block] = Enum.take(blockchain, -1)
          calculate_block_hash(last_block[:header])
        end
        
      header = Map.merge(header, %{
        :merkle_root => merkle_root,
        :timestamp => DateTime.utc_now(),
        :previous_block_hash => pbh
      })

      nonce = M.mine(header)
      # hash = "#{header[:version]}#{header[:previous_block_hash]}#{header[:merkle_root]}#{header[:timestamp]}#{header[:nonce]}" |> H.double_hash(:sha256) |> Base.encode16
      # IO.inspect hash
      my_address = get_in(state, [:wallet, :public_address])

      header = Map.put(header, :nonce, nonce)
      block = Map.put(block, :header, header)
      blockchain = blockchain ++ [block]

      blockhash = state[:blockhash]
      pbh = get_in(block, [:header, :previous_block_hash])
      blockhash = blockhash ++ [pbh]
      state = Map.put(state, :blockhash, blockhash)

      height = length(blockchain)
      state = Map.put(state, :blockchain, blockchain)
      state = T.update_global_UTXOs(state, coinbase_transaction)
      coinbase_tx_hash = H.transaction_hash(coinbase_transaction, :sha256)
      state = T.update_local_UTXOs(state, coinbase_tx_hash, coinbase_transaction[:outputs])
      # IO.puts "Genesis Block created by #{my_address}"

      [cblock] = Enum.take(blockchain, -1)
      chash = calculate_block_hash(cblock[:header])

      trans = GetTransactions.getTrans(block.transactions,[])
      Bitcoinv2Web.Endpoint.broadcast "miningChannel:" , "mining", %{
        
        bits: block.header.bits,
        merkle_root: Base.encode16(merkle_root),    
        height: height,
  
        prev_blockHash: header.previous_block_hash,
        timeS: block.header.timestamp,
        num_transactions: block.num_transactions,
        blockHash: chash ,
        minedBy: my_address,
        nonce: nonce,
        transactions: trans
  
      }
      {state, block, height}
    end

    @doc """
    selects atmost 4 transactions from mempool 
    """
    def select_transactions(mempool, transactions, keys) do
        cond do
            length(transactions) == @tpb -> {transactions, keys}
            length(mempool) == 0 -> {transactions, keys}
            true ->
                [{key, transaction} | mempool] = mempool
                select_transactions(mempool, transactions ++ [transaction], keys ++ [key])
        end
    end


    @doc """
    returns the hash of the header of the block
    """
    def calculate_block_hash(header) do
      v = header[:version]
      pbh = header[:previous_block_hash]
      mr = header[:merkle_root]
      t = header[:timestamp]
      n = header[:nonce]

      "#{v}#{pbh}#{mr}#{t}#{n}" |> H.double_hash(:sha256) |> Base.encode16
    end

    @doc """
    receives new block from a neighbor
    """
    def receive(state, block, height) do
      blockchain = state[:blockchain]
      public_address = get_in(state, [:wallet, :public_address])

      cond do
        length(blockchain) < height and validate(block) ->
          mempool = Map.get(state, :mempool)
          in_progress_block = Map.get(state, :in_progress_block)

          #IO.puts "A valid block received by #{public_address}"
          
          mempool = 
            if map_size(in_progress_block) != 0 do
              [_ | transactions] = get_in(state, [:in_progress_block, :transactions])
              adjust_mempool(mempool, transactions, :add)
            else
              mempool
            end
          
          state = Map.merge(state, %{
            :in_progress_block => %{},
            :continue_mining => false})

          # delete the blocked transactions
          [coinbase | transactions] = Map.get(block, :transactions)
          
          mempool = adjust_mempool(mempool, transactions, :delete)

          state = Map.put(state, :mempool, mempool)

          state = T.update_global_UTXOs(state, coinbase)

          blockchain = blockchain ++ [block]
          state = Map.put(state, :blockchain, blockchain)

          blockhash = state[:blockhash]
          pbh = get_in(block, [:header, :previous_block_hash])
          blockhash = blockhash ++ [pbh]
          Map.put(state, :blockhash, blockhash)

        length(blockchain) == height and validate(block) ->
          state
        true -> 
          state
      end
      
    end


    @doc """
    updates the mempool
    """
    def adjust_mempool(mempool, transactions, tag) do
      if length(transactions) == 0 do
        mempool
      else
        [transaction | transactions] = transactions
        tx_hash = H.transaction_hash(transaction, :sha256)
        
        mempool = 
        case tag do
          :delete ->     
            Map.delete(mempool, tx_hash)
          :add ->
            Map.put(mempool, tx_hash, transaction)
        end

        adjust_mempool(mempool, transactions, tag)
      end
    end


    @doc """
    validates the received block
    """
    def validate(block) do
      validate_syntax(block) and validate_transaction_inclusion(block) 
      and validate_pow(block)

    end

    @doc """
    checks if the block is syntatically correct
    """
    def validate_syntax(block) do
      header = block[:header]

      header[:version] != nil and header[:previous_block_hash] != nil and
      header[:merkle_root] != nil and header[:timestamp] != nil  and 
      header[:bits] != nil and header[:nonce] != nil and 
      block[:num_transactions] > 0 and block[:num_transactions] == length(block[:transactions])
      and map_size(header) == 6 and map_size(block) == 3
    end

    @doc """
    checks if every transaction mentioned in the block is considered
    while calculating the merkle root
    """
    def validate_transaction_inclusion(block) do
      transactions = Map.get(block, :transactions)
      given_merkle_root = get_in(block, [:header, :merkle_root])
      calculated_merkle_root = MR.get_root(transactions)
      given_merkle_root == calculated_merkle_root
    end

    @doc """
    checks if the proof of work was calculated correctly
    """
    def validate_pow(block) do
      header = block[:header]
      nonce = header[:nonce]
      nonce == M.mine(header)
    end

  end