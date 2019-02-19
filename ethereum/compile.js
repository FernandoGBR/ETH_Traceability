const path =  require('path');
const solc =  require('solc');
const fs =  require('fs-extra');

const buildPath = path.resolve(__dirname,'build');
fs.removeSync(buildPath);
fs.ensureDirSync(buildPath);

compileFromFile('owned.sol');
compileFromFile('asset.sol');
compileFromFile('shops.sol');
compileFromFile('transporters_users.sol'); 
compileFromFile('transporters.sol');
compileFromFile('producers.sol');
compileFromFile('traceabilityContract.sol'); 

function compileFromFile(fileName) {
	const contractPath = path.resolve(__dirname,'contracts', fileName);

	const source = fs.readFileSync(contractPath,'utf8');

	var input = {
		language: 'Solidity',
		sources: {
			[fileName]: {
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

	var output = JSON.parse(solc.compile(JSON.stringify(input), findImports));

	//console.log(output.contracts);
	
	for (let contract in output.contracts[fileName]) {
		fs.outputJSONSync(
			path.resolve(buildPath,contract.replace(':', '') + '.json'),
			output.contracts[fileName][contract]
		);
	}
}

function findImports(pathToImport){	
	const importPath = path.resolve(__dirname,'contracts', pathToImport);
	return {contents: fs.readFileSync(importPath,'utf8')};		 
}