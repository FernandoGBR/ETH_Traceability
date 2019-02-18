const path =  require('path');
const solc =  require('solc');
const fs =  require('fs-extra');

const buildPath = path.resolve(__dirname,'build');
fs.removeSync(buildPath);

const contractPath = path.resolve(__dirname,'contracts', 'traceabilityContract.sol');

const source = fs.readFileSync(contractPath,'utf8');

var input = {
	language: 'Solidity',
	sources: {
		'traceabilityContract.sol': {
			content: source
		}
	},
	settings: {
		outputSelection: {
			'*': {
				'*': [ '*' ]
			}
		}
	}
}


var output = JSON.parse(solc.compile(JSON.stringify(input)));
//const output = solc.compile(source, 1).contracts;

fs.ensureDirSync(buildPath);

/*for ( let contract in output) {
    fs.outputJSONSync(
        path.resolve(buildPath,contract.replace(':', '') + '.json'),
        output[contract]
    );
}*/

for (let contract in output.contracts['traceabilityContract.sol']) {
    fs.outputJSONSync(
        path.resolve(buildPath,contract.replace(':', '') + '.json'),
        output.contracts['traceabilityContract.sol'][contract]
    );
}



