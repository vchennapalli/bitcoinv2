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
  //window.alert(typeof(num));
  channel.push("mining", {num: num});
};

  
channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

var sNum = 1
var ts_array = [];
var transCountList = [];
var blockNumList = [];
blockNumList[0] = 0;
transCountList[0] = 0;
var nonceList = [];
nonceList[0] = 0;


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
     if(timeS > ts_array[parseInt(blockHeight)-1]){
        comments = "Discarded Block"
      }
      else{
        ts_array[parseInt(blockHeight)-1] = timeS
        comments = "This block replaces other blocks with same height"
     }
    }
    else{
      ts_array[parseInt(blockHeight)-1] = timeS
        transCountList[parseInt(blockHeight)] = parseInt(num_trans)+transCountList[transCountList.length-1]
        blockNumList[parseInt(blockHeight)] = parseInt(blockHeight)
        nonceList[parseInt(blockHeight)] = parseInt(nonce)
      // window.alert(transCountList)
    }
  
    sNum = sNum+1
    //Adding status of block and nonce
    cell9.innerHTML=comments
    cell10.innerHTML=nonce

    // console.log(trans_list)
    //Transaction table insertions
  
    // var table=document.getElementById("transtable")
    // var row=table.insertRow(1)

    // var cell0=row.insertCell(0)
    // var cell1=row.insertCell(1)
    // var cell2=row.insertCell(2)
    // var cell3=row.insertCell(3)
    // var cell4=row.insertCell(4)
    // var cell5=row.insertCell(5)

    // var trans_status 
    // if(trans_list.length == 1){

    // }
    // else{

    // }

    
    // cell0.innerHTML= sNum
    // cell3.innerHTML = bits


    var mynonceChart = new Chart(nonceChart, {
     type: 'line',
      data: {
        labels: blockNumList,
        text: "Nunber of blocks",
        datasets: [{ 
            data: nonceList,
            label: "Nonce",
            borderColor: "#3e95cd",
            fill: false
          }
        ]
      },
      options: {
        title: {
          display: true,
          text: 'Nonce after Each Block'
        },
        responsive:true,
      }
   })

    var mytransactionChart = new Chart(transactionChart, {
     type: 'line',
      data: {
        labels: blockNumList,
        text: "Nunber of blocks",
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

export default socket