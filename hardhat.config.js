require("@nomiclabs/hardhat-ethers");
require("dotenv").config();

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        },
        // 本地 solc-js 路径
        url: "node_modules/solc/soljson.js"
      }
    ]
  },
  networks: {
    hyperevm: {
      url: process.env.HYPEEVM_RPC,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
    }
  }
};
