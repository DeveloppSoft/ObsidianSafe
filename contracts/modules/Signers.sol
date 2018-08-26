pragma solidity ^0.4.22;

import '../interfaces/IModule.sol';
import '../libraries/ListOnSteroids.sol';
import './Module.sol';

// Manage signing keys
// Verify signatures

contract Signers is IModule, Module {
    using ListOnSteroids for ListOnSteroids.List;

    ListOnSteroids.List private signers;
    mapping (bytes32 => mapping (address => bool)) private approvedHash;
    
    uint public requiredSignatures;

    event SignerUpdated(address indexed _signer, bool _allowed);
    event SignaturesNeededChanged(uint _newValue);

    constructor(address _safe, address[] _initialSigners, uint _needSigs) public Module(_safe) {
        signers.init();

        requiredSignatures = _needSigs;

        for (uint i = 0; i < _initialSigners.length; i++) {
            signers.insert(_initialSigners[i]);
        }
    }

    function verify(
        address _dest,
        uint _value,
        bytes _data,
        Operation _op,
        uint _nonce,
        uint _timestamp,
        address _reimbursementToken, // or 0x0 for ETH
        uint _minimumGasNeeded,
        uint _gasPrice,
        bytes _signatures
    ) public view returns (bool) {
        if (_signatures.length < requiredSignatures * 65) {
            return false; // No need to go further
        }

        bytes32 txHash = getTxHash(
            _dest,
            _value,
            _data,
            _op,
            _nonce,
            _timestamp,
            _reimbursementToken,
            _minimumGasNeeded,
            _gasPrice
        );

        return verifyHash(
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    txHash
                )
            ),
            _signatures
        );
    }

    function verifyHash(bytes32 txHash, bytes _signatures) internal view returns (bool) {
        address lastOwner = 0x0;
        address currentOwner;

        uint8 v;
        bytes32 r;
        bytes32 s;

        for (uint i = 0; i < requiredSignatures; i++) {
            // split sig
            // Credit Gnosis Safe
            assembly {
                let pos := mul(0x41, i)
                r := mload(add(_signatures, add(pos, 0x20)))
                s := mload(add(_signatures, add(pos, 0x40)))
                v := and(mload(add(_signatures, add(pos, 0x41))), 0xff)
            }

            // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
            if (v < 27) {
                v += 27;
            }

            currentOwner = ecrecover(txHash, v, r, s);
            if (
                currentOwner <= lastOwner ||        // unordered
                signers.isIn(currentOwner) == false // not signer
            ) {
                return false;
            }

            lastOwner = currentOwner;
        }

        return true;
    }

    function addSigner(address _signer) public onlySafe {
        signers.insert(_signer);

        emit SignerUpdated(
            _signer,
            true
        );
    }

    function removeSigner(address _previousSigner, address _signer) public onlySafe {
        signers.remove(_previousSigner, _signer);

        emit SignerUpdated(
            _signer,
            false
        );
    }

    function changeSignaturesNeeded(uint _newValue) public onlySafe {
        require(requiredSignatures != _newValue, "Already correct value");

        requiredSignatures = _newValue;

        emit SignaturesNeededChanged(_newValue);
    }

    function listSigners() public view returns (address[]) {
        return signers.list();
    }

    function isSigner(address _signer) public view returns (bool) {
        return signers.isIn(_signer);
    }
}
