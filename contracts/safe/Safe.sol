pragma solidity ^0.4.22;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol";

import "../interfaces/ISafe.sol";
import '../interfaces/IAuthOracle.sol';
import '../common/Initializable.sol';

contract Safe is Initializable, ISafe {
    using SafeMath for uint;

    uint public currentNonce; // Increment for each TX
    IAuthOracle public oracle; // Authorize or refuse transactions

    event TransactionExecuted(bool indexed _success, address indexed _module, address indexed _to, uint _value, bytes _data, Operation _op);
    event ContractDeployed(address _newContract);
    event GotFunds(address indexed _from, uint _amount);

    function initialize(IAuthOracle _oracle) public isInitializer {
        currentNonce = 0;
        oracle = _oracle;
    }

    // TODO take inspiration from Aragon for modulable token receivers
    function () public payable {
        emit GotFunds(msg.sender, msg.value);
    }

    function isNonceValid(uint _nonce) public view returns (bool) {
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
        address _reimbursementToken, // or 0x0 for ETH
        uint _minimumGasNeeded,
        uint _gasPrice,
        bytes _signatures
    ) public view returns (bool) {
        if (!isNonceValid(_nonce)) {
            return false;
        }

        return oracle.authorized(
            _dest,
            _value,
            _data,
            _op,
            _nonce,
            _timestamp,
            _reimbursementToken,
            _minimumGasNeeded,
            _gasPrice,
            _signatures
        );
    }

    function exec(
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
    ) public {
        uint startingGas = gasleft();
        require(startingGas >= _minimumGasNeeded, "Need more gas");

        require(
            isTxValid(
                _dest,
                _value,
                _data,
                _op,
                _nonce,
                _timestamp,
                _reimbursementToken,
                _minimumGasNeeded,
                _gasPrice,
                _signatures
            ),
            "TX is not valid"
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
            // 21000 is for the gas to send the reimbursement
            //uint gasBeforeReimbursement = gasleft();
            //uint amount = (21000 + (startingGas - gasBeforeReimbursement)) * _gasPrice;
            uint amount = (startingGas - gasleft()) * _gasPrice;

            if (_reimbursementToken == 0x0) {
                msg.sender.transfer(amount);
            } else {
                require(ERC20Basic(_reimbursementToken).transfer(msg.sender, amount), "Cannot send token");
            }

            // TODO discuss if this is needed
            // Mitigate the case where a token could choose to use too much gas
            //uint gasUsedForReimbursement = gasBeforeReimbursement - gasleft();
            //assert(gasUsedForReimbursement <= 21000);
        }
    }

    function execFromModule(address _dest, uint _value, bytes _data, Operation _op) public {
        require(oracle.moduleAuthorized(msg.sender, _dest, _value, _data, _op));

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
            // solium-disable-next-line security/no-inline-assembly
            assembly {
                success := call(gasTx, _dest, _value, add(_data, 0x20), mload(_data), 0, 0)
            }
        } else if (_op == Operation.DelegateCall) {
            // solium-disable-next-line security/no-inline-assembly
            assembly {
                success := delegatecall(gasTx, _dest, add(_data, 0x20), mload(_data), 0, 0)
            }
        } else if (_op == Operation.Create) {
            address newContract = 0x0;
            // solium-disable-next-line security/no-inline-assembly
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
