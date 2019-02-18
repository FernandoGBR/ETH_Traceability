import web3 from './web3';
import TraceabilityContract from './build/TraceabilityContract.json';


/*const instance = new web3.eth.Contract(
    JSON.parse(TraceabilityContract.interface)
);*/

const instance = new web3.eth.Contract(
    TraceabilityContract.abi
);

export default instance;