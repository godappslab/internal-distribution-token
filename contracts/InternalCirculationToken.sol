pragma solidity >=0.4.21<0.6.0;

import "./InternalCirculationTokenImplementation.sol";

contract InternalCirculationToken is InternalCirculationTokenImplementation {
    address public owner;

    // ---------------------------------------------
    // Modification : Only an owner can carry out.
    // ---------------------------------------------
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owners can use");
        _;
    }

    // ---------------------------------------------
    // Constructor
    // ---------------------------------------------
    constructor(string name, string symbol, uint8 decimals, uint256 totalSupply) public {
        // Initial information of token
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _totalSupply = totalSupply * (10 ** uint256(decimals));

        // The owner address is maintained.
        owner = msg.sender;

        // Assign total amount to owner
        _balances[owner] = _totalSupply;

    }

    // ---------------------------------------------
    // Destruction of a contract (only owner)
    // ---------------------------------------------
    function destory() public onlyOwner {
        selfdestruct(owner);
    }

}
