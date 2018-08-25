pragma solidity ^0.4.22;
pragma experimental ABIEncoderV2; // for bytes[]

import '../common/HasOperations.sol';


contract IModule is HasOperations {
    function verify(
        address _dest,
        uint _value,
        bytes _data,
        Operation _op,
        uint _nonce,
        uint _timestamp,
        address _reimbursementToken, // or 0x0 for ETH
        uint _gasPrice,
        bytes[] _signatures
    ) public view returns (bool);
}
