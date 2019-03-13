pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

/**
 * Utility library of inline functions on addresses
 */
library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

/**
 * @title Elliptic curve signature operations
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 */

library ECDSA {
    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param signature bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }

    /**
     * toEthSignedMessageHash
     * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
     * and hash the result
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

interface InternalCirculationTokenInterface {
    // Required methods

    // @title Is the ETH address of the argument the distributor of the token?
    // @param _account
    // @return bool (true:owner false:not owner)
    function isDistributor(address _account) external view returns (bool);

    // @title A function that adds the ETH address of the argument to the distributor list of the token
    // @param _account ETH address you want to add
    // @return bool
    function addToDistributor(address _account) external returns (bool success);

    // @title A function that excludes the ETH address of the argument from the distributor list of the token
    // @param _account ETH address you want to delete
    // @return bool
    function deleteFromDistributor(address _account) external returns (bool success);

    // @title A function that accepts a user's transfer request (executed by the contract owner)
    // @param bytes memory _signature
    // @param address _requested_user
    // @param uint256 _value
    // @param string _nonce
    // @return bool
    function acceptTokenTransfer(bytes calldata _signature, address _requested_user, uint256 _value, string calldata _nonce)
        external
        returns (bool success);

    // @title A function that generates a hash value of a request to which a user sends a token (executed by the user of the token)
    // @params _requested_user ETH address that requested token transfer
    // @params _value Number of tokens
    // @params _nonce One-time string
    // @return bytes32 Hash value
    // @dev The user signs the hash value obtained from this function and hands it over to the owner outside the system
    function requestTokenTransfer(address _requested_user, uint256 _value, string calldata _nonce) external view returns (bytes32);

    // @title Returns whether it is a used signature
    // @params _signature Signature string
    // @return bool Used or not
    function isUsedSignature(bytes calldata _signature) external view returns (bool);

    // Events

    // token assignment from owner to distributor
    event Allocate(address indexed from, address indexed to, uint256 value);

    // tokens from distributor to users
    event Distribute(address indexed from, address indexed to, uint256 value);

    // tokens from distributor to owner
    event BackTo(address indexed from, address indexed to, uint256 value);

    // owner accepted the token from the user
    event Exchange(address indexed from, address indexed to, uint256 value, bytes signature, string nonce);

    event AddedToDistributor(address indexed account);
    event DeletedFromDistributor(address indexed account);
}

interface FunctionalizedERC20 {
    function balanceOf(address who) external view returns (uint256);
    function name() external view returns (string memory _name);
    function symbol() external view returns (string memory _symbol);
    function decimals() external view returns (uint8 _decimals);
    function totalSupply() external view returns (uint256 _supply);
    function transfer(address to, uint256 value) external returns (bool ok);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract InternalCirculationTokenImplementation is FunctionalizedERC20, InternalCirculationTokenInterface {
    // Load library
    using SafeMath for uint256;
    using Address for address;
    using ECDSA for bytes32;
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
    function name() external view returns (string memory) {
        return _name;
    }

    // Function to access symbol of token .
    function symbol() external view returns (string memory) {
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
    function acceptTokenTransfer(bytes calldata _signature, address _requested_user, uint256 _value, string calldata _nonce)
        external
        onlyOwner
        returns (bool success)
    {
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
        emit Exchange(_user, msg.sender, _value, _signature, _nonce);

        return true;
    }

    // @title A function that generates a hash value of a request to which a user sends a token (executed by the user of the token)
    // @params _requested_user ETH address that requested token transfer
    // @params _value Number of tokens
    // @params _nonce One-time string
    // @return bytes32 Hash value
    // @dev The user signs the hash value obtained from this function and hands it over to the owner outside the system
    function requestTokenTransfer(address _requested_user, uint256 _value, string calldata _nonce) external view returns (bytes32) {
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

    // @title Returns whether it is a used signature
    // @params _signature Signature string
    // @return bool Used or not
    function isUsedSignature(bytes calldata _signature) external view returns (bool) {
        return usedSignatures[_signature];
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
