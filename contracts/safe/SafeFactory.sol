pragma solidity ^0.4.22;


import "./Safe.sol";
import "../oracles/AuthOracle.sol"

contract SafeFactory {
    event SafeCreated(address indexed _sender, address _safe);

    function createSafe(address _signer) public returns (address) {
        address[] memory initialSigners = new address[](1);
        initialSigners[0] = _signer;
        uint needSigs = 1;

        AuthOracle oracle = new AuthOracle();
        Safe safe = new Safe(oracle);

        safe.initialize(oracle);
        oracle.initialize(address(safe), initialSigners, needSigs)

        emit SafeCreated(msg.sender, address(safe));

        return address(safe);
    }
}
