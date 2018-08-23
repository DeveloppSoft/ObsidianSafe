pragma solidity ^0.4.22;

import './HasOperations.sol';


contract TransactionUtils is HasOperations {
    function getTxHash(address _dest, uint _value, bytes _data, Operation _op, uint _nonce, uint _timestamp, address[] _tokens, uint[] _tokenValues) view public returns (bytes32) {
        return keccak256(
            abi.encode(
                address(this), // No replay between Safes
                _dest,
                _value,
                _data,
                _op,
                _nonce,
                _timestamp,
                _tokens,
                _tokenValues
            )
        );
    }
}
