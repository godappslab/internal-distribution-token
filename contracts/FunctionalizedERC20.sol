pragma solidity >=0.4.21<0.6.0;

interface FunctionalizedERC20 {
    function balanceOf(address who) external view returns (uint256);
    function name() external view returns (string _name);
    function symbol() external view returns (string _symbol);
    function decimals() external view returns (uint8 _decimals);
    function totalSupply() external view returns (uint256 _supply);
    function transfer(address to, uint256 value) external returns (bool ok);

    event Transfer(address indexed from, address indexed to, uint256 value);
}
