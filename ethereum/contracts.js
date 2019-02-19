import web3 from './web3';

import AssetJSON from './build/Asset.json';
import ProducersJSON from './build/Producers.json';
import ShopsJSON from './build/Shops.json';
import TraceabilityContractJSON from './build/TraceabilityContract.json';
import Transporters_UsersJSON from './build/Transporters_Users.json';
import TransportersJSON from './build/Transporters.json';

const Asset = new web3.eth.Contract(AssetJSON.abi);
const Producers = new web3.eth.Contract(ProducersJSON.abi);
const Shops = new web3.eth.Contract(ShopsJSON.abi);
const TraceabilityContract = new web3.eth.Contract(TraceabilityContractJSON.abi);
const Transporters_Users = new web3.eth.Contract(Transporters_UsersJSON.abi);
const Transporters = new web3.eth.Contract(TransportersJSON.abi);

export {
    Asset,
    Producers,
    Shops,
    TraceabilityContract,
    Transporters_Users,
    Transporters
}
