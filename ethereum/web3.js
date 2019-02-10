import Web3 from 'web3';

//const web3 = new Web3(window.web3.currentProvider);


let web3;

if(typeof window !== 'undefined' && window.web3 !== 'undefined'){
    //we are in the browser and metamask is runing 
    web3 = new Web3(window.web3.currentProvider);
}else{
    //we are on the server or the user is not runing metamask
    const provider = new Web3.providers.HttpProvider(
        'https://rinkeby.infura.io/v3/e1187cd614a9410cb15eb85bee1bede4'
        
    );
    web3 = new Web3(provider);
}
export default web3;
