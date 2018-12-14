# Bitcoin

COP5615 - Project 4.2 

# Group

Akshay Rechintala - 4581 6988
Vineeth Chennapalli - 3124 2465


# Background, Distribution Protocl, Transaction & Block Mining Scenarios Details

1. In the first part of the project, we implemented functionality components for the bitcoin network protocol. Various test cases were considered to test the functionality.

2. In this part, we completed the distribution protocol and considered various transaction types while constructing transactions and blocks. 

  Trasaction Types:
  - A normal transaction which has two output components: 
    - one to a neighbor
    - one to self, which is change
    - Also, there is a trasaction cost per transaction that is awarded to the first person who mines it.
  - Coinbase transaction
    - UTXO that's awarded to the miner, along with the total transaction reward of all the transactions in the block.

  Mining Scenarios:
    - In out model, all the nodes are miners and users. Every transaction block consists of 5 transactions, of which one is the coinbase transaction. Everyone begins mining, and the node that
    find the suitable nonce broadcasts the blokc to all the nodes. There are two scenarios that occur
    here
      - When only one node mines and sends it to all the nodes before any other node mines their own
      block. In this case, the block that's broadcasted is received by all the nodes and mining is stopped. 
      - When one node mines and by the times it's received by all the users, another node (or more) mines a block and broadcasts it. In this scenario, the block that's first received at the specific height is considered to be part of the blockchain. And it has been noticed that there exists a consistency in this scenario where the first block is first received by all the nodes followed by the other block. Thus, the second block is discarded.

  The details of the transactions and the blocks that get mined (and discarded in some cases) can be seen in the web interface clearly.

3. With regard to the testcases and the various scenarios, tests were performed in the first part of the project. Transaction validity and verification, and block validity and verification have been considered comprehensively. Forking was dealt with in the functional test in 4.1. For more details, please take a look at 4.1

# Steps To Begin Server & Perform Simulation

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create`
  * If hex is not available use `mix archive.install https://github.com/phoenixframework/archives/raw/master/phx_new.ez `
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Phoenix interface:
•	Enter the number of nodes and the number of the blocks until which the program must run and click 'Begin Simulation'.
•	The total bitcoins mined shows the number of bitcoins mined and the total bitcoins transacted and validated are shown.

Tables
•	Block details table updates the table as soon a new block is mined. Height of the block, merkel root value of the transaction bits mention the difficulty, mined by shows the id of the node which has mined the blocked. 
•	Transaction table updates the transactions details. It shows block to which it belongs, sender’s address, receiver’s address, transaction value (the amount sent to the receiver), change (the amount which the sender gets back to himself) and transaction fee (reward that the miner receives).

Graphs
•	Time to mine a block shows the time taken to mine the valid block.
• Nonce for each block shows the nonce of each block with which the block was solved.
• Number of successful transactions shows a liner graph (except for the first block which has only one transaction), with each block consisting of 5 successful transactions.