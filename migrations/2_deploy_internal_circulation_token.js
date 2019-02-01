const InternalCirculationToken = artifacts.require('./InternalCirculationToken.sol');

const name = 'TestToken';
const symbol = 'tt';
const decimals = 0;
const totalSupply = 1000000000;

module.exports = (deployer) => {
    deployer.deploy(InternalCirculationToken, name, symbol, decimals, totalSupply);
};
