pragma solidity ^0.4.22;

import 'openzeppelin-solidity/contracts/ECRecovery.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol';

import '../modules/IModule.sol';
import './ISafe.sol';
import './TransactionUtils.sol';


contract Safe is ECRecovery, ISafe, TransactionUtils {
    using SafeMath for uint;

    IModule[] public verificationModules;
    mapping (address => bool) public isRegisteredExecutionModule;

    uint public currentNonce = 0; // Increment for each TX

    event TransactionExecuted(bool indexed _success, address indexed _module, address indexed _to, uint _value, bytes _data, Operation _op);
    event ContractDeployed(address newContract);

    modifier onlyThis {
        require(msg.sender == address(this));
        _;
    }

    function isNonceValid(uint _nonce) view public returns (bool) {
        // In the hypothetical context of an heavily used Safe,
        // the nonce COULD hypothetically reach the maximum value
        // of an uint256, in such case we can't prevent TX replay
        // anymore, so we refuse every TX overflowing the nonce.
        return _nonce == currentNonce.add(1);
    }

    function isTxValid(address _dest, uint _value, bytes _data, Operation _op, uint _nonce, uint _timestamp, address[] _tokens, uint[] _tokenValues, bytes[] _signatures) public view returns (bool) {
        if (!isNonceValid(_nonce)) {
            return false;
        }

        if (_tokens.length != _tokenValues.length) {
            return false;
        }

        for (uint i = 0; i < verificationModules.length; i++) {
            if (!verificationModules[i].verify(
                _dest,
                _value,
                _data,
                _op,
                _nonce,
                _timestamp,
                _tokens,
                _tokenValues,
                _signatures
            )) {
                return false;
            }
        }
    }

    function exec(address _dest, uint _value, bytes _data, Operation _op, uint _nonce, uint _timestamp, address[] _tokens, uint[] _tokenValues, bytes[] _signatures) public {
        require(isTxValid(_dest, _value, _data, _op, _nonce, _timestamp, _tokens, _tokenValues, _signatures));

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

        // Reimburse
        for (uint i = 0; i < _tokens.length; i++) {
            if (_tokens[i] == 0x0) {
                require(msg.sender.send(_tokenValues[i]));
            } else {
                require(ERC20Basic(_tokens[i]).transfer(msg.sender, _tokenValues[i]));
            }
        }
    }

    function execFromModule(address _dest, uint _value, bytes _data, Operation _op) public {
        require(isRegisteredExecutionModule[msg.sender]);

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

    function execute(address _dest, uint _value, bytes _data, Operation _op) internal returns (bool success) {
        gas = msg.gas; // Forward all gas

        // Credits to the Gnosis Safe Executor.sol contract
        if (_op == Operation.Call) {
            assembly {
                success := call(gas, _dest, _value, add(_data, 0x20), mload(_data), 0, 0)
            }
        } else if (_op == Operation.DelegateCall) {
            assembly {
                success := delegatecall(gas, _dest, add(_data, 0x20), mload(_data), 0, 0)
            }
        } else if (_op == Operation.Create) {
            address newContract = 0x0:
            assembly {
                newContract := create(0, add(data, 0x20), mload(data))
            }
            success = newContract != 0x0;
            emit ContractDeployed(newContract);
        } else {
            revert("Unknown operation"); // Should never, ever be reached
        }
    }

    // TODO module management !! onlyThis
}
