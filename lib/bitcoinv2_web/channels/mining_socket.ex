defmodule Bitcoinv2Web.MiningSocket do
    use Phoenix.Channel

    def join("miningChannel:", _params, socket) do
        {:ok, %{},socket}
    end

    def handle_in("mining",%{"num" => num, "bnum" => bnum}, socket) do
        # IO.puts "+++++++++++++++++++++++++"
        Bitcoin.main(num,bnum)
        {:noreply, socket}
      end

    def handle_in("mining:time",%{"num" => num}, socket) do
        IO.puts "+++++++++++++++++++++++++"
       #Bitcoin.main(num)
       {:noreply, socket}
    end


end
