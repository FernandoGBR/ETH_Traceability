pragma solidity ^0.5.0;

contract owned {
    constructor() public{ owner = msg.sender; }
    address owner;

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner");
        _;
    }
}


contract Asset {

    enum AssetState {Created, PendingTransport, InTransport, PendingReceipt, Processed, Finished}
    enum TransactionType {Creation, Transport, InShop}
    struct transaction {
        TransactionType transactionType; //1. Creation 2.Transport 3. In shop 
        address address1;
        address address2;
        string description;
        uint date;
    }
    AssetState public assetState;
    address traceabilityContract;
    transaction[] public transactions;
    
    function setAssetState(AssetState _state) public {
        assetState = _state;
    }

    constructor(address _creator, string memory _description) public{
        traceabilityContract = msg.sender;
        assetState = AssetState.Created;
        transaction memory t;
        t.transactionType = TransactionType.Creation;
        t.description = _description;
        t.address1 = _creator;
        t.date = now;
        transactions.push(t);
    }

    function newTransport(address _from, address _to) public{   
        assetState = AssetState.InTransport;
        transaction memory _t;
        _t.transactionType = TransactionType.Transport;
        _t.address1 = _from;
        _t.address1 = _to;
        _t.date = now;
        transactions.push(_t);
    }
}



contract TraceabilityContract is owned {

    event LogNewTransporter(address indexed transporterAddress, uint index, string registration);
    event LogNewCertifier(address indexed certifierAddress, uint index);
    event LogNewShop(address indexed shopAddress, uint index);
    event LogNewProducer(address indexed producerAddress, uint index);

    struct Transport {
        address from;
        address to;
        address asset;
    }

    struct Transporter{
        string registration; 
        uint index;
        mapping(address => Transport) pendingTransport; // address = addressAsset
        address[] pendingTransportList;
        address activeTransport;
    }
    mapping (address => Transporter) private  transporters;
    address[] public transportersIndex;

    struct Certifier{
        uint index;
    }
    mapping (address => Certifier) private certifiers;
    address[] public certifiersIndex;

    struct Shop{
        uint index;
        mapping(address => Transport) pendingReceipt;  // address = addressAsset
        address[] pendingReceiptList;
        mapping(address => Transport) receivedAssets;  // address = addressAsset
        address[] receivedAssetsList;
    }
    mapping (address => Shop) private shops;
    address[] public shopsIndex;

    struct Producer{
        uint index;
        mapping(address => bool) assetsCreated;
        address[] assetsCreatedList;
        mapping(address => bool) transportersOfProducer;
        address[] transportersOfProducerList;
    }
    mapping (address => Producer) private producers;
    address[] public producersIndex;

    function isTransporter(address transporterAddress) public view returns(bool isIndeed) {
        if(transportersIndex.length == 0) return false;
        return (transportersIndex[transporters[transporterAddress].index] == transporterAddress);
    }
    function isShop(address shopAddress) public view returns(bool isIndeed) {
        if(shopsIndex.length == 0) return false;
        return (shopsIndex[shops[shopAddress].index] == shopAddress);
    } 
    function isCertifier(address certifierAddress) public view returns(bool isIndeed) {
        if(certifiersIndex.length == 0) return false;
        return (certifiersIndex[certifiers[certifierAddress].index] == certifierAddress);
    } 
    function isProducer(address producerAddress) public view returns(bool isIndeed) {
        if(producersIndex.length == 0) return false;
        return (producersIndex[producers[producerAddress].index] == producerAddress);
    } 

    function insertTransporter(address transporterAddress, string memory registration) public onlyOwner returns(uint index){
        require(isTransporter(transporterAddress) == false, "Transporter is already in the system");

        transporters[transporterAddress].registration = registration;
        transporters[transporterAddress].index = transportersIndex.push(transporterAddress)-1;
        emit LogNewTransporter(transporterAddress, transporters[transporterAddress].index, registration);
        return transportersIndex.length-1;
    }

    function insertCertifier(address CertifierAddress) public onlyOwner returns(uint index){
        require(isCertifier(CertifierAddress) == false, "Certifier is already in the system");

        certifiers[CertifierAddress].index = certifiersIndex.push(CertifierAddress)-1;
        emit LogNewCertifier(CertifierAddress, certifiers[CertifierAddress].index);
        return certifiersIndex.length-1;
    }

    function insertShop(address ShopAddress) public onlyOwner returns(uint index){
        require(isShop(ShopAddress) == false, "Shop is already in the system");

        shops[ShopAddress].index = shopsIndex.push(ShopAddress)-1;
        emit LogNewShop(ShopAddress, shops[ShopAddress].index);
        return shopsIndex.length-1;
    }

    function insertProducer(address ProducerAddress) public onlyOwner returns(uint index){
        require(isProducer(ProducerAddress) == false, "Producer is already in the system");

        producers[ProducerAddress].index = producersIndex.push(ProducerAddress)-1;
        emit LogNewProducer(ProducerAddress, producers[ProducerAddress].index);
        return producersIndex.length-1;
    }

    function attachTransporterOfProducer(address transporterAddress) public returns(uint index){
        require(isTransporter(transporterAddress), " transporterAddress is not a transporter");
        require(isProducer(msg.sender), "Only producers can attach transporterOfProducer");
        require(producers[msg.sender].transportersOfProducer[transporterAddress] == false, "transporter already attached");
        producers[msg.sender].transportersOfProducer[transporterAddress] = true;
        producers[msg.sender].transportersOfProducerList.push(transporterAddress);
        return producers[msg.sender].transportersOfProducerList.length;
    }

    function createAsset(string memory _JSON) public returns (address asset){
        require(isProducer(msg.sender), "Only producers can create assets");

        address asset = address(new Asset(msg.sender, _JSON));
        
        producers[msg.sender].assetsCreated[asset] = true;
        producers[msg.sender].assetsCreatedList.push(asset);
        
        return asset;
    }

    function requestTransportStart(address asset, address transporter, address receiver) public returns (bool success){
        require(isProducer(msg.sender), "only producers can request new transport");
        require(isTransporter(transporter), "only transporters can transport");
        require(isShop(receiver), "only shops can receive a transport");
        require(producers[msg.sender].assetsCreated[asset], "only producer who created asset can requestTransportStart");
        require(producers[msg.sender].transportersOfProducer[transporter], "not have this transporter added");
        //require(producers[msg.sender].shopsOfProducer[receiver], "not have this shop added");
        require(Asset(asset).assetState() == Asset.AssetState.Created, "incorrect asset status");

        Transport memory t;
        t.from = msg.sender;
        t.to = receiver;
        t.asset = asset;

        transporters[transporter].pendingTransport[asset] = t;
        transporters[transporter].pendingTransportList.push(asset);
        Asset(asset).setAssetState(Asset.AssetState.PendingTransport);

        return true;
    }

    function startTransport(address from, address asset,uint indexPendingTransport) public returns (bool success){        
        require(isTransporter(msg.sender), "Only transporters can start transport");
        require(transporters[msg.sender].pendingTransport[asset].from != address(0), "transporter have this asset in pending transport");
        require(Asset(asset).assetState() == Asset.AssetState.PendingTransport, "incorrect asset status");

        transporters[msg.sender].activeTransport = asset; //define new activeTransport

        // delete pending Transport
        if(indexPendingTransport != transporters[msg.sender].pendingTransportList.length-1){
            transporters[msg.sender]
            .pendingTransportList[indexPendingTransport] = transporters[msg.sender].pendingTransportList[transporters[msg.sender].pendingTransportList.length-1];
        }
        transporters[msg.sender].pendingTransportList.length--;


        //transport started
        Asset(asset).setAssetState(Asset.AssetState.InTransport);

        //inform asset about new transaction
        Asset(asset).newTransport(from, msg.sender);

        return true;
    }
    
    function requestTransportEnd() public returns (bool success){
        require(isTransporter(msg.sender), "Only the transporter can request transport end"); 
        require(transporters[msg.sender].activeTransport != address(0), " transporter have activeTransport");
        Transport storage transportActive = transporters[msg.sender].pendingTransport[transporters[msg.sender].activeTransport];   
        require(Asset(transportActive.asset).assetState() == Asset.AssetState.InTransport, "incorrect asset status");

        shops[transportActive.to].pendingReceipt[transportActive.asset] = transportActive;
        shops[transportActive.to].pendingReceiptList.push(transportActive.asset);
        
        Asset(transportActive.asset).setAssetState(Asset.AssetState.PendingReceipt);

        return true;
    }

    function endTransport(uint indexPendingReceipt) public returns (bool success){      
        require(isShop(msg.sender), "Only shop can receive Asset");
        Transport storage transportPending = shops[msg.sender].pendingReceipt[shops[msg.sender].pendingReceiptList[indexPendingReceipt]];
        require(transportPending.asset != address(0), "have pending receipt");
        require(Asset(transportPending.asset).assetState() == Asset.AssetState.PendingReceipt, "incorrect asset status");


        //add transaction to the asset history
        Asset(transportPending.asset).newTransport(transportPending.to, msg.sender);
        Asset(transportPending.asset).setAssetState(Asset.AssetState.Finished);
        // delete pending Receipt
        if(indexPendingReceipt != shops[msg.sender].pendingReceiptList.length-1){
            shops[msg.sender]
            .pendingReceiptList[indexPendingReceipt] = shops[msg.sender].pendingReceiptList[shops[msg.sender].pendingReceiptList.length-1];
        }
        shops[msg.sender].pendingReceiptList.length--;

        shops[msg.sender].receivedAssets[transportPending.asset] = transportPending;
        shops[msg.sender].receivedAssetsList.push(transportPending.asset);
        return true;
    }

    constructor() public{
    }


}

