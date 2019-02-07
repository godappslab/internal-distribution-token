pragma solidity >=0.4.24<0.6.0;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/AddressUtils.sol";
import "zeppelin-solidity/contracts/ECRecovery.sol";
import "zeppelin-solidity/contracts/access/rbac/Roles.sol";

import "./InternalCirculationTokenInterface.sol";
import "./FunctionalizedERC20.sol";

contract InternalCirculationTokenImplementation is FunctionalizedERC20, InternalCirculationTokenInterface {
    // Load library
    using SafeMath for uint256;
    using AddressUtils for address;
    using ECRecovery for bytes32;
    using Roles for Roles.Role;

    // Token properties
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _totalSupply;

    // Manage token holding record
    mapping(address => uint256) internal _balances;

    // Signature list after processing (Already transfer)
    mapping(bytes => bool) private usedSignatures;

    // List of ETH addresses to which tokens can be distributed
    Roles.Role private Distributors;

    // Token Owner ETH Address
    address public owner;

    constructor() internal {
        owner = msg.sender;
    }

    // Only the owner can do it
    modifier onlyOwner() {
        require(isOwner(msg.sender), "Only owners can use");
        _;
    }

    // @title Is the ETH address of the argument the owner of the token?
    // @param address account
    // @return bool (true:owner false:not owner)
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    // Function to access name of token .
    function name() external view returns (string) {
        return _name;
    }

    // Function to access symbol of token .
    function symbol() external view returns (string) {
        return _symbol;
    }

    // Function to access decimals of token .
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    // Function to access total supply of tokens .
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    // Function to access total supply of tokens .
    function balanceOf(address _account) external view returns (uint256 balance) {
        return _balances[_account];
    }

    // Only the distributor can do it
    modifier onlyDistributor() {
        require(this.isDistributor(msg.sender), "Only distributors can use");
        _;
    }

    // @title Is the ETH address of the argument the distributor of the token?
    // @param _account
    // @return bool (true:owner false:not owner)
    function isDistributor(address _account) external view returns (bool) {
        return Distributors.has(_account);
    }

    // @title A function that adds the ETH address of the argument to the distributor list of the token
    // @param _account ETH address you want to add
    // @return bool
    function addToDistributor(address _account) external onlyOwner returns (bool success) {
        // `_account` is a correct address
        require(_account != address(0), "Correct EOA address is required");

        // `_account` is necessary to have no token
        require(_balances[_account] == 0, "This EOA address has a token");

        // `_account` is not an owner or a distributor
        require(this.isOwner(_account) == false && this.isDistributor(_account) == false, "This EOA address can not be a distributor");

        // `_account` is not a contract address
        require(_account.isContract() == false, "Contract address can not be specified");

        // Add to distributor
        Distributors.add(_account);

        emit AddedToDistributor(_account);

        return true;
    }

    // @title A function that excludes the ETH address of the argument from the distributor list of the token
    // @param _account ETH address you want to delete
    // @return bool
    function deleteFromDistributor(address _account) external onlyOwner returns (bool success) {
        // `_account` is a correct address
        require(_account != address(0), "Correct EOA address is required");

        // `_account` is necessary to have no token
        require(_balances[_account] == 0, "This EOA address has a token");

        // Delete from distributor
        Distributors.remove(_account);

        emit DeletedFromDistributor(_account);

        return true;
    }

    // @title A function that accepts a user's transfer request (executed by the contract owner)
    // @param bytes _signature
    // @param address _requested_user
    // @param uint256 _value
    // @param string _nonce
    // @return bool
    function acceptTokenTransfer(bytes _signature, address _requested_user, uint256 _value, string _nonce) external onlyOwner returns (bool success) {
        // argument `_signature` is not yet used
        require(usedSignatures[_signature] == false);

        // Recalculate hash value
        bytes32 hashedTx = this.requestTokenTransfer(_requested_user, _value, _nonce);

        // Identify the requester's ETH Address
        address _user = hashedTx.recover(_signature);

        require(_user != address(0), "Unable to get EOA address from signature");

        // the argument `_requested_user` and
        // the value obtained by calculation from the signature are the same ETH address
        //
        // If they are different, it is judged that the user's request has not been transmitted correctly
        require(_user == _requested_user, "EOA address mismatch");

        // user has the amount of that token
        require(this.balanceOf(_user) >= _value, "Insufficient funds");

        _balances[_user] = _balances[_user].sub(_value);
        _balances[msg.sender] = _balances[msg.sender].add(_value);

        // Record as used signature
        usedSignatures[_signature] = true;

        // Execute events
        emit Transfer(_user, msg.sender, _value);
        emit Exchange(_user, msg.sender, _value);

        return true;
    }

    // @title A function that generates a hash value of a request to which a user sends a token (executed by the user of the token)
    // @params _requested_user ETH address that requested token transfer
    // @params _value Number of tokens
    // @params _nonce One-time string
    // @return bytes32 Hash value
    // @dev The user signs the hash value obtained from this function and hands it over to the owner outside the system
    function requestTokenTransfer(address _requested_user, uint256 _value, string _nonce) external view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), bytes4(0x8210d627), _requested_user, _value, _nonce));
    }

    // @title Send a token
    // @notice However, the remittance destination is managed
    // @param _to ETH address of sending token
    // @param _value Number of tokens
    // @return bool (true)
    // @dev
    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(_to != address(0), "The remittance destination needs a correct address");

        //
        // Only the owner or distributor can use this function
        //
        require(this.isOwner(msg.sender) || this.isDistributor(msg.sender), "Only owner or distributor can use");

        if (this.isOwner(msg.sender) && this.isDistributor(_to)) {
            //
            // If the requester is the owner of the token and the destination is the distributor
            //
            return _allocateToken(_to, _value);

        } else if (this.isDistributor(msg.sender) && this.isOwner(_to)) {
            //
            // If the requester is a distributor and the token destination is the owner
            //
            return _backToToken(_to, _value);

        } else if (this.isDistributor(msg.sender) && this.isDistributor(_to) == false && this.isOwner(_to) == false && _to.isContract() == false) {
            //
            // If the requestor is distributor and the destination is neither distributor, owner nor contract address
            //
            return _distributeToken(_to, _value);

        }

        //
        // Otherwise do not process
        //
        revert("Transfer source and destination are out of operating conditions");

        return false;

    }

    ///////////////////////////////////////////////////////////////////////
    // private functions
    ///////////////////////////////////////////////////////////////////////

    // @title Assign token to distributor (internal processing)
    function _allocateToken(address _to, uint256 _value) private onlyOwner returns (bool success) {
        success = _transfer(_to, _value);

        // Execute event if token transfer is successful
        if (success) {
            emit Allocate(msg.sender, _to, _value);
        }

        return success;
    }

    // @title returns a token to the owner (internal processing)
    function _backToToken(address _to, uint256 _value) private onlyDistributor returns (bool success) {
        success = _transfer(_to, _value);

        // Execute event if token transfer is successful
        if (success) {
            emit BackTo(msg.sender, _to, _value);
        }

        return success;
    }

    // @title distributing tokens to users (internal processing)
    function _distributeToken(address _to, uint256 _value) private onlyDistributor returns (bool success) {
        success = _transfer(_to, _value);

        // Execute event if token transfer is successful
        if (success) {
            emit Distribute(msg.sender, _to, _value);
        }

        return success;
    }

    // @title Token movement processing (common internal processing)
    function _transfer(address _to, uint256 _value) private returns (bool success) {
        require(_to.isContract() == false, "Can not transfer to contract address");

        if (this.balanceOf(msg.sender) < _value) revert("Insufficient funds");

        _balances[msg.sender] = _balances[msg.sender].sub(_value);
        _balances[_to] = _balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;

    }

}
