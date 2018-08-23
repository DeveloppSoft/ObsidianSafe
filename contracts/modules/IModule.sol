pragma solidity ^0.4.22;


interface IModule {
    function verify(address _dest, uint _value, bytes _data, Operation _op, uint _nonce, uint _timestamp, address[] _tokens, uint[] _tokenValues, bytes[] _signatures) view returns (bool); 
}
