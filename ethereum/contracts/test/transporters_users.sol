pragma solidity ^0.5.0;

contract Transporters_Users{
    address traceabilityContract;
    

    enum TransportState { PendingStart, Transporting, PendingEnd}

    struct Transport {
        TransportState state;

        uint index; //index of the transport in the transport array

        address from;
        address to;
        address transporter;
        address asset;
    }

    struct Transporter_User{
        address transporter;
        address user; //Producer, and later, factory

        uint indexInTransporter;
        uint indexInUser;

        //pending transport for a determinate transporter for a determinate user (producer)
        mapping(address => Transport) pendingTransports; // address = addressAsset
        address[] pendingTransportsList;

        //active transport for a determinate transporter for a determinate user (producer)
        mapping(address => Transport) activeTransports; // address = addressAsset
        address[] activeTransportsList;        
    }

    mapping (address => mapping (address => Transporter_User)) tuMatrix; //transporter => user => T_U
    mapping (address => address[]) usersOfTransporters; //transporter => user[]
    mapping (address => address[]) transportersOfUsers; //user => transporter[]

    constructor (address _tc) public{
        traceabilityContract = _tc;
    } 

    function insertTU(address _transporterAddress, address _userAddress) public returns (bool success){
        require(!isTransporterOfUser(_transporterAddress, _userAddress), "Association already exists"); 

        Transporter_User storage tu = tuMatrix[_transporterAddress][_userAddress];
        tu.transporter = _transporterAddress;
        tu.user = _userAddress;
        tu.indexInTransporter = usersOfTransporters[_transporterAddress].push(_userAddress);
        tu.indexInUser = usersOfTransporters[_userAddress].push(_transporterAddress);

        return true;
    }

    function isTransporterOfUser(address _transporterAddress, address _userAddress) public view returns (bool isIndeed){
        return tuMatrix[_transporterAddress][_userAddress].transporter != address(0);
    }

    function isPendingTransport(address _userAddress, address _transporterAddress, address _assetAddress) 
        public view returns (bool isIndeed)
    {
        Transporter_User storage tu = tuMatrix[_transporterAddress][_userAddress];
        return (_assetAddress == tu.pendingTransportsList[tu.pendingTransports[_assetAddress].index]);
    }

    function requestTransportStart(address _userAddress, address _assetAddress, address _transporterAddress, address _receiverAddress) 
        public 
        returns (bool success)
    {   
        require(msg.sender == traceabilityContract, "only TC can do this call");
        require(
            isTransporterOfUser(_transporterAddress, msg.sender) == true, 
            "transporter is not partner of message sender"
        );      

        //Add to transport list of NxM transport_user aux entity
        Transporter_User storage tu = tuMatrix[_transporterAddress][_userAddress];                
        Transport storage t = tu.pendingTransports[_assetAddress];

        t.state = TransportState.PendingStart;
        t.from = _userAddress;
        t.to = _receiverAddress;
        t.transporter = _transporterAddress;
        t.asset = _assetAddress;
        t.index = tu.pendingTransportsList.push(_assetAddress) - 1;

        return true;
    }

    function activateTransport(address _userAddress, address _transporterAddress, address _assetAddress) public{
        require(msg.sender == traceabilityContract, "only TC can do this call");

        address[] storage pendingTransportArray = tuMatrix[_transporterAddress][_userAddress].pendingTransportsList;
        Transport storage t = tuMatrix[_transporterAddress][_userAddress].pendingTransports[_assetAddress];
        
        //Delete from pending
        uint rowToDelete = t.index;
        address keyToMove = pendingTransportArray[pendingTransportArray.length - 1];

        pendingTransportArray[rowToDelete] = keyToMove;
        tuMatrix[_transporterAddress][_userAddress].pendingTransports[keyToMove].index = rowToDelete;
        pendingTransportArray.length --;

        //Add to active
        t.index = tuMatrix[_transporterAddress][_userAddress].activeTransportsList.push(_assetAddress) - 1;
        t.state = TransportState.Transporting;
    }

    function getTransportReceiver(address _userAddress, address _transporterAddress, address _assetAddress) public view returns (address to){
        return tuMatrix[_transporterAddress][_userAddress].activeTransports[_assetAddress].to;
    }

    function deleteTransport(address _userAddress, address _transporterAddress, address _assetAddress) public{
        require(msg.sender == traceabilityContract, "only TC can do this call");

        address[] storage activeTransportArray = tuMatrix[_transporterAddress][_userAddress].activeTransportsList;
        Transport storage t = tuMatrix[_transporterAddress][_userAddress].activeTransports[_assetAddress];
        //Delete from active
        uint rowToDelete = t.index;
        address keyToMove = activeTransportArray[activeTransportArray.length - 1];

        activeTransportArray[rowToDelete] = keyToMove;
        tuMatrix[_transporterAddress][_userAddress].activeTransports[keyToMove].index = rowToDelete;
        activeTransportArray.length --;
    }
}