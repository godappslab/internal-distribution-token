pragma solidity ^0.5.0;

import "./InternalDistributionTokenImplementation.sol";

contract InternalDistributionToken is InternalDistributionTokenImplementation {
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
    constructor(string memory name, string memory symbol, uint8 decimals, uint256 totalSupply) public {
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

}
