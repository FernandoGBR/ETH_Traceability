pragma solidity ^0.5.0;

import "./transporters_users.sol";

contract Transporters {
    address traceabilityContract;    

    struct Transporter{
        string registrationData; //extra data given on register

        uint index; // index on the global transporter list

        mapping(address => bool) users; //address == userAddress
        address[] usersList;        
    }    
    mapping (address => Transporter) private  transporters;
    address[] public transportersList;

    constructor (address _tc) public{
        traceabilityContract = _tc;        
    }   

    function isTransporter(address transporterAddress) public view returns(bool isIndeed) {
        if(transportersList.length == 0) return false;
        return (transportersList[transporters[transporterAddress].index] == transporterAddress);
    }

    function insertTransporter(        
        address _transporterAddress,
        string memory _registrationData
    ) public returns(bool success){ 
        require(msg.sender == traceabilityContract, "only TC can do this call");       
        require(isTransporter(_transporterAddress) == false, "Transporter is already in the system");  
        
        transporters[_transporterAddress].registrationData = _registrationData;
        transporters[_transporterAddress].index = transportersList.push(_transporterAddress) - 1;        

        return true;
    }
    
}