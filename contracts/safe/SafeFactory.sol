pragma solidity ^0.4.22;


import './Safe.sol';
import '../modules/Signers.sol';

contract SafeFactory {
    event SafeCreated(address indexed _sender, address _safe);

    function createSafe(address _signer) public returns (address) {
        address[] memory initialSigners = new address[](1);
        initialSigners[0] = _signer;
        uint needSigs = 1;

        address fakeSafe = address(this);

        Signers signerModule = new Signers(fakeSafe, initialSigners, needSigs);
        Safe safe = new Safe(address(signerModule), address(signerModule));

        // Make the safe the real safe
        signerModule.updateSafe(address(safe));

        emit SafeCreated(msg.sender, address(safe));

        return address(safe);
    }
}
