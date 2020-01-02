pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Token {
  // import library from openzeppelin
  using SafeMath for uint;

  // Variables
  string public name = "DApp Token";
  string public symbol = "DAPP";
  uint256 public decimals = 18; // numb of decimals token can be subdivided by
  uint public totalSupply;

  // Events
  // indexed means only subscribe to events where we are the 'from' or 'to' value
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  

  mapping(address => uint256) public balanceOf;

  // allowance keeps track of how many tokens the exchange is allowed to spend on 
  // behalf of an account

  // 1st address is from person who approved the tokens
  // 2nd address is all the places/exchanges where they approved to spend
  //   can be multiple exchanges (in our case just one)
  mapping(address => mapping(address => uint256)) public allowance;

  // Send tokens

  // constructors MUST have public in order to work
  constructor() public {
    // actual total supply is totalSupply * decimals
    // because it's stored as cents
    totalSupply = 1000000 * (10 ** decimals);

    // set total supply to deployer of contract
    balanceOf[msg.sender] = totalSupply;
  }

  function transfer(address _to, uint256 _value) public returns (bool success) {
    // sender must have exact or more tokens than value to transfer
    require(balanceOf[msg.sender] >= _value);
    _transfer(msg.sender, _to, _value);
    return true;
  }

  // _ before fnc name is convention that denotes internal-only function
  function _transfer(address _from, address _to, uint256 _value) internal {
    require(_to != address(0));
    balanceOf[_from] = balanceOf[_from].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);
    emit Transfer(_from, _to, _value);
  }

  // Approve tokens
  function approve(address _spender, uint256 _value) public returns (bool success) {
    require(_spender != address(0)); // test this under failure block
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(_value <= balanceOf[_from]);
    require(_value <= allowance[_from][msg.sender]);
    allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
    _transfer(_from, _to, _value);
    return true;
  }
}
