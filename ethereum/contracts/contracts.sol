pragma solidity ^0.5.0;

contract TraceabilityContract {
    
    struct transport {
        address from;
        address to;
        address asset;
        bool acepted;
    }

    mapping (address => uint8) public roles; //1. Superadmin, 2. Productor, 3. Transporter, 4. Certifier, 5. Shop
    
    address superAdmin;
    address[] shops;
    address[] producers;
    mapping (address => address[]) transportersOf; //List of transporters of an entity
    mapping (address => address[]) transportersTo; //List of entities of a transporter
    mapping (address => address[]) certifierOf; //List of cerifiers of a producer
    mapping (address => address[]) certifierTo; //List of producers certified by a certifier
    
    mapping (address => address[]) assetsOwned; //List of address of the assets owned by one entity (must recheck the ownage in assetOwner)
    mapping (address => address) assetOwner; //Owner of each asset in a given moment;

    mapping (address => address[]) transports; //List of assets to transport from a transporter (must recheck the transport)
                                               //(transporter => asset[])
    mapping (address => mapping (address => transport)) transports_asset;

    mapping (address => address[]) receivingAssets; //List of assets to be received by the shops;

    
    modifier onlySuperAdmin(){
        require (roles[msg.sender] == 1, "Super Admin only function");
        _;
    }
    
    constructor() public{
        superAdmin = msg.sender;
        roles[msg.sender] = 1;
    }
    
    function newProductor(address productor) public onlySuperAdmin returns (bool success){
        require(roles[productor] == 0, "productor already has a role");
        
        roles[productor] = 2;
        producers.push(productor);
        
        return true;
    }
    
    function newShop(address shop) public onlySuperAdmin returns (bool success){
        require(roles[shop] == 0, "shop already has a role");
        
        roles[shop] = 5;
        shops.push(shop);
        
        return true;
    }
    
    function newTransporter(address transporter) public returns (bool success){
        require(roles[transporter] == 0, "transporter already has a role");
        require(roles[msg.sender] == 1 || roles[msg.sender] == 2, "Only superAdmin and producers can add new transporters");
        
        transportersOf[msg.sender].push(transporter);
        transportersTo[transporter].push(msg.sender);
        
        roles[transporter] = 3;
        return true;
    }
    
    function newCertifier(address certifier) public returns (bool success){
        require(roles[certifier] == 0, "certifier already has a role");
        require(roles[msg.sender] == 2, "Only producers can add new certifiers");
        
        certifierOf[msg.sender].push(certifier);
        certifierTo[certifier].push(msg.sender);
        
        roles[certifier] = 4;
        return true;
    }
    
    function attachTransporter(address transporter, address assetAddress) public returns (bool success){
        require(roles[transporter] == 3, "transporter is not a transporter");
        require(roles[msg.sender] == 1 || roles[msg.sender] == 2, "Only superAdmin and producers can use transporters");
        require(assetOwner[assetAddress] == msg.sender, "Only owner to asset can useTransporter");
        
        transportersOf[msg.sender].push(transporter);
        transportersTo[transporter].push(msg.sender);
    
        return true;
    }   
    
    function attachCertifier(address certifier) public returns (bool success){
        require(roles[certifier] == 4, "certifier is not a certifier");
        require(roles[msg.sender] == 2, "Only producers can use certifiers");
        
        certifierOf[msg.sender].push(certifier);
        certifierTo[certifier].push(msg.sender);
        
        return true;
    }

    function requestTransportStart(address asset, address transporter, address receiver) public returns (bool success){
        require(roles[msg.sender] == 2, "only producers can request new transport");
        require(roles[transporter] == 3, "only transporters can transport");
        require(roles[receiver] == 5, "only shops can receive a transport");

        require(assetOwner[asset] == msg.sender, "only the owner of the asset can request a transport");

        transport memory t;
        t.from = msg.sender;
        t.to = receiver;
        t.asset = asset;
        t.acepted = false;

        transports_asset[transporter][asset] = t;
        transports[transporter].push(asset);

        return true;
    }

    function startTransport(address from, address asset) public returns (bool success){        
        require(roles[msg.sender] == 3, "Only transporters can start transport");
        require(transports_asset[msg.sender][asset].from != address(0), "Transporter must have a request for the asset");    

        //transport started
        transports_asset[msg.sender][asset].acepted = true;


        //inform asset about new transaction
        Asset(asset).newTransport(from, msg.sender);
        
        //change asset owner
        assetsOwned[msg.sender].push(asset);        
        assetOwner[asset] = msg.sender;

        return true;
    }

    function requestTransportEnd(address asset) public returns (bool success){        
        require(assetOwner[asset] == msg.sender, "Only the transporter owner can request transport end");
        require(roles[msg.sender] == 3, "Only transporters can request transport end");
               

        address receiver = transports_asset[msg.sender][asset].to;
        receivingAssets[receiver].push(asset);

        return true;
    }

    function endTransport(address asset) public returns (bool success){        
        require(roles[msg.sender] == 5, "Only shop can receive Asset");

        address transporter = assetOwner[asset];
        require(transports_asset[transporter][asset].from != address(0), "asset must be in transport");
        require(transports_asset[transporter][asset].to == msg.sender, "sender must be the asset receiver");
        require(transports_asset[transporter][asset].acepted, "transport must be started");

        //add transaction to the asset history
        Asset(asset).newTransport(transporter, msg.sender);
        
        //Delete ongoing transport
        delete transports_asset[transporter][asset];

        //Change ownage
        assetsOwned[msg.sender].push(asset);        
        assetOwner[asset] = msg.sender;

        return true;
    }
    
    function createAsset(string memory _JSON) public returns (bool success){
        require(roles[msg.sender] == 2, "Only producers can create assets");
        
        address asset = address(new Asset(msg.sender, _JSON));
        
        assetsOwned[msg.sender].push(asset);
        assetOwner[asset] = msg.sender;
        
        return true;
    }

    function getOwnedAssets() public returns (address[] memory assets){
        require(roles[msg.sender] == 2 || roles[msg.sender] == 3 || roles[msg.sender] == 5, "sender is not a possible owner");

        //purge old ownages
        uint _length = assetsOwned[msg.sender].length;
        for(uint _i = 0; _i < _length; _i++){
            address _asset = assetsOwned[msg.sender][_i];
            if(assetOwner[_asset]!=msg.sender){
                assetsOwned[msg.sender][_i] = assetsOwned[msg.sender][_length - 1];
                delete assetsOwned[msg.sender][_length - 1];
                _length--;
                _i--;                
            }
        }

        return assetsOwned[msg.sender];
    }
}


contract Asset {
    struct transaction {
        uint8 transactionType; //1. Creation 2.Transport 3. In shop 
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

    function newTransport(address _from, address _to) public{        
        transaction memory _t;
        _t.transactionType = 2;
        _t.address1 = _from;
        _t.address1 = _to;
        _t.date = now;
        transactions.push(_t);
    }
}

