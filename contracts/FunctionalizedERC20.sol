pragma solidity ^0.5.0;

interface FunctionalizedERC20 {
    function balanceOf(address who) external view returns (uint256);
    function name() external view returns (string memory _name);
    function symbol() external view returns (string memory _symbol);
    function decimals() external view returns (uint8 _decimals);
    function totalSupply() external view returns (uint256 _supply);
    function transfer(address to, uint256 value) external returns (bool ok);

    event Transfer(address indexed from, address indexed to, uint256 value);
}
