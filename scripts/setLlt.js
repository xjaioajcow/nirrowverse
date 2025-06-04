const { ethers } = require("hardhat");
require("dotenv").config();

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Using deployer:", await deployer.getAddress());

  const redeemerAddress = process.env.REDEEMER;
  const newLlt = process.env.LLT;

  if (!redeemerAddress || redeemerAddress === "0x0000000000000000000000000000000000000000") {
    console.error("Please set REDEEMER in environment variables");
    process.exit(1);
  }
  if (!newLlt || newLlt === "0x0000000000000000000000000000000000000000") {
    console.error("Please set LLT in environment variables");
    process.exit(1);
  }

  const Redeemer = await ethers.getContractFactory("Redeemer");
  const redeemer = Redeemer.attach(redeemerAddress);
  const tx = await redeemer.setLlt(newLlt);
  console.log("setLlt tx hash:", tx.hash);
  await tx.wait();
  console.log("Redeemer LLT updated to:", newLlt);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
