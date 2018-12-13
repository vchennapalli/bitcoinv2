defmodule GetTransactions do
    def getTrans([head|tail],res) do
        res = res ++ head.outputs
        getTrans(tail,res)
    end

    def getTrans([],res)do
        res
    end
    
end
