pragma solidity ^0.4.22;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol';

import '../interfaces/IModule.sol';
import '../interfaces/ISafe.sol';
import './Modulable.sol';

contract Safe is ISafe, Modulable {
    using SafeMath for uint;

    uint public currentNonce; // Increment for each TX

    event TransactionExecuted(bool indexed _success, address indexed _module, address indexed _to, uint _value, bytes _data, Operation _op);
    event ContractDeployed(address _newContract);

    constructor(address _initialVerif, address _initialExec) public Modulable(_initialVerif, _initialExec) {
        currentNonce = 0;
    }

    function isNonceValid(uint _nonce) view public returns (bool) {
        // In the hypothetical context of an heavily used Safe,
        // the nonce COULD hypothetically reach the maximum value
        // of an uint256, in such case we can't prevent TX replay
        // anymore, so we refuse every TX overflowing the nonce.
        return _nonce == currentNonce.add(1);
    }

    function isTxValid(
        address _dest,
        uint _value,
        bytes _data,
        Operation _op,
        uint _nonce,
        uint _timestamp,
        uint _minimumGasNeeded,
        uint _gasProvided,
        address _reimbursementToken, // or 0x0 for ETH
        uint _gasPrice,
        bytes _signatures
    ) public view returns (bool) {
        if (_gasProvided < _minimumGasNeeded) {
            return false;
        }

        if (!isNonceValid(_nonce)) {
            return false;
        }

        address[] memory allVerifModules = listVerifModules();
        for (uint i = 0; i < allVerifModules.length; i++) {
            if (
                !IModule(
                    allVerifModules[i]
                ).verify(
                    _dest,
                    _value,
                    _data,
                    _op,
                    _nonce,
                    _timestamp,
                    _reimbursementToken,
                    _gasPrice,
                    _signatures
                )
            ) {
                return false;
            }
        }
    }

    function exec(
        address _dest,
        uint _value,
        bytes _data,
        Operation _op,
        uint _nonce,
        uint _timestamp,
        uint _minimumGasNeeded,
        address _reimbursementToken, // or 0x0 for ETH
        uint _gasPrice,
        bytes _signatures
    ) public {
        uint startingGas = gasleft();

        require(
            isTxValid(
                _dest,
                _value,
                _data,
                _op,
                _nonce,
                _timestamp,
                _minimumGasNeeded,
                startingGas,
                _reimbursementToken,
                _gasPrice,
                _signatures
            )
        );

        // Always increment nonce
        currentNonce = currentNonce.add(1);

        emit TransactionExecuted(
            executeTx(
                _dest,
                _value,
                _data,
                _op
            ),
            0x0,
            _dest,
            _value,
            _data,
            _op
        );

        if (_gasPrice > 0) {
            uint amount = (startingGas - gasleft()) * _gasPrice;

            if (_reimbursementToken == 0x0) {
                msg.sender.transfer(amount);
            } else {
                require(ERC20Basic(_reimbursementToken).transfer(msg.sender, amount));
            }
        }
    }

    function execFromModule(address _dest, uint _value, bytes _data, Operation _op) public {
        require(moduleCanExecuteTx(msg.sender));

        emit TransactionExecuted(
            executeTx(
                _dest,
                _value,
                _data,
                _op
            ),
            msg.sender,
            _dest,
            _value,
            _data,
            _op
        );
    }

    function executeTx(address _dest, uint _value, bytes _data, Operation _op) internal returns (bool success) {
        uint gasTx = gasleft(); // Forward all gas

        // Credits to the Gnosis Safe Executor.sol contract
        if (_op == Operation.Call) {
            assembly {
                success := call(gasTx, _dest, _value, add(_data, 0x20), mload(_data), 0, 0)
            }
        } else if (_op == Operation.DelegateCall) {
            assembly {
                success := delegatecall(gasTx, _dest, add(_data, 0x20), mload(_data), 0, 0)
            }
        } else if (_op == Operation.Create) {
            address newContract = 0x0;
            assembly {
                newContract := create(0, add(_data, 0x20), mload(_data))
            }
            success = newContract != 0x0;
            emit ContractDeployed(newContract);
        } else {
            revert("Unknown operation"); // Should never, ever be reached
        }
    }
}
