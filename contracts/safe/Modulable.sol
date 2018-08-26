pragma solidity ^0.4.22;

import '../libraries/ListOnSteroids.sol';


contract Modulable {
    using ListOnSteroids for ListOnSteroids.List;

    ListOnSteroids.List private verifModules;
    ListOnSteroids.List private execModules;

    event ModuleChanged(address indexed _module, bool indexed _installed, bool _isVerif, bool _isExec);

    modifier onlyThis {
        require(msg.sender == address(this));
        _;
    }

    constructor(address _initialVerif, address _initialExec) public {
        // Init lists of modules
        verifModules.init();
        execModules.init();

        // Install modules
        // TODO Shall we avoid removing all modules?
        //      Maybe this should be the role of a module?
        verifModules.insert(_initialVerif);
        execModules.insert(_initialExec);
    }

    function installModule(address _module, bool _isVerif, bool _isExec) public onlyThis returns (bool) {
        require(_isVerif || _isExec);
        
        if (_isVerif) {
            verifModules.insert(_module);
        }

        if (_isExec) {
            execModules.insert(_module);
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
        require(_isVerif || _isExec);

        if (_isVerif) {
            verifModules.remove(_previousModule, _module);
        }

        if (_isExec) {
            execModules.remove(_previousModule, _module);
        }

        emit ModuleChanged(
            _module,
            false,
            _isVerif,
            _isExec
        );

        return true;
    }

    function listExecModules() public view returns (address[]) {
        return execModules.list();
    }

    function listVerifModules() public view returns (address[]) {
        return verifModules.list();
    }

    function moduleCanExecuteTx(address _module) internal view returns (bool) {
        return execModules.isIn(_module);
    }
}
