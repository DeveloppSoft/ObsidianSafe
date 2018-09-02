pragma solidity ^0.4.22;


contract Initializable {
    bool public initialized = false;

    modifier isInitializer {
        require(!initialized);
        _;
        initialized = true;
    }
}
