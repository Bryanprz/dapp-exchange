// Deposit & Withdraw Funds
// Manage Orders - Make or Cancel
// Handle Trades - Charge Fees

// TODO:
// [X] Set the fee account
// [X] Deposit Ether
// [X] Withdraw Ether
// [X] Deposit tokens
// [X] Withdraw tokens
// [X] Check balances
// [X] Make order
// [X] Cancel order
// [X] Fill order
// [X] Charge fees

pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Token.sol";

contract Exchange {
  using SafeMath for uint;

  // state variable convention without underscore
  address public feeAccount; // the account that receives exchange fees
  uint256 public feePercent;
  address constant ETHER = address(0); // store Ether in tokens mapping with blank address

  // --- MAPPINGS ---
  // 1st key is token addresses; all tokens that have been deposited
  // 2nd key is address of user who has deposited the tokens themselves 
  // uint256 is balance

  // This mapping stores Ether by assuming the first address is address 0
  // for Ether
  mapping(address => mapping(address => uint256)) public tokens;
  mapping(uint256 => _Order) public orders; // key is ID
  mapping(uint256 => bool) public orderCancelled;
  mapping(uint256 => bool) public orderFilled; // key is ID
  uint256 public orderCount;

  // --- MAPPING ENDS ---

  // Events
  event Deposit(address token, address user, uint256 amount, uint256 balance);
  event Withdraw(address token, address user, uint256 amount, uint256 balance);

  // Name Order event without underscore to differentiate
  // from _Order struct
  // Event Order is used outside smart contract; struct
  // used inside smart contract only
  event Order(
    uint256 id,
    address user,
    address tokenGet, 
    uint256 amountGet, 
    address tokenGive,
    uint256 amountGive,
    uint256 timestamp
  );

  event Cancel(
    uint256 id,
    address user,
    address tokenGet, 
    uint256 amountGet, 
    address tokenGive,
    uint256 amountGive,
    uint256 timestamp
  );

  // user is user that created order
  // userFill is user that filled order
  event Trade(
    uint256 id,
    address user, 
    address tokenGet, 
    uint256 amountGet, 
    address tokenGive,
    uint256 amountGive,
    address userFill,
    uint256 timestamp
  );
  // --- MODELING ORDERS ---
  // Model the order
  // store the order on the blockchain
  // add the order to storage
   
  struct _Order {
    uint256 id;
    address user;
    address tokenGet; // token they want to purchase
    uint256 amountGet; 
    address tokenGive; // token they are going to use in the trade
    uint256 amountGive;
    uint256 timestamp;
  }


  constructor(address _feeAccount, uint256 _feePercent) public {
    feeAccount = _feeAccount; // _ means local variable
    feePercent = _feePercent;
  }

  // Fallback: reverts if Ether is sent to this smart contract by mistake
  function() external {
    revert();
  }

  // payable modifier means this function accepts Ether payments with { value: 10 }
  function depositEther() payable public {
    // msg.value comes from meta data available in every function call in Solidity
    // e.g. { value: 10 } in a function call means send 10 Ether; receiving func sees msg.value
    tokens[ETHER][msg.sender] = tokens[ETHER][msg.sender].add(msg.value);
    emit Deposit(ETHER, msg.sender, msg.value, tokens[ETHER][msg.sender]);
  }

  function withdrawEther(uint _amount) public {
    require(tokens[ETHER][msg.sender] >= _amount);
    tokens[ETHER][msg.sender] = tokens[ETHER][msg.sender].sub(_amount);
    msg.sender.transfer(_amount);
    emit Withdraw(ETHER, msg.sender, _amount, tokens[ETHER][msg.sender]);
  }

  function depositToken(address _token, uint _amount) public {
    // TODO Don't allow Ether deposits
    require(_token != ETHER);

    // require means transfer should work or else revert execution
    require(Token(_token).transferFrom(msg.sender, address(this), _amount));

    // Internally track how many tokens each user of this
    // exchange has
    // (Manage deposit - update balance)
    tokens[_token][msg.sender] = tokens[_token][msg.sender].add(_amount);
    // Send tokens to this contract
    // Emit event
    emit Deposit(_token, msg.sender, _amount, tokens[_token][msg.sender]);
  }

  function withdrawToken(address _token, uint256 _amount) public {
    require(_token != ETHER); // Token should not be stored at Ether address
    require(tokens[_token][msg.sender] >=_amount); // user should have more balance than withdrawal
    tokens[_token][msg.sender] = tokens[_token][msg.sender].sub(_amount);
    require(Token(_token).transfer(msg.sender, _amount));
    emit Withdraw(_token, msg.sender, _amount, tokens[_token][msg.sender]);
  }

  // view modifier means function is external and will return a value for us
  // i.e. it's a reader function essentially
  function balanceOf(address _token, address _user) public view returns (uint256) {
    return tokens[_token][_user];
  }

  function makeOrder(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive) public {
    orderCount = orderCount.add(1);

    // 'now' is Solidity timestamp expressed in Epoch time
    orders[orderCount] = _Order(orderCount, msg.sender, _tokenGet, _amountGet, _tokenGive, _amountGive, now);
    emit Order(orderCount, msg.sender, _tokenGet, _amountGet, _tokenGive, _amountGive, now);
     
  }

  function cancelOrder(uint256 _id) public {
    // set local var _order
    // of _Order type
    // fetch it from storage
    _Order storage _order = orders[_id];

    // Must be "my" order
    require(address(_order.user) == address(msg.sender));

    // Must be a valid order; i.e. must exist
    require(_order.id == _id);

    // add order.id to cancelled orders mapping
    orderCancelled[_id] = true;

    // trigger event so subscribers can be notified
    emit Cancel(_order.id, msg.sender, _order.tokenGet, _order.amountGet, _order.tokenGive, _order.amountGive, now);
  }

  function fillOrder(uint256 _id) public {
    // make sure it hasn't been filled already
    // fetch the order
    // do the trade
    // charge fees
    // emit a trade event
    // mark the order as filled

    require(_id > 0 && _id <= orderCount);
    require(!orderFilled[_id]);
    require(!orderCancelled[_id]);

    _Order storage _order = orders[_id];
    _trade(_order.id, _order.user, _order.tokenGet, _order.amountGet, _order.tokenGive, _order.amountGive); 
    orderFilled[_order.id] = true;
  }

  function _trade(uint256 _orderId, address _user, address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive) internal {
    // --- CHARGE FEES ---
    // fee paid by user that fills order, i.e. msg.sender
    // fee deducted from _amountGet
    // div fee percent (integer) by 100 to get percentage
    uint256 _feeAmount = _amountGive.mul(feePercent).div(100);

    // --- EXECUTE TRADE ---
    // _user is person who created order
    // msg.sender is person filling order
    // send tokens from filler to creater
    tokens[_tokenGet][msg.sender] = tokens[_tokenGet][msg.sender].sub(_amountGet.add(_feeAmount));
    tokens[_tokenGet][_user] = tokens[_tokenGet][_user].add(_amountGet);
    tokens[_tokenGet][feeAccount] = tokens[_tokenGet][feeAccount].add(_feeAmount);

    // creator pays filler with tokenGive
    tokens[_tokenGive][_user] = tokens[_tokenGive][_user].sub(_amountGive);
    tokens[_tokenGive][msg.sender] = tokens[_tokenGive][_user].add(_amountGive);
    // --- EXECUTE TRADE ENDS---

    emit Trade(_orderId, _user, _tokenGet, _amountGet, _tokenGive, _amountGive, msg.sender, now);
  }
}
