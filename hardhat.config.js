require("@nomiclabs/hardhat-ethers");
require("dotenv").config();
const { subtask } = require("hardhat/config");
const { TASK_COMPILE_SOLIDITY_GET_SOLC_BUILD } = require("hardhat/builtin-tasks/task-names");
const path = require("path");

// 覆盖默认下载任务，直接指向本地 soljson.js
subtask(TASK_COMPILE_SOLIDITY_GET_SOLC_BUILD, async (args, hre, runSuper) => {
  if (args.solcVersion === "0.8.20") {
    const compilerPath = path.join(__dirname, "node_modules/solc/soljson.js");
    return {
      compilerPath,
      isSolcJs: true,
      version: args.solcVersion,
      longVersion: "0.8.20+commit"
    };
  }
  return runSuper();
});

module.exports = {
  solidity: "0.8.20",
  networks: {
    hyperevm: {
      url: process.env.HYPEEVM_RPC,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
    }
  }
};
