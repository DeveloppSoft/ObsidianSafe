pragma solidity ^0.4.22;


contract ISafe {
    enum Operation {
        Call,
        DelegateCall,
        Create
    }

    function getTxHash(address _dest, uint _value, bytes _data, Operation _op, uint _nonce, uint _timestamp, address[] _tokens, uint[] _tokenValues) pure public returns (bytes32);
    function exec(address _dest, uint _value, bytes _data, Operation _op, uint _nonce, uint _timestamp, address[] _tokens, uint[] _tokenValues) public;
    function execFromModule(address _dest, uint _value, bytes _data, Operation _op);
}
