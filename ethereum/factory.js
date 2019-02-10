import web3 from './web3';
import CampaignFactory from './build/CampaignFactory.json';

const instance = new web3.eth.Contract(
JSON.parse(CampaignFactory.interface),
'0x69EBaBBd212F0c8ec317944C9648C1198e73d126'
);

export default instance;