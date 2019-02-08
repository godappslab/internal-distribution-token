const fs = require('fs');
const InternalCirculationToken = artifacts.require('InternalCirculationToken');

const name = 'TestToken';
const symbol = 'tt';
const decimals = 0;
const totalSupply = 1000000000;

module.exports = (deployer) => {
    deployer.deploy(InternalCirculationToken, name, symbol, decimals, totalSupply).then(() => {
        // Save ABI to file
        fs.mkdirSync('deploy/abi/', { recursive: true });
        fs.writeFileSync('deploy/abi/InternalCirculationToken.json', JSON.stringify(InternalCirculationToken.abi), { flag: 'w' });
    });
};
