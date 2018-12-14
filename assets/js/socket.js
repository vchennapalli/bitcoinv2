// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/web/endpoint.ex":
import {Socket} from "phoenix"

let socket = new Socket("/socket", {params: {token: window.userToken}})

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "lib/web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "lib/web/templates/layout/app.html.eex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/2" function
// in "lib/web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, pass the token on connect as below. Or remove it
// from connect if you don't care about authentication.

socket.connect()

// Now that you are connected, you can join channels with a topic:

let channel = socket.channel(`miningChannel:`,{})
document.getElementById("loginButton").onclick = function(){
  let num = parseInt($("#exampleInputEmail1").val());
  let bnum = parseFloat($("#blockNum").val());
  //window.alert(typeof(num));
  channel.push("mining", {num: num,bnum: bnum});
};

  
channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

var sNum = 1
var tNum = 1
var ts_array = [];
var transCountList = [];
var blockNumList = [];
blockNumList[0] = 0;
transCountList[0] = 0;
var nonceList = [];
nonceList[0] = 0;
var bitcoins = 0
var bitcoins_transacted = 0
document.getElementById("bitcoins").innerHTML = bitcoins
document.getElementById("bitcoins_transacted").innerHTML = bitcoins_transacted

channel.on('mining', msg => {
  // window.alert(msg.height)
  var blockHeight=msg.height
  var bits=msg.bits
  var merkle_root = msg.merkle_root

  var timeS = msg.timeS
  var num_trans = msg.num_transactions
  var blockHash = msg.blockHash
  var prev_blockHash = msg.prev_blockHash
  var minedBy = msg.minedBy
  var nonce = msg.nonce

  var trans_list = msg.transactions

  var comments = "New Block"
  
  if(parseInt(blockHeight) < ts_array.length){
    console.log("discarded")
  }
  else{
    var table=document.getElementById("blocktable")
    var row=table.insertRow(1)

    var cell0=row.insertCell(0)
    var cell1=row.insertCell(1)
    var cell2=row.insertCell(2)
    var cell3=row.insertCell(3)
    var cell4=row.insertCell(4)
    var cell5=row.insertCell(5)
    var cell6=row.insertCell(6)
    var cell7=row.insertCell(7)
    var cell8=row.insertCell(8)
    var cell9=row.insertCell(9)
    var cell10=row.insertCell(10)
  
    cell0.innerHTML= sNum
    cell3.innerHTML = bits
    cell2.innerHTML=merkle_root.toLowerCase()
    cell1.innerHTML=blockHeight

    cell4.innerHTML=timeS
    cell5.innerHTML=num_trans
    cell6.innerHTML=minedBy
    cell7.innerHTML=blockHash
    cell8.innerHTML=prev_blockHash

    //Updating block comments
    // window.alert(blockHeight)
    // window.alert(ts_array.length)
    if(parseInt(blockHeight) == ts_array.length){
    //  if(timeS > ts_array[parseInt(blockHeight)-1]){
    //     comments = "Discarded Block"
    //   }
    //   else{
    //     ts_array[parseInt(blockHeight)-1] = timeS
    //     comments = "This block replaces other blocks with same height"
    //  }
      comments = "Discard Block"
    }
    else{
      ts_array[parseInt(blockHeight)-1] = timeS
        transCountList[parseInt(blockHeight)] = parseInt(num_trans)+transCountList[transCountList.length-1]
        blockNumList[parseInt(blockHeight)] = parseInt(blockHeight)
        nonceList[parseInt(blockHeight)] = parseInt(nonce)
      // window.alert(transCountList)
      //Transaction details are only sent if the block is a new Block
      
      //Updating Total number of botcoins
      bitcoins = bitcoins+50
      document.getElementById("bitcoins").innerHTML = bitcoins

      //variables for transactions
      var senderAdd;
      var receiverAdd;
      var transVal;
      var change_trans;
      var trans_fee;
      var status_trans;

      // console.log(trans_list)
      //for genesis block
      if(trans_list.length == 1){
        status_trans = "Coinbase Transaction"
        senderAdd = "Coinbase"
        receiverAdd = trans_list[0].script_pub_key
        transVal = parseInt(trans_list[0].value)/10000000
        trans_fee = 0
        change_trans = 0
        addTrans(tNum, senderAdd,receiverAdd,transVal,change_trans,trans_fee,status_trans)

        // window.alert(transVal)
        }
        //for other blocks
      else{
        status_trans = "Coinbase and Transfer Fee"
        senderAdd = "Coinbase"
        receiverAdd = trans_list[0].script_pub_key
        transVal = parseInt(trans_list[0].value)/10000000
        trans_fee = transVal-50
        change_trans = 0
        addTrans(tNum, senderAdd,receiverAdd,transVal,change_trans,trans_fee,status_trans)

        //Updating the value of total bitcoins transacted
        bitcoins_transacted = bitcoins_transacted+trans_fee
        document.getElementById("bitcoins_transacted").innerHTML = bitcoins_transacted
        
        for (let i = 1; i < trans_list.length; i++) {
          status_trans = "Transaction"
          senderAdd = trans_list[i].script_pub_key
          transVal =  parseInt(trans_list[i].value)/10000000
          i++
          receiverAdd = trans_list[i].script_pub_key
          change_trans = parseInt(trans_list[i].value)/10000000
          trans_fee = ((change_trans+transVal)*2)/98
          addTrans(tNum, senderAdd,receiverAdd,transVal,change_trans,trans_fee,status_trans)

          //updating bitcoins transacted
          bitcoins_transacted = bitcoins_transacted+transVal
          bitcoins_transacted = Math.floor(bitcoins_transacted * 10000) / 10000
          document.getElementById("bitcoins_transacted").innerHTML = bitcoins_transacted
        }
      }

    
      // cell0.innerHTML= tNum
      // cell1.innerHTML = senderAdd
      // cell2.innerHTML = receiverAdd
      // cell3.innerHTML = transVal
      // cell4.innerHTML = change_trans
      // cell5.innerHTML = trans_fee
      // cell6.innerHTML = status_trans

      tNum = tNum+1

    }
  
    sNum = sNum+1
    //Adding status of block and nonce
    cell9.innerHTML=comments
    cell10.innerHTML=nonce

    // console.log(trans_list)
   //function for inserting element to the table
  
   function addTrans(tNum, senderAdd,receiverAdd,transVal,change_trans,trans_fee,status_trans) {
      var table=document.getElementById("transtable")
      var row=table.insertRow(1)

      var cell0=row.insertCell(0)
      var cell1=row.insertCell(1)
      var cell2=row.insertCell(2)
      var cell3=row.insertCell(3)
      var cell4=row.insertCell(4)
      var cell5=row.insertCell(5)
      var cell6=row.insertCell(6)

      cell0.innerHTML= tNum
      cell1.innerHTML = senderAdd
      cell2.innerHTML = receiverAdd
      cell3.innerHTML = transVal
      cell4.innerHTML = change_trans
      cell5.innerHTML = trans_fee
      cell6.innerHTML = status_trans
    }

    var mynonceChart = new Chart(nonceChart, {
     type: 'bar',
      data: {
        labels: blockNumList,
        text: "Nunber of blocks",
        datasets: [{ 
            data: nonceList,
            label: "Nonce",
            backgroundColor: "#2229e8",
            fill: true
          }
        ]
      },
      options: {
        title: {
          display: true,
          text: 'Nonce for Each Block'
        },
        responsive:true,
      }
   })

    var mytransactionChart = new Chart(transactionChart, {
     type: 'line',
      data: {
        labels: blockNumList,
        text: "Number of blocks",
        datasets: [{ 
            data: transCountList,
            label: "Number of transactions",
            borderColor: "#3e95cd",
            fill: false
          }
       ]
      },
      options: {
        title: {
         display: true,
         text: 'Number of Successful Transactions after Every Block'
        },
        responsive:true,
      }
    })
  
    //window.createSocket = createSocket;
  }
})

//Timing graphs
var time_height_list = []
var time_list = []

time_height_list[0]=0
time_list[0] = 0

var time_var
var time_height

channel.on("mining:time", payload => {
  time_var = parseInt(payload.time)/1000000
  time_height = payload.height

  if(time_height == time_height_list.length){

    //Adding two height and time to their respecetive lists
    time_height_list[time_height] = time_height
    time_list[time_height] = time_var


    //Js code for the time graph
    var mytimeChart = new Chart(timeChart, {
      type: 'bar',
       data: {
         labels: time_height_list,
         text: "Block Numbers",
         datasets: [{ 
             data: time_list,
             label: "Time Taken to Mine per Block",
             backgroundColor: "#f47442",
             fill: true
           }
        ]
       },
       options: {
         title: {
          display: true,
          text: 'Time to mine a block in seconds'
         },
         responsive:true,
       }
     })
  }
  else{
    
  }

})

export default socket