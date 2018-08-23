pragma solidity ^0.4.22;
pragma experimental ABIEncoderV2; // for bytes[]

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol';

import '../modules/IModule.sol';
import './ISafe.sol';
import './TransactionUtils.sol';

// Credits to the GNOSIS Safe for the executeTx() function and
// the inspiration for the module management

// Albeit we don't use getTxHash it is added to be used by users
// and modules

contract Safe is ISafe, TransactionUtils {
    using SafeMath for uint;

    address private constant MODULE_HEAD_MARKER = 0x1;

    uint private nbVerifModules = 0;
    uint private nbExecModules = 0;

    mapping (address => address) private verifModules;
    mapping (address => address) private execModules;

    uint public currentNonce; // Increment for each TX

    bool private initialized = false;

    event TransactionExecuted(bool indexed _success, address indexed _module, address indexed _to, uint _value, bytes _data, Operation _op);
    event ContractDeployed(address _newContract);
    event ModuleChanged(address indexed _module, bool indexed _installed, bool _isVerif, bool _isExec);

    modifier onlyThis {
        require(msg.sender == address(this) || !initialized);
        _;
    }

    constructor(address _initialVerif, address _initialExec) public {
        currentNonce = 0;

        // Init lists of modules
        verifModules[MODULE_HEAD_MARKER] = MODULE_HEAD_MARKER;
        execModules[MODULE_HEAD_MARKER] = MODULE_HEAD_MARKER;

        // Install modules
        // TODO Shall we avoid removing all modules?
        //      Maybe this should be the role of a module?
        installModule(_initialVerif, true, false);
        installModule(_initialExec, false, true);

        initialized = true;
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

        address[] memory allVerifModules = getVerifModules();
        for (uint i = 0; i < allVerifModules.length; i++) {
            if (!IModule(allVerifModules[i]).verify(
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
        require(isRegisteredExecutionModule(msg.sender));

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

    function getVerifModules() public view returns (address[]) {
        address[] memory allVerifModules = new address[](nbVerifModules);

        uint index = 0;
        address currentModule = verifModules[MODULE_HEAD_MARKER];

        // Goes from one marker to the second
        while (currentModule != MODULE_HEAD_MARKER) {
            allVerifModules[index] = currentModule; // Save
            index++; // Next element

            currentModule = verifModules[currentModule]; // Next module
        }

        return allVerifModules;
    }

    function getExecModules() public view returns (address[]) {
        address[] memory allExecModules = new address[](nbExecModules);

        uint index = 0;
        address currentModule = execModules[MODULE_HEAD_MARKER];

        // Goes from one marker to the second
        while (currentModule != MODULE_HEAD_MARKER) {
            allExecModules[index] = currentModule; // Save
            index++; // Next element

            currentModule = execModules[currentModule]; // Next module
        }

        return allExecModules;
    }

    function isRegisteredExecutionModule(address _module) internal view returns (bool) {
        return execModules[_module] != 0x0;
    }

    function installModule(address _module, bool _isVerif, bool _isExec) public onlyThis returns (bool) {
        require(_module != MODULE_HEAD_MARKER && _module != 0x0, "Invalid Module");
        require(_isVerif || _isExec);
        
        if (_isVerif) {
            require(verifModules[_module] == 0x0, "Module is already installed");

            verifModules[_module] = verifModules[MODULE_HEAD_MARKER];
            verifModules[MODULE_HEAD_MARKER] = _module;

            nbVerifModules++;
        }

        if (_isExec) {
            require(execModules[_module] == 0x0, "Module is already installed");

            execModules[_module] = execModules[MODULE_HEAD_MARKER];
            execModules[MODULE_HEAD_MARKER] = _module;

            nbExecModules++;
        }

        emit ModuleChanged(
            _module,
            true,
            _isVerif,
            _isExec
        );

        return true;
    }

    function uninstallModule(address _previousModule, address _module, bool _isVerif, bool _isExec) public onlyThis returns (bool) {
        require(_module != MODULE_HEAD_MARKER && _module != 0x0, "Invalid Module");
        require(_isVerif || _isExec);

        if (_isVerif) {
            require(verifModules[_module] != 0x0, "Module is not installed");
            require(verifModules[_previousModule] == _module, "Invalid module pair");

            verifModules[_previousModule] = verifModules[_module];
            verifModules[_module] = 0x0;

            nbVerifModules--;
        }

        if (_isExec) {
            require(execModules[_module] != 0x0, "Module is not installed");
            require(execModules[_previousModule] == _module, "Invalid module pair");

            execModules[_previousModule] = execModules[_module];
            execModules[_module] = 0x0;

            nbExecModules--;
        }

        emit ModuleChanged(
            _module,
            false,
            _isVerif,
            _isExec
        );

        return true;
    }
}
