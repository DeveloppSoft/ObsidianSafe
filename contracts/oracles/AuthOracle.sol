pragma solidity ^0.4.22;

import '../common/Initializable.sol';
import '../interfaces/IAuthOracle.sol';
import '../libraries/DLL.sol';


contract AuthOracle is Initializable, IAuthOracle {
    using DLL for DLL.Data;

    DLL.Data private signers;
    DLL.Data private modules;

    uint public minimumSignatures;
    address public safe;

    event SignarUpdated(address indexed _signer, bool indexed _added);
    event MinimumSignaturesUpdated(uint _new);
    event ModuleUpdated(address indexed _module, bool indexed _added);

    modifier onlySafeContract {
        require(msg.sender == safe, "Can only be called by safe");
        _;
    }

    function initialize(address _safe, address _signer) public isInitializer {
        safe = _safe;
        minimumSignatures = 1;

        signers.append(_signer);
    }

    function addSigner(address _signer) public onlySafeContract {
        signers.append(_signer);
        emit SignarUpdated(_signer, true);
    }

    function removeSigner(address _signer) public onlySafeContract {
        require(signers.nbElems > 1, "Need at least one signer left");

        signers.remove(_signer);
        emit SignarUpdated(_signer, false);
    }

    function listSigners() public view returns (address[]) {
        return signers.list();
    }

    function updateNbSignatures(uint _number) public onlySafeContract {
        minimumSignatures = _number;
        emit MinimumSignaturesUpdated(_number);
    }

    function addModule(address _module) public onlySafeContract {
        modules.append(_module);
        emit ModuleUpdated(_module, true);
    }

    function removeModule(address _module) public onlySafeContract {
        modules.remove(_module);
        emit ModuleUpdated(_module, false);
    }

    function listModules() public view returns (address[]) {
        return modules.list();
    }

    function getTxHash(
        address _dest,
        uint _value,
        bytes _data,
        Operation _op,
        uint _nonce,
        uint _timestamp,
        address _reimbursementToken, // or 0x0 for ETH
        uint _minimumGasNeeded,
        uint _gasPrice
    ) view public returns (bytes32) {
        return keccak256(
            abi.encode(
                0x1, // version
                address(this),
                _dest,
                _value,
                _data,
                _op,
                _nonce,
                _timestamp,
                _reimbursementToken,
                _minimumGasNeeded,
                _gasPrice
            )
        );
    }

    function authorized(
        address _dest,
        uint _value,
        bytes _data,
        Operation _op,
        uint _nonce,
        uint _timestamp, // 0 means none
        address _reimbursementToken, // or 0x0 for ETH
        uint _minimumGasNeeded,
        uint _gasPrice,
        bytes _signatures
    ) view public returns (bool) {
        if (_signatures.length < minimumSignatures * 65) {
            return false;
        }

        if (_timestamp != 0 && now > _timestamp) { // TX expired
            return false;
        }

        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                getTxHash(
                    _dest,
                    _value,
                    _data,
                    _op,
                    _nonce,
                    _timestamp,
                    _reimbursementToken, // or 0x0 for ETH
                    _minimumGasNeeded,
                    _gasPrice
                )
            )
        );

        return verify(hash, _signatures);
    }

    function verify(bytes32 _hash, bytes _signatures) internal view returns (bool) {
        address last = 0x0;
        address current = 0x0;

        uint8 v;
        bytes32 r;
        bytes32 s;

        for (uint i = 0; i < minimumSignatures; i++) {
            // solium-disable-next-line security/no-inline-assembly
            assembly {
                let pos := mul(0x41, i)
                r := mload(add(_signatures, add(pos, 0x20)))
                s := mload(add(_signatures, add(pos, 0x40)))
                v := and(mload(add(_signatures, add(pos, 0x41))), 0xff)
            }

            if (v < 27) {
                v += 27;
            }

            current = ecrecover(_hash, v, r, s);
            if (current <= last ||
                signers.contains(current) == false) {
                return false;
            }

            last = current;
        }

        return true;
    }
        
    function moduleAuthorized(
        address _module,
        address _dest,
        uint _value,
        bytes _data,
        Operation _op
    ) view public returns (bool) {
        // ATM it is quite simple, in the future we could have a permission system
        return modules.contains(_module);

        _dest; _value; _data; _op;
    }
}
