pragma solidity ^0.4.22;

import '../common/HasOperations.sol';


contract ISafe is HasOperations {
    function exec(
        address _dest,
        uint _value,
        bytes _data,
        Operation _op,
        uint _nonce,
        uint _timestamp,
        uint _minimumGasNeeded,
        address _reimbursementToken, // or 0x0 for ETH
        uint _gasPrice,
        bytes _signatures
    ) public;
    function execFromModule(address _dest, uint _value, bytes _data, Operation _op) public;
}
