// babel presets allow us to export/import
// functions from different js files
// e.g. export tokens fnc in test/helpers
require('babel-register');
require('babel-polyfill');
require('dotenv').config();
// access .env through 'process', which holds reference because we required file
const privateKeys = process.env.PRIVATE_KEYS || '';
const HDWalletProvider = require('truffle-hdwallet-provider-privkey');

module.exports = {
  /**
   * Networks define how you connect to your ethereum client and let you set the
   * defaults web3 uses to send transactions. If you don't specify one truffle
   * will spin up a development blockchain for you on port 9545 when you
   * run `develop` or `test`. You can ask a truffle command to use a specific
   * network from the command line, e.g
   *
   * $ truffle test --network <network-name>
   */

  // connect to ganashe in dev env
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*" // match any network id
    },
    kovan: {
      provider: function() {
        return new HDWalletProvider(
          // private key, to know what account to connect to
          privateKeys.split(','), // array of account private keys
          // URL to eth node
          `https://kovan.infura.io/${process.env.INFURA_API_KEY}`
        )
      },
      gas: 5000000,
      gasPrice: 25000000000,
      network_id: 42 // id for Kovan network
    }
  },
  contracts_directory: './src/contracts/',
  contracts_build_directory: './src/abis/',

  // Set default mocha options here, use special reporters etc.

  // Configure your compilers
  compilers: {
    solc: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  }
}
