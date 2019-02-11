pragma solidity ^0.5.1;

contract TraceabilityContract {
    
    mapping (address => uint8) public roles; //1. Superadmin, 2. Productor, 3. Transporter, 4. Certifier, 5. Shop
    
    address superAdmin;
    address[] shops;
    address[] producers;
    mapping (address => address[]) transportersOf; //List of transporters of an entity
    mapping (address => address[]) transportersTo; //List of entities of a transporter
    mapping (address => address) requestTransport; // Lista de pedidos de transporte
    mapping (address => address) inTransport; // Lista de pedidos en transporte
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
    
    function useTransporter(address addressToUse, address assetAddress) public returns (bool success){
        require(roles[addressToUse] == 3, "addressToUse is not a transporter");
        require(roles[msg.sender] == 1 || roles[msg.sender] == 2, "Only superAdmin and producers can use transporters" );
        require(assetOwner[assetAddress] == msg.sender, "Only owner to asset can useTransporter");
        
        transportersOf[msg.sender].push(addressToUse);
        transportersTo[addressToUse].push(msg.sender);
        
        requestTransport[assetAddress]=addressToUse;//add request to transfer
        return true;
    }
    function initTransporter(address addressFromInit, address assetAddress, string memory _JSON) public returns (bool success){
        require(roles[addressFromInit] == 2 || roles[addressFromInit] == 5, "addressFromInit is producers or shop");
        require(roles[msg.sender] == 3 , "Only transporters can init transport" );
        require(requestTransport[assetAddress] == msg.sender, "Only can init transporter if asset have requestTransport");

        //transporte iniciado
        //añadir informacion de transaction al asset
        Asset(assetAddress).addTransaction(2 , addressFromInit, msg.sender, _JSON);
        requestTransport[assetAddress] = address(0);
        inTransport[assetAddress] = msg.sender;
        return true;
    }
    function finishTransporter(address addressToFinish, address assetAddress, string memory _JSON) public returns (bool success){
        require( roles[addressToFinish] == 5, "addressToFinish is a shop");
        require(roles[msg.sender] == 3 , "Only transporters can finish transport" );
        require(inTransport[assetAddress] == msg.sender, "Only can finish transporter if asset have inTransport");

        //transporte finalizado por parte del transportista
        Asset(assetAddress).addTransaction(2 , msg.sender, addressToFinish, _JSON);
        //send event para avisar a la tienda
        return true;
    }
        function receiveAsset(address addressToTransport, address assetAddress, string memory _JSON) public returns (bool success){
        require( roles[addressToTransport] == 2, "addressToTransport is not transporter");
        require(roles[msg.sender] == 5 , "Only shop can receive Asset" );
        require(inTransport[assetAddress] == addressToTransport, "Only can finish transporter if asset have inTransport");

        //transporte finalizado por parte de la tienda
        Asset(assetAddress).addTransaction(3 , addressToTransport,msg.sender , _JSON);
        inTransport[assetAddress] = address(0);
        return true;
    }
    
    function useCertifier(address addressToUse) public returns (bool success){
        require(roles[addressToUse] == 0, "addressToUse is not a certifier");
        require(roles[msg.sender] == 2, "Only producers can use certifiers" );
        
        certifierOf[msg.sender].push(addressToUse);
        certifierTo[addressToUse].push(msg.sender);
        
        //roles[addressToUse] = 4;
        return true;
    }
    
    function createAsset(string memory _JSON) public returns (bool success){
        require(roles[msg.sender] == 2, "Only producers can create assets");
        
        Asset asset = new Asset(msg.sender, _JSON);
        
           //No se puede recoger el address del assert recien creado, tiene que confirmarse en la blockchain, por tanto llamamos a un evento y con web3 capturaremos ese evento y recogeremos el address del contrato creado
           // https://ethereum.stackexchange.com/questions/35679/how-to-return-address-from-newly-created-contract
        address assetAddress;
        
        assetsOwned[msg.sender].push(assetAddress);
        assetOwner[assetAddress] = msg.sender;
        
        return true;
    }
}


contract Asset {
    struct transaction {
        uint8 transactionType; //1. Creation 2.Transporter 3. In shop 
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
        transactions.push(t);
    }
    function addTransaction(uint8 _transactionType, address _address1, address _address2, string memory _description) public{
        
         transaction memory t;
        t.transactionType = _transactionType;
        t.description = _description;
        t.address1 = _address1;
        t.address1 = _address2;
        t.date = now;
        transactions.push(t);
    }
}

