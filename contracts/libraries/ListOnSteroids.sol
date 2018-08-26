pragma solidity ^0.4.22;

// A list helper, but with steroids

library ListOnSteroids {
    struct List {
        uint nbElems;
        mapping (address => address) elements;
        mapping (address => bool) elemIn;
    }

    address private constant MODULE_HEAD_MARKER = 0x1;

    function init(List storage self) public {
        self.elements[MODULE_HEAD_MARKER] = MODULE_HEAD_MARKER;
        self.nbElems = 0;
    }

    function insert(List storage self, address _module) public {
        require(_module != MODULE_HEAD_MARKER && _module != 0x0, "Invalid address");
        require(self.elemIn[_module] == false, "Address already listed");

        self.elements[_module] = self.elements[MODULE_HEAD_MARKER];
        self.elements[MODULE_HEAD_MARKER] = _module;

        self.elemIn[_module] = true;

        self.nbElems++;
    }

    function remove(List storage self, address _prevModule, address _module) public {
        require(_module != MODULE_HEAD_MARKER && _module != 0x0, "Invalid address");
        require(self.elemIn[_module] == true, "Address not listed");
        require(self.elements[_prevModule] == _module, "Invalid pair");

        self.elements[_prevModule] = self.elements[_module];
        self.elements[_module] = 0x0;

        self.elemIn[_module] = false;

        self.nbElems--;
    }

    function list(List storage self) public view returns (address[]) {
        address[] memory allElems = new address[](self.nbElems);

        uint index = 0;
        address currentElem = self.elements[MODULE_HEAD_MARKER];

        while (currentElem != MODULE_HEAD_MARKER) {
            allElems[index] = currentElem;
            index++;

            currentElem = self.elements[currentElem];
        }

        return allElems;
    }

    function isIn(List storage self, address _module) public view returns (bool) {
        if (_module == 0x0 || _module == MODULE_HEAD_MARKER) {
            return false;
        }

        return self.elemIn[_module];
    }
}
