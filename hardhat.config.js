require("@nomiclabs/hardhat-ethers");
require("dotenv").config();
const path = require("path");

module.exports = {
  solidity: {
    compilers: [
      {
        // 直接引用本地 soljson.js 路径
        version: "solc/soljson.js",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
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
