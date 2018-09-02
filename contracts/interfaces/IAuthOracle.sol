pragma solidity ^0.4.22;

import "../common/HasOperations.sol";


contract IAuthOracle is HasOperations {
    function authorized(
        address _dest,
        uint _value,
        bytes _data,
        Operation _op,
        uint _nonce,
        uint _timestamp,
        address _reimbursementToken, // or 0x0 for ETH
        uint _minimumGasNeeded,
        uint _gasPrice,
        bytes _signatures) view public;
    function moduleAuthorized(
        address _module,
        uint _value,
        bytes _data,
        Operation _op) view public;
}
