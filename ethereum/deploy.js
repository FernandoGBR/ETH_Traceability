const HDWalletProvider = require('truffle-hdwallet-provider');
const Web3 = require('web3');
//const { interface, bytecode }  = require('./compile');
const compiledFactory = require ('./build/CampaignFactory.json');
const provider =  new HDWalletProvider(
    'license dog casual deputy sugar island leave crunch business private fish topple','https://rinkeby.infura.io/v3/e1187cd614a9410cb15eb85bee1bede4'
);

const web3 = new Web3(provider);


const deploy = async () => {
    const accounts = await web3.eth.getAccounts();
    console.log('Attempting to deploy from account', accounts[0]);

    const result = await new web3.eth.Contract(JSON.parse(compiledFactory.interface))
    .deploy({ data: compiledFactory.bytecode })
    //    .deploy({ data: '0x' + compiledFactory.bytecode }) // add bytecode
    .send({gas:'1000000', from: accounts[0] });

    console.log('Contract deployed to', result.options.address);
    console.log(compiledFactory.interface);
};
deploy();