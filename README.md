# Bitcoinv2

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create`
  * If hex is not available use `mix archive.install https://github.com/phoenixframework/archives/raw/master/phx_new.ez `
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Phoenix interface:
•	Enter the number of node and the number of the blocks until which the program must run and click submit.
•	The total bitcoins mined shows the number of bitcoins mined and the total bitcoins transacted and validated are shown.
•	Block details table updates the table as soon a new block is mined. Height of the block, merkel root value of the transaction bits mention the difficulty, mined by shows the id of the node which has mined the blocked, Transaction value- the amount intended to be sent to the receiver, Change – the amount which the sender gets back it itself and the transaction fee mention which the miner receives.
•	Transaction table updates the transactions details. It shows sender’s address, receiver’s address  
•	Time to mine a block shows the time taken to mine the valid block.


## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: http://phoenixframework.org/docs/overview
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix

