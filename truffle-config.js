const HDWalletProvider = require('truffle-hdwallet-provider');

const infuraConfig = require('./private_file/infura-config.js');
/*
module.exports = {
    ropsten: {
        infuraKey: 'xxxxxx_infula.io's "PROJECT ID"_xxxxxx',
        privateKey: 'xxxxxx_your_eth_address_private_key_xxxxxx',
    },
};
 */

module.exports = {
    networks: {
        ropsten: {
            provider: () => new HDWalletProvider(infuraConfig.ropsten.privateKey, `https://ropsten.infura.io/v3/${infuraConfig.ropsten.infuraKey}`),
            network_id: 3,
            gas: 5500000,
            confirmations: 2,
            timeoutBlocks: 200,
            skipDryRun: true,
        },

        private: {
            host: '127.0.0.1',
            port: 8545,
            network_id: 1547092157,
            from: '0x083Cd205ee174D0d0D259c0225be4218EAdcE556', // truffle develop
            gas: 5651873,
        },
    },

    mocha: {},

    compilers: {
        solc: {
            version: '0.4.24',
        },
    },
};
