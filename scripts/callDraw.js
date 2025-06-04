const { ethers } = require("hardhat");
require("dotenv").config();

async function main() {
  const provider = new ethers.providers.JsonRpcProvider(process.env.HYPEEVM_RPC);
  const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
  const hourlyDrawAddress = process.env.HOURLYDRAW;

  if (!hourlyDrawAddress || hourlyDrawAddress === "0x0000000000000000000000000000000000000000") {
    console.error("Please set HOURLYDRAW in environment variables");
    process.exit(1);
  }

  const abi = ["function draw() external"];
  const hourly = new ethers.Contract(hourlyDrawAddress, abi, wallet);

  const tx = await hourly.draw();
  console.log("Called draw(), tx hash:", tx.hash);
  await tx.wait();
  console.log("Draw executed at timestamp:", Math.floor(Date.now() / 1000));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
