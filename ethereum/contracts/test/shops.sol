pragma solidity ^0.5.0;

contract Shops {
    address traceabilityContract;

    struct Shop{
        string registrationData; //extra data given on register

        uint index; //index on the global shop list
        mapping(address => uint) pendingAssets;  // address = addressAsset
        address[] pendingTransportsList;
        
        mapping(address => uint) assetsIndex; // address = addressAsset
        address[] assetsList;
    }
    mapping (address => Shop) private shops;
    address[] public shopsIndex;

    constructor (address _tc) public{
        traceabilityContract = _tc;
    }

    function isShop(address shopAddress) public view returns(bool isIndeed) {
        if(shopsIndex.length == 0) return false;
        return (shopsIndex[shops[shopAddress].index] == shopAddress);
    }

    function insertShop(address _shopAddress, string memory _data) public returns(uint index){
        require(msg.sender == traceabilityContract, "only TC can do this call");
        require(isShop(_shopAddress) == false, "Shop is already in the system");

        shops[_shopAddress].registrationData = _data;
        shops[_shopAddress].index = shopsIndex.push(_shopAddress)-1;        
        return shopsIndex.length-1;
    }

    function addPendingAsset(address _shopAddress, address _assetAddress) public returns (bool success){
        require(msg.sender == traceabilityContract, "only TC can do this call");
        require(isShop(_shopAddress), "Wrong shopAddress provided");

        shops[_shopAddress].pendingAssets[_assetAddress] = shops[_shopAddress].pendingTransportsList.push(_assetAddress) - 1;
        return true;
    }
}