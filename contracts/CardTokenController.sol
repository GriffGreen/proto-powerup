pragma solidity ^0.4.8;

/*
  MiniMeToken contract taken from https://github.com/Giveth/minime/
 */

// TokenController interface
contract TokenController {
    function proxyPayment(address _owner) payable returns(bool);
    function onTransfer(address _from, address _to, uint _amount) returns(bool);
    function onApprove(address _owner, address _spender, uint _amount) returns(bool);
}

// Minime interface
contract MiniMeToken {
    function generateTokens(address _owner, uint _amount
    ) returns (bool);
}


contract ICOTokenController is TokenController {
  function mintToken(uint amount);
  function setChiefApricot(string _boardID,address _boardowner);
}



// Taken from Zeppelin's standard contracts.
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract CardTokenController is TokenController {

    MiniMeToken ICOToken;   // The new card token
    MiniMeToken CardToken;   // The new card token

    address public allowedSupplier; // the supplier that can claim the card

    address supplier; // the supplier that has actually claimed the card.

    address owner;

    CardStatuses public cardstatus;

   enum CardStatuses {
        Open,
        Claimed,
        Approved,
        Rejected
        //Finished
    }

    function CardTokenController(
        address _ICOTokenaddress,
        address _CardTokenaddress          // the new MiniMe token address
    ) {
        CardToken = MiniMeToken(_CardTokenaddress); // The Deployed Token Contract
        ICOToken = MiniMeToken(_ICOTokenaddress);
        owner = msg.sender;
        cardstatus = CardStatuses.Open;
    }

/////////////////
// TokenController interface
/////////////////


    function proxyPayment(address _owner) payable returns(bool) {
        return false;
    }

    function onTransfer(address _from, address _to, uint _amount) returns(bool) {

      // we're paying out ?
      if (_to == address(ICOToken)){
        //CardToken.destroyTokens(msg.sender,_amount);
        ICOToken.generateTokens(msg.sender,_amount);
        if (!supplier.send(_amount)){
          throw;
        }
        cardstatus = CardStatuses.Approved;
        CardApproved(this,supplier,_amount);

      }

        return true;
    }

    function onApprove(address _owner, address _spender, uint _amount) returns(bool)
    {
        return false;
    }

    function assignSupplier(address _supplier) {

      if (msg.sender != owner){
        throw;
      }

      allowedSupplier = _supplier;
    }

    // sending ETH mints card-tokens
    function() payable {

      // when supplier is set - minting new tokens is disabled. ETH is sent back.
      if (supplier != 0x0){
        throw;
      }

      CardToken.generateTokens(msg.sender, msg.value);

    }

    event CardClaimed(address cardcontroller, address supplier);
    event CardApproved(address cardcontroller,address supplier,uint amount);
    event CardRejected(address cardcontroller, address supplier);

    function claim(){

      // has it been claimed already ?
      if (supplier != 0x0){
        throw;
      }

      // am I the correct claimer ?
      if (msg.sender != allowedSupplier){
        throw;
      }

      supplier = msg.sender;

      cardstatus = CardStatuses.Claimed;

      CardClaimed(this,msg.sender);

    }

    // function resolve(){ // payout and approve

    //  if (msg.sender != owner){
    //     throw;
    //   }

    //   supplier.send(this.value);

    //   // generate ICO tokens for the funder ( == the owner for now )
    //   ICOToken.generateTokens(owner, this.value);

    // }

    // function panic() {  // cancel and send money back
    //   selfdestruct(_boardowner);
    // }

    function fuckYou(){ // I don't approve this - remove supplier, so that he is fucked

      // only the owner can fuck over the supplier
      if (msg.sender != owner){
        throw;
      }

      CardRejected(this,supplier);

      supplier = 0;
      allowedSupplier = 0;
      cardstatus = CardStatuses.Open;
    }

//    function convert(uint _amount){

        // transfer ARC to the vault address. caller needs to have an allowance from
        // this controller contract for _amount before calling this or the transferFrom will fail.
//        if (!arcToken.transferFrom(msg.sender, 0x0, _amount)) {
//            throw;
//        }

        // mint new SWT tokens
//        if (!CardToken.generateTokens(msg.sender, _amount)) {
//            throw;
//        }
//    }


}