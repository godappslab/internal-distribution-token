const fs = require('fs');
const InternalDistributionToken = artifacts.require('InternalDistributionToken');

const name = 'PointToken';
const symbol = 'pt';
const decimals = 0;
const totalSupply = 1000000000;

module.exports = (deployer) => {
    deployer.deploy(InternalDistributionToken, name, symbol, decimals, totalSupply).then(() => {
        // Save ABI to file
        fs.mkdirSync('deploy/abi/', { recursive: true });
        fs.writeFileSync('deploy/abi/InternalDistributionToken.json', JSON.stringify(InternalDistributionToken.abi), { flag: 'w' });
    });
};
