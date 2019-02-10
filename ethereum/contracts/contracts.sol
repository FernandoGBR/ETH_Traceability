pragma solidity ^0.5.1;

contract TraceabilityContract {
    
    mapping (address => uint8) public roles; //1. Superadmin, 2. Productor, 3. Transporter, 4. Certifier, 5. Shop
    
    address superAdmin;
    address[] shops;
    address[] producers;
    mapping (address => address[]) transportersOf; //List of transporters of an entity
    mapping (address => address[]) transportersTo; //List of entities of a transporter
    mapping (address => address[]) certifierOf; //List of cerifiers of a producer
    mapping (address => address[]) certifierTo; //List of producers certified by a certifier
    
    mapping (address => address[]) assetsOwned; //List of address of the assets owned by one entity
    mapping (address => address) assetOwner; //Owner of each asset in a given moment;
    
    
    modifier onlySuperAdmin(){
        require (roles[msg.sender] == 1, "Super Admin only function");
        _;
    }
    
    constructor() public{
        superAdmin = msg.sender;
        roles[msg.sender] = 1;
    }
    
    function newProductor(address addressToAdd) public onlySuperAdmin returns (bool success){
        require(roles[addressToAdd] == 0, "addressToAdd already has a role");
        
        roles[addressToAdd] = 2;
        producers.push(addressToAdd);
        
        return true;
    }
    
    function newShop(address addressToAdd) public onlySuperAdmin returns (bool success){
        require(roles[addressToAdd] == 0, "addressToAdd already has a role");
        
        roles[addressToAdd] = 5;
        shops.push(addressToAdd);
        
        return true;
    }
    
    function newTransporter(address addressToAdd) public returns (bool success){
        require(roles[addressToAdd] == 0, "addressToAdd already has a role");
        require(roles[msg.sender] == 1 || roles[msg.sender] == 2, "Only superAdmin and producers can add new transporters" );
        
        transportersOf[msg.sender].push(addressToAdd);
        transportersTo[addressToAdd].push(msg.sender);
        
        roles[addressToAdd] = 3;
        return true;
    }
    
    function newCertifier(address addressToAdd) public returns (bool success){
        require(roles[addressToAdd] == 0, "addressToAdd already has a role");
        require(roles[msg.sender] == 2, "Only producers can add new certifiers" );
        
        certifierOf[msg.sender].push(addressToAdd);
        certifierTo[addressToAdd].push(msg.sender);
        
        roles[addressToAdd] = 4;
        return true;
    }
    
    function useTransporter(address addressToUse) public returns (bool success){
        require(roles[addressToUse] == 3, "addressToUse is not a transporter");
        require(roles[msg.sender] == 1 || roles[msg.sender] == 2, "Only superAdmin and producers can use transporters" );
        
        transportersOf[msg.sender].push(addressToUse);
        transportersTo[addressToUse].push(msg.sender);
        
        return true;
    }
    
    function useCertifier(address addressToUse) public returns (bool success){
        require(roles[addressToUse] == 0, "addressToUse is not a certifier");
        require(roles[msg.sender] == 2, "Only producers can use certifiers" );
        
        certifierOf[msg.sender].push(addressToUse);
        certifierTo[addressToUse].push(msg.sender);
        
        roles[addressToUse] = 4;
        return true;
    }
    
    function createAsset(string memory _JSON) public returns (bool success){
        require(roles[msg.sender] == 2, "Only producers can create assets");
        
        Asset asset = new Asset(msg.sender, _JSON);
        
        //TODO: Get asset address
        address assetAddress;
        
        assetsOwned[msg.sender].push(assetAddress);
        assetOwner[assetAddress] = msg.sender;
        
        return true;
    }
}


contract Asset {
    struct transaction {
        uint8 transactionType; //1. Creation
        address address1;
        address address2;
        string description;
        uint date;
    }
    
    address traceabilityContract;
    transaction[] transactions;
    
    constructor(address _creator, string memory _description) public{
        traceabilityContract = msg.sender;
        
        transaction memory t;
        t.transactionType = 1;
        t.description = _description;
        t.address1 = _creator;
        t.date = now;
    }
}

