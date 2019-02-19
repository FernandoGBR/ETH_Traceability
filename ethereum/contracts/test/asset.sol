pragma solidity ^0.5.0;

contract Asset { //is owned?

    enum AssetState {Waiting, PendingTransport, InTransport, PendingReceipt, Consumed}
    enum TransactionType {Creation, TransportStartRequest, TransportStart, TransportEndRequest, TransportEnd, Consume}
    struct transaction {
        TransactionType transactionType;
        address address1;
        address address2;
        string description;
        uint date;
    }
    AssetState public assetState;
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
        _t.address2 = _to;
        _t.date = now;
        transactions.push(_t);
    }

    function newTransport() public {
        assetState = AssetState.InTransport;
        transaction memory _t = transactions[transactions.length - 1]; //copy the last transaction
        owner = _t.address2;        
        _t.transactionType = TransactionType.TransportStart;
        _t.date = now;
        transactions.push(_t);        
    }

    function askForTransportEnd(address _from, address _to) public{
        require(_from == owner, "only owner of the asset can ask for end Transport");        
        assetState = AssetState.PendingReceipt;
        transaction memory _t;
        _t.transactionType = TransactionType.TransportEndRequest;
        _t.address1 = _from;
        _t.address2 = _to;
        _t.date = now;
        transactions.push(_t);
    }

    function endTransport() public {
        assetState = AssetState.Waiting;
        transaction memory _t = transactions[transactions.length - 1]; //copy the last transaction
        owner = _t.address2;        
        _t.transactionType = TransactionType.TransportEnd;        
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
}