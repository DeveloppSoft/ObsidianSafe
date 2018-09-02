pragma solidity ^0.4.22;

import "./Safe.sol";
import "../oracles/AuthOracle.sol";


contract SafeFactory {
    event SafeCreated(address indexed _sender, address _safe);

    function createSafe(address _signer) public returns (address) {
        uint needSigs = 1;

        AuthOracle oracle = new AuthOracle();
        Safe safe = new Safe();

        safe.initialize(oracle);
        oracle.initialize(address(safe), _signer, needSigs);

        emit SafeCreated(_signer, address(safe));

        return address(safe);
    }
}
