pragma solidity^0.4.22;

// Modofied version of https://github.com/skmgoldin/sol-dll

library DLL {
    address constant private NULL_NODE_ID = 0;

    struct Node {
        address next;
        address prev;
    }

    struct Data {
        uint nbElems;
        mapping(address => Node) dll;
    }

    function isEmpty(Data storage self) public view returns (bool) {
        return getStart(self) == NULL_NODE_ID;
    }

    function contains(Data storage self, address _curr) public view returns (bool) {
        if (isEmpty(self) || _curr == NULL_NODE_ID) {
            return false;
        } 

        bool isSingleNode = (getStart(self) == _curr) && (getEnd(self) == _curr);
        bool isNullNode = (getNext(self, _curr) == NULL_NODE_ID) && (getPrev(self, _curr) == NULL_NODE_ID);
        return isSingleNode || !isNullNode;
    }

    function getNext(Data storage self, address _curr) public view returns (address) {
        return self.dll[_curr].next;
    }

    function getPrev(Data storage self, address _curr) public view returns (address) {
        return self.dll[_curr].prev;
    }

    function getStart(Data storage self) public view returns (address) {
        return getNext(self, NULL_NODE_ID);
    }

    function getEnd(Data storage self) public view returns (address) {
        return getPrev(self, NULL_NODE_ID);
    }

    function append(Data storage self, address _curr) public {
        require(!contains(self, _curr), "Element already in list");
        require(_curr != NULL_NODE_ID, "Element invalid");

        address next = getNext(self, NULL_NODE_ID);
        address prev = NULL_NODE_ID;

        self.dll[_curr].prev = prev;
        self.dll[_curr].next = next;

        self.dll[next].prev = _curr;
        self.dll[prev].next = _curr;

        self.nbElems++;
    }

    function remove(Data storage self, address _curr) public {
        require(contains(self, _curr), "Element is not in list");

        address next = getNext(self, _curr);
        address  prev = getPrev(self, _curr);

        self.dll[next].prev = prev;
        self.dll[prev].next = next;

        delete self.dll[_curr];
        self.nbElems--;
    }

    function list(Data storage self) public view returns (address[]) {
        address[] memory dll = new address[](self.nbElems);
        address current = NULL_NODE_ID;

        for (uint i = 0; i < self.nbElems; i++) {
            current = getNext(self, current);
            dll[i] = current;
        }

        return dll;
    }
}
