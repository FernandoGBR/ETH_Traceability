pragma solidity ^0.5.0;

contract owned {
    constructor() public{ owner = msg.sender; }
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner");
        _;
    }
}


contract Asset { 

    enum AssetState {Waiting, PendingTransport, InTransport, PendingReceipt, Consumed}
    enum TransactionType {Creation, TransportStartRequest, TransportStart, TransportEndRequest, TransportEnd, Consume}
    struct transaction {
        TransactionType transactionType;
        address address1;
        address address2;
        string description;
        uint date;
    }
    AssetState assetState;
    address traceabilityContract; 
    address public owner;
    transaction[] public transactions;

    constructor(address _creator, string memory _description) public{
        traceabilityContract = msg.sender;
        assetState = AssetState.Waiting;
        owner = _creator;

        transaction memory t;
        t.transactionType = TransactionType.Creation;
        t.description = _description;
        t.address1 = _creator;
        t.date = now;
        transactions.push(t);
        
    }

    function askForTransport(address _from, address _to) public{
        require(_from == owner, "Only owner of the asset can ask for transport");
        require(assetState == AssetState.Waiting, "Can not ask for transport if asset is not waiting");
        assetState = AssetState.PendingTransport;
        transaction memory _t;
        _t.transactionType = TransactionType.TransportStartRequest;
        _t.address1 = _from;
        _t.address1 = _to;
        _t.date = now;
        transactions.push(_t);
    }

    function getTransportData() public view returns (address _from, address _transporter){
        require (
            assetState == AssetState.PendingTransport || assetState == AssetState.InTransport || assetState == AssetState.PendingReceipt,
            "asset is not pending of transport"
        );

        _from = transactions[transactions.length - 1].address1;
        _transporter = transactions[transactions.length - 1].address2;
    }

    function newTransport(address _from, address _to) public {
        assetState = AssetState.InTransport;
        owner = _to;
        transaction memory _t;
        _t.transactionType = TransactionType.TransportStart;
        _t.address1 = _from;
        _t.address1 = _to;
        _t.date = now;
        transactions.push(_t);
    }

    function askForTransportEnd(address _from, address _to) public{
        require(_from == owner, "only owner of the asset can ask for end Transport");        
        assetState = AssetState.PendingReceipt;
        transaction memory _t;
        _t.transactionType = TransactionType.TransportEndRequest;
        _t.address1 = _from;
        _t.address1 = _to;
        _t.date = now;
        transactions.push(_t);
    }

    function endTransport(address _from, address _to) public {
        assetState = AssetState.Waiting;
        owner = _to;
        transaction memory _t;
        _t.transactionType = TransactionType.TransportEnd;
        _t.address1 = _from;
        _t.address1 = _to;
        _t.date = now;
        transactions.push(_t);
    }
}



contract TraceabilityContract is owned {

    event LogNewTransporter(address indexed transporterAddress, string registrationData);
    event LogNewCertifier(address indexed certifierAddress, string registrationData);
    event LogNewShop(address indexed shopAddress, string registrationData);
    event LogNewProducer(address indexed producerAddress, string registrationData);

    event LogAttachedTransporter(address indexed userAddress, address indexed transporterAddress);

    enum TransportState { PendingStart, Transporting, PendingEnd}

    struct Transport {
        TransportState state;

        uint index; //index of the transport in the transport array

        address from;
        address to;
        address transporter;
        address asset;
    }

    //NxM intermediate struct
    struct Transporter_User{
        address transporter;
        address user; //Producer, and later, factory

        uint indexInTransporter;
        uint indexInUser;

        //pending transport for a determinate transporter for a determinate user (producer)
        mapping(address => Transport) pendingTransports; // address = addressAsset
        Transport[] pendingTransportsList;

        //pending transport for a determinate transporter for a determinate user (producer)
        mapping(address => Transport) activeTransports; // address = addressAsset
        Transport[] activeTransportsList;        
    }

    struct Transporter{
        string registrationData; //extra data given on register

        uint index; // index on the global transporter list

        mapping(address => Transporter_User) users; //address == userAddress
        Transporter_User[] usersList;        
    }    
    mapping (address => Transporter) private  transporters;
    address[] public transportersList;

    //TODO NxM struct
    //struct Certifier_User{}

    struct Certifier{
        string registrationData; //extra data given on register
        uint index;
    }
    mapping (address => Certifier) private certifiers;
    address[] public certifiersIndex;
    
        
    struct Shop{
        string registrationData; //extra data given on register

        uint index; //index on the global shop list
        mapping(address => Transport) pendingTransports;  // address = addressAsset
        address[] pendingTransportsList;
        
        mapping(address => uint) assetsIndex; // address = addressAsset
        address[] assetsList;
    }
    mapping (address => Shop) private shops;
    address[] public shopsIndex;

    struct Producer{
        string registrationData; //extra data given on register

        uint index; //index on the global producer list

        mapping(address => uint) assetsCreatedIndex;
        address[] assetsCreatedList;

        mapping(address => Transporter_User) transporters; //address = transporterAddress
        Transporter_User[] transportersList;         
    }
    mapping (address => Producer) private producers;
    address[] public producersIndex;

    function isTransporter(address transporterAddress) public view returns(bool isIndeed) {
        if(transportersList.length == 0) return false;
        return (transportersList[transporters[transporterAddress].index] == transporterAddress);
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

/**
Always call after checking _transporterAddress is a transporter
*/
    function isTransporterOfUser(address _transporterAddress, address _userAddress) private view returns (bool isIndeed){
        return (transporters[_transporterAddress].users[_userAddress].user == _userAddress);
    }

    function isPendingTransport(address _fromAddress, address _transporterAddress, address _assetAddress) 
        private view returns (bool isIndeed)
    {
        uint transportIndex = transporters[_transporterAddress].users[_fromAddress].pendingTransports[_assetAddress].index;
        return  transporters[_transporterAddress].users[_fromAddress].pendingTransportsList[transportIndex].asset == _assetAddress;
    }

    function activateTransport(address _fromAddress, address _transporterAddress, address _assetAddress) private{
        Transport[] storage transportArray = transporters[_transporterAddress].users[_fromAddress].pendingTransportsList;
        Transport storage t = transporters[_transporterAddress].users[_fromAddress].pendingTransports[_assetAddress];
        
        //Delete from pending
        uint rowToDelete = t.index;
        Transport storage keyToMove = transportArray[transportArray.length - 1];

        transportArray[rowToDelete] = keyToMove;
        keyToMove.index = rowToDelete;
        transportArray.length --;

        //Add to active
        t.index = transporters[_transporterAddress].users[_fromAddress].pendingTransportsList.push(t) - 1;
        t.state = TransportState.Transporting;        
    }

    function deleteTransport(Transport memory t) private{
        //delete from transporter_user
        Transporter_User storage t_u = transporters[t.transporter].users[t.from];
        Transport[] storage transportArray = transporters[t.transporter].users[t.from].activeTransportsList;

        uint rowToDelete = t_u.activeTransports[t.asset].index;
        Transport storage keyToMove = transportArray[transportArray.length - 1];

        transportArray[rowToDelete] = keyToMove;
        keyToMove.index = rowToDelete;
        transportArray.length --;

        //delete from shop
        Shop storage s = shops[t.to];
        address[] storage transportArray2 = s.pendingTransportsList;

        rowToDelete = t.index;
        address keyToMove2 = transportArray2[transportArray2.length - 1];

        transportArray2[rowToDelete] = keyToMove2;
        transportArray2.length --;
    }

    function insertTransporter(address _transporterAddress, string memory _registrationData) public returns(bool success){        
        require(isTransporter(_transporterAddress) == false, "Transporter is already in the system");                
        require(isProducer(msg.sender) == true, "Only producers can insert transporters");

        Transporter storage t = transporters[_transporterAddress];
        t.registrationData = _registrationData;

        //Add to the global list        
        t.index = transportersList.push(_transporterAddress) - 1;

        //auxiliar NxM transporter_user
        Transporter_User storage t_u = t.users[msg.sender];
        t_u.transporter = _transporterAddress;
        t_u.user = msg.sender;
        t_u.indexInTransporter = t.usersList.push(t_u) - 1;
        t_u.indexInUser = producers[msg.sender].transportersList.push(t_u) - 1;
        producers[msg.sender].transporters[_transporterAddress] = t_u;

        emit LogNewTransporter(_transporterAddress, _registrationData);
        emit LogAttachedTransporter(msg.sender, _transporterAddress);
        return true;
    }
/* 
TODO refactor this and add attachCertifier();
    function insertCertifier(address CertifierAddress, string memory _data) public onlyOwner returns(uint index){
        require(isCertifier(CertifierAddress) == false, "Certifier is already in the system");

        certifiers[CertifierAddress].index = certifiersIndex.push(CertifierAddress)-1;
        emit LogNewCertifier(CertifierAddress, _data);
        return certifiersIndex.length-1;
    }
*/
    function insertShop(address ShopAddress, string memory _data) public onlyOwner returns(uint index){
        require(isShop(ShopAddress) == false, "Shop is already in the system");

        shops[ShopAddress].registrationData = _data;
        shops[ShopAddress].index = shopsIndex.push(ShopAddress)-1;
        emit LogNewShop(ShopAddress, _data);
        return shopsIndex.length-1;
    }

    function insertProducer(address ProducerAddress, string memory _data) public onlyOwner returns(uint index){
        require(isProducer(ProducerAddress) == false, "Producer is already in the system");

        producers[ProducerAddress].registrationData = _data;
        producers[ProducerAddress].index = producersIndex.push(ProducerAddress)-1;
        emit LogNewProducer(ProducerAddress, _data);
        return producersIndex.length-1;
    }

    function attachTransporterToProducer(address _transporterAddress) public returns(bool success){
        require(isTransporter(_transporterAddress), " transporterAddress is not a transporter");
        require(isProducer(msg.sender), "Only producers can attach transporterOfProducer");   
        require(
            isTransporterOfUser(_transporterAddress, msg.sender) == false, 
            "producer already attached to transporter"
        );


        //Create new NxM aux and push to both places
        Transporter storage t = transporters[_transporterAddress];
        
        //TODO refactor in a function to avoid duplicate code
        Transporter_User storage t_u = t.users[msg.sender];
        t_u.transporter = _transporterAddress;
        t_u.user = msg.sender;
        t_u.indexInTransporter = t.usersList.push(t_u) - 1;
        t_u.indexInUser = producers[msg.sender].transportersList.push(t_u) - 1;
        producers[msg.sender].transporters[_transporterAddress] = t_u;

        return true;
    }

    function createAsset(string memory _JSON) public returns (address asset){
        require(isProducer(msg.sender), "Only producers can create assets");

        asset = address(new Asset(msg.sender, _JSON));
        
        //add the asset to the mapping and indexList
        producers[msg.sender].assetsCreatedIndex[asset] = producers[msg.sender].assetsCreatedList.push(asset) - 1;
                
        return asset;
    }

    function requestTransportStart(address _assetAddress, address _transporterAddress, address _receiverAddress) 
        public 
        returns (bool success)
    {        
        require(isTransporter(_transporterAddress), "only transporters can transport");
        require(isShop(_receiverAddress), "only shops can receive a transport");        
        require(
            isTransporterOfUser(_transporterAddress, msg.sender) == false, 
            "transporter is not partner of message sender"
        );        

        //check for asset ownership       
        require(
            Asset(_assetAddress).owner() == msg.sender, 
            "Only owner of the asset can request a transport"
        );        

        //Add to transport list of NxM transport_user aux entity
        Transport storage t = transporters[_transporterAddress].users[msg.sender].pendingTransports[_assetAddress];
        t.state = TransportState.PendingStart;

        t.from = msg.sender;
        t.to = _receiverAddress;
        t.transporter = _transporterAddress;
        t.asset = _assetAddress;

        t.index = transporters[_transporterAddress].users[msg.sender].pendingTransportsList.push(t) - 1;
        
        //Change asset status and add a transaction of type (TransportStartRequest)
        Asset(_assetAddress).askForTransport(msg.sender, _transporterAddress);

        return true;
    }

    function startTransport(address _assetAddress) public returns (bool success){     
        //TODO quiza añadir una estructura asset que simplemente deje saber a este contrato la lista
        //de assets que se han creado
        require(isTransporter(msg.sender), "Only transporters can start transports");
        
        (address _from, address _transporter) = Asset(_assetAddress).getTransportData();
        require (_transporter == msg.sender, "Asset is pending transport from another transporter");
        assert (isPendingTransport(_from, _transporter, _assetAddress)); //This should always be true        
        
        //Delete transport from pending transports and add to activeTransports        
        activateTransport(_from, _transporter, _assetAddress);
        
        //Notify the assets contract (change state and add transaction)       
        Asset(_assetAddress).newTransport(_from, msg.sender);

        return true;
    }

    //faltan parametros obviamente al menos el asset que se transporta
    function requestTransportEnd(address _assetAddress) public returns (bool success){
        require(isTransporter(msg.sender), "Only the transporter can request transport end"); 
        
        (address _from, address _transporter) = Asset(_assetAddress).getTransportData();
        require(msg.sender == _transporter, "Requester is not the valid transporter");

        //Conseguir el transporte
        Transport storage transport = transporters[msg.sender].
            users[_from].
            activeTransports[_assetAddress];           

        //TODO pedir al asset el cambio de estado 
        Asset(_assetAddress).askForTransportEnd(_transporter, transport.to);

        //Añadir a la lista de transportes pendientes de la tienda
        Transport memory t2 = transport;
        shops[transport.to].pendingTransports[_assetAddress] = t2;
        shops[transport.to].pendingTransports[_assetAddress].index = shops[transport.to].pendingTransportsList.push(t2.asset) - 1;        
        return true;
    }

    function endTransport(address _assetAddress) public returns (bool success){      
        require(isShop(msg.sender), "Only shop can receive Asset");
        //TODO añadir mas comprobaciones de seguridad
        
        //Conseguir el transporte
        Transport storage transport = shops[msg.sender].pendingTransports[_assetAddress];
        
        //add transaction to the asset history
        Asset(_assetAddress).endTransport(transport.transporter, transport.to);   

        
        // delete transport from transporter and shop
        deleteTransport(transport);
        
        // add asset to shop
        shops[msg.sender].assetsIndex[_assetAddress] = shops[msg.sender].assetsList.push(_assetAddress) - 1;        
        
        return true;
    }

}

