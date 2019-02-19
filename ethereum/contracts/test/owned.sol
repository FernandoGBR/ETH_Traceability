pragma solidity ^0.5.0;

contract owned {
    constructor() public{ owner = msg.sender; }
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner");
        _;
    }
}