defmodule Mining do
    alias Helper, as: H
    @doc """
    takes in a new block and returns the block with its nonce
    """
    def mine(header) do
        version = header[:version]
        previous_block_hash = header[:previous_block_hash]
        merkle_root = header[:merkle_root]
        timestamp = header[:timestamp]
        bits = header[:bits]
        nonce = header[:nonce]
        generate_proof_of_work(version, previous_block_hash, merkle_root, timestamp, bits, nonce)
    end

    @doc """
    recursive method that generates the appropriate nonce
    """
    def generate_proof_of_work(v, pbh, mr, t, bits, n) do
        
        hash = "#{v}#{pbh}#{mr}#{t}#{n}" |> H.double_hash(:sha256) |> Base.encode16
        
        if(hash < bits) do
            # IO.inspect hash
            n
        else
            n = n + 1
            generate_proof_of_work(v, pbh, mr, t, bits, n)
        end
    end

    @doc """
    checks if the pow is valid or not. If not, increases the nonce and checks 
    pow of that in the next callback.
    """
    def check_proof_of_work(state) do
        block = state[:in_progress_block]
        header = block[:header]
        v = header[:version]
        pbh = header[:previous_block_hash]
        mr = header[:merkle_root]
        t = header[:timestamp]
        bits = header[:bits]
        n = header[:nonce]

        hash = "#{v}#{pbh}#{mr}#{t}#{n}" |> H.double_hash(:sha256) |> Base.encode16

        if hash < bits do
            {true, state}
        else
            state = put_in(state, [:in_progress_block, :header, :nonce], n+1)
            {false, state}
        end
    end


end