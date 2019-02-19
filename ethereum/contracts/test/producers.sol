pragma solidity ^0.5.0;

import "./transporters_users.sol";
import "./asset.sol";

contract Producers {

    address traceabilityContract;    

    struct Producer{
        string registrationData; //extra data given on register

        uint index; //index on the global producer list

        mapping(address => uint) assetsCreatedIndex;
        address[] assetsCreatedList;

        //mapping(address => Transporter_User) transporters; //address = transporterAddress
        //Transporter_User[] transportersList;         
    }
    mapping (address => Producer) private producers;
    address[] public producersIndex;

    constructor (address _tc) public{
        traceabilityContract = _tc;        
    }    

    function isProducer(address producerAddress) public view returns(bool isIndeed) {
        if(producersIndex.length == 0) return false;
        return (producersIndex[producers[producerAddress].index] == producerAddress);
    }

    function insertProducer(address ProducerAddress, string memory _data) public returns(uint index){    
        require(msg.sender == traceabilityContract, "only TC can do this call");
        require(isProducer(ProducerAddress) == false, "Producer is already in the system");

        producers[ProducerAddress].registrationData = _data;
        producers[ProducerAddress].index = producersIndex.push(ProducerAddress)-1;        
        return producersIndex.length-1;
    }

    function createAsset(address _producerAddress, string memory _JSON) public returns (address asset){
        require(msg.sender == traceabilityContract, "only TC can do this call");
        require(isProducer(_producerAddress), "Only producers can create assets");

        asset = address(new Asset(_producerAddress, _JSON));        
        producers[msg.sender].assetsCreatedIndex[asset] = producers[msg.sender].assetsCreatedList.push(asset) - 1;
               
        return asset;
    }

}