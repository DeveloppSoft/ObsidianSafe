pragma solidity ^0.4.22;


import './Safe.sol';

// TODO delegate proxy?

contract SafeFactory {
    event SafeCreated(address indexed _sender, address _safe);

    // TODO configure initial modules
    function createSafe(address _initialVerifModule, address _initialExecModule) returns (address) {
        Safe safe = new Safe(_initialVerifModule, _initialExecModule);

        SafeCreated(msg.sender, address(safe));

        return address(safe);
    }
}
