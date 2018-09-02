pragma solidity ^0.4.22;

// A list helper, but with steroids

library ListOnSteroids {
    struct List {
        uint nbElems;
        mapping (address => address) previous;
        mapping (address => address) next;
        mapping (address => bool) elemIn;
    }

    address private constant SENTINEL = 0x1;

    function init(List storage self) public {
        self.next[SENTINEL] = SENTINEL;
        self.previous[SENTINEL] = SENTINEL;

        self.nbElems = 0;
    }

    function insert(List storage self, address _element) public {
        require(_element != SENTINEL && _element != 0x0, "Invalid address");
        require(self.elemIn[_element] == false, "Address already listed");

        self.previous[self.next[SENTINEL]] = _element;
        self.previous[_element] = SENTINEL;

        self.next[_element] = self.next[SENTINEL];
        self.next[SENTINEL] = _element;

        self.elemIn[_element] = true;

        self.nbElems++;
    }

    function remove(List storage self, address _element) public {
        //require(_element != SENTINEL && _element != 0x0, "Invalid address");
        require(self.elemIn[_element] == true, "Address not listed");

        address prev = self.previous[_element];
        address next = self.next[_element];
        assert(prev != 0x0);
        assert(next != 0x0);

        self.previous[next] = self.previous[_element];
        self.next[prev] = self.next[_element];

        self.previous[_element] = 0x0;
        self.next[_element] = 0x0;

        self.elemIn[_element] = false;

        self.nbElems--;
    }

    function list(List storage self) public view returns (address[]) {
        address[] memory allElems = new address[](self.nbElems);

        uint index = 0;
        address currentElem = self.next[SENTINEL];

        while (currentElem != SENTINEL) {
            allElems[index] = currentElem;
            index++;

            currentElem = self.next[currentElem];
        }

        return allElems;
    }

    function isIn(List storage self, address _element) public view returns (bool) {
        return self.elemIn[_element] != 0x0;
    }
}
