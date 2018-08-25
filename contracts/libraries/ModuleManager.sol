pragma solidity ^0.4.22;


library ModuleManager {
    struct Modules {
        uint nbModules;
        mapping (address => address) modules;
        mapping (address => bool) moduleIn;
    }

    address private constant MODULE_HEAD_MARKER = 0x1;

    function init(Modules storage self) public {
        self.modules[MODULE_HEAD_MARKER] = MODULE_HEAD_MARKER;
        self.nbModules = 0;
    }

    function insert(Modules storage self, address _module) public {
        require(_module != MODULE_HEAD_MARKER && _module != 0x0, "Invalid address");
        require(self.moduleIn[_module] == false, "Module already installed");

        self.modules[_module] = self.modules[MODULE_HEAD_MARKER];
        self.modules[MODULE_HEAD_MARKER] = _module;

        self.moduleIn[_module] = true;

        self.nbModules++;
    }

    function remove(Modules storage self, address _prevModule, address _module) public {
        require(_module != MODULE_HEAD_MARKER && _module != 0x0, "Invalid address");
        require(self.moduleIn[_module] == true, "Module not installed");
        require(self.modules[_prevModule] == _module, "Invalid pair");

        self.modules[_prevModule] = self.modules[_module];
        self.modules[_module] = 0x0;

        self.moduleIn[_module] = false;

        self.nbModules--;
    }

    function list(Modules storage self) public view returns (address[]) {
        address[] memory allModules = new address[](self.nbModules);

        uint index = 0;
        address currentModule = self.modules[MODULE_HEAD_MARKER];

        while (currentModule != MODULE_HEAD_MARKER) {
            allModules[index] = currentModule;
            index++;

            currentModule = self.modules[currentModule];
        }

        return allModules;
    }

    function isIn(Modules storage self, address _module) public view returns (bool) {
        if (_module == 0x0 || _module == MODULE_HEAD_MARKER) {
            return false;
        }

        return self.moduleIn[_module];
    }
}
