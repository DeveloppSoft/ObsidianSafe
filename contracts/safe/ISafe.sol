pragma solidity ^0.4.22;

import './HasOperations.sol';


contract ISafe is HasOperations {
    function exec(address _dest, uint _value, bytes _data, Operation _op, uint _nonce, uint _timestamp, address[] _tokens, uint[] _tokenValues) public;
    function execFromModule(address _dest, uint _value, bytes _data, Operation _op) public;
}
