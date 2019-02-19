pragma solidity ^0.5.0;

import "./owned.sol";
import "./asset.sol";
import "./producers.sol";
import "./transporters.sol";
import "./shops.sol";

import "./transporters_users.sol";


contract TraceabilityContract is owned {

    event LogNewTransporter(address transporterAddress, string registrationData);
    event LogNewCertifier(address certifierAddress, string registrationData);
    event LogNewShop(address shopAddress, string registrationData);
    event LogNewProducer(address producerAddress, string registrationData);
    event LogNewAsset(address indexed producerAddress, address assetAddress);

    event LogAttachedTransporter(address indexed userAddress, address indexed transporterAddress);

    Transporters_Users tuContract;
    Producers producersContract;  
    Transporters transportersContract;
    Shops shopsContract;
    
    constructor () public {
        tuContract = new Transporters_Users(address(this));
        producersContract = new Producers(address(this));                        
        transportersContract = new Transporters(address(this));
        shopsContract = new Shops(address(this));
    }

    /* Pertenencia a roles*/

    function isTransporter(address _transporterAddress) public view returns(bool isIndeed) {
        return transportersContract.isTransporter(_transporterAddress);
    }

    function isShop(address _shopAddress) public view returns(bool isIndeed) {
        return shopsContract.isShop(_shopAddress);
    } 
    
    function isProducer(address _producerAddress) public view returns(bool isIndeed) {                
        return producersContract.isProducer(_producerAddress);
    } 

    /* inserción de participantes */ 
    //TODO quitar los returns??
    function insertShop(address _shopAddress, string memory _data) public onlyOwner returns(uint index){
        index = shopsContract.insertShop(_shopAddress, _data);
        emit LogNewShop(_shopAddress, _data);             
    }

    function insertProducer(address ProducerAddress, string memory _data) public onlyOwner returns(uint index){
        index = producersContract.insertProducer(ProducerAddress, _data);
        emit LogNewProducer(ProducerAddress, _data);        
    }

    function insertTransporter(address _transporterAddress, string memory _registrationData) 
        public onlyOwner returns(bool success)
    {       
        success = transportersContract.insertTransporter(_transporterAddress, _registrationData);
        emit LogNewTransporter(_transporterAddress, _registrationData);                
    }


    /* NxM relations */

    function userAttachTransporter(address _transporterAddress) public returns(bool success){
        require(isTransporter(_transporterAddress), " transporterAddress is not a transporter");
        require(
            isProducer(msg.sender) || false, //TODO añadir todos los posibles tipos de user
            "Sender is not a valid transporter user"
        ); 

        success = tuContract.insertTU(_transporterAddress, msg.sender);
        emit LogAttachedTransporter(msg.sender, _transporterAddress);
    }
    

    /* Checks */

    function isTransporterOfUser(address _transporterAddress, address _userAddress) private view returns (bool isIndeed){
        assert(isTransporter(_transporterAddress));
        return tuContract.isTransporterOfUser(_transporterAddress, _userAddress);
    }

    function isPendingTransport(address _userAddress, address _transporterAddress, address _assetAddress) 
        private view returns (bool isIndeed)
    {        
        assert(isTransporter(_transporterAddress));
        return tuContract.isPendingTransport(_userAddress, _transporterAddress, _assetAddress);
    }


    /* Operations */

    function createAsset(string memory _JSON) public returns (address assetAddress){       
        assetAddress = producersContract.createAsset(msg.sender, _JSON);
        emit LogNewAsset(msg.sender, assetAddress);        
    }

    function requestTransportStart(address _assetAddress, address _transporterAddress, address _receiverAddress) 
        public 
        returns (bool success)
    {   
        require(Asset(_assetAddress).owner() == msg.sender, "Only owner of the asset can request a transport");           
        require(isTransporter(_transporterAddress), "only transporters can transport");
        require(
            isShop(_receiverAddress), //TODO Añadir diferentes tipos de users
            "only shops can receive a transport"
        );        
        
        tuContract.requestTransportStart(msg.sender, _assetAddress, _transporterAddress, _receiverAddress);
        
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
        assert (isPendingTransport(_from, _transporter, _assetAddress));        
        
        //Delete transport from pending transports and add to activeTransports        
        tuContract.activateTransport(_from, _transporter, _assetAddress);
        
        //Notify the assets contract (change state and add transaction)       
        Asset(_assetAddress).newTransport();
        return true;
    }

    function requestTransportEnd(address _assetAddress) public returns (bool success){
        require(isTransporter(msg.sender), "Only a transporter can request transport end"); 
        
        (address _from, address _transporter) = Asset(_assetAddress).getTransportData();
        require(msg.sender == _transporter, "Requester is not the valid transporter");
          
        //conseguir datos del transport  
        address _to = tuContract.getTransportReceiver(_from, _transporter, _assetAddress);

        //pedir al asset el cambio de estado 
        Asset(_assetAddress).askForTransportEnd(_transporter, _to);

        //Añadir a la lista de transportes pendientes de la tienda
        shopsContract.addPendingAsset(_to, _assetAddress);
                
        return true;
    }

    function endTransport(address _assetAddress) public returns (bool success){      
        require(
            isShop(msg.sender), //TODO Add the rest of possible receivers i.e. factory, warehouse
            "Only shop can receive Asset"
        );
        //TODO añadir mas comprobaciones de seguridad
        
        //add transaction to the asset history
        Asset(_assetAddress).endTransport();
        
        (address _from, address _transporter) = Asset(_assetAddress).getTransportData();
        // delete transport from transporter
        tuContract.deleteTransport(_from, _transporter, _assetAddress);
        
        
        // add asset to shop
        shopsContract.receiveAsset(msg.sender, _assetAddress);
        return true;
    }

     /*function deleteTransport(Transport memory t) private{
        //delete from transporter_user <--- esto a tuContarct
        Transporter_User storage t_u = transporters[t.transporter].users[t.from];
        Transport[] storage transportArray = transporters[t.transporter].users[t.from].activeTransportsList;

        uint rowToDelete = t_u.activeTransports[t.asset].index;
        Transport storage keyToMove = transportArray[transportArray.length - 1];

        transportArray[rowToDelete] = keyToMove;
        keyToMove.index = rowToDelete;
        transportArray.length --;

        //delete from shop <--- esto a shopContract
        Shop storage s = shops[t.to];
        address[] storage transportArray2 = s.pendingTransportsList;

        rowToDelete = t.index;
        address keyToMove2 = transportArray2[transportArray2.length - 1];

        transportArray2[rowToDelete] = keyToMove2;
        transportArray2.length --;
    }*/

}

