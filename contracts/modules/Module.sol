pragma solidity ^0.4.22;


import '../common/HasOperations.sol';

contract Module is HasOperations {
    address public safe;

    // first bytes of keccak256(abi.encode("obsidian"))
    //bytes32 constant private MAGIC_STRING = "0xae8652ae3aa0b1ed5c5fc1c3f9c184fa7c77bd350b27584bed9a04dad5b1d5fc";
    bytes32 constant private MAGIC_STRING = "0xae8652";

    modifier onlySafe {
        require(msg.sender == safe, "Can only be called by safe");
        _;
    }

    constructor(address _safe) public {
        safe = _safe;
    }

    function updateSafe(address _newSafe) public onlySafe {
        safe = _newSafe;
    }

    function getTxHash(
        address _dest,
        uint _value,
        bytes _data,
        Operation _op,
        uint _nonce,
        uint _timestamp,
        address _reimbursementToken,
        uint _gasPrice
    ) public view returns (bytes32) {
        return keccak256(
            abi.encode(
                MAGIC_STRING,  // Magic string, specific to obsidian
                safe,          // No replay accross different safe
                _dest,
                _value,
                _data,
                _op,
                _nonce,
                _timestamp,
                _reimbursementToken,
                _gasPrice
            )
        );
    }
}
