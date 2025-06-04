const { ethers } = require("hardhat");
require("dotenv").config();

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", await deployer.getAddress());

  // 1. Deploy LOTTO
  const Lotto = await ethers.getContractFactory("LOTTO");
  const lotto = await Lotto.deploy();
  await lotto.deployed();
  console.log("LOTTO deployed to:", lotto.address);

  // 2. Deploy StakeVault
  const StakeVault = await ethers.getContractFactory("StakeVault");
  const stakeVault = await StakeVault.deploy(lotto.address);
  await stakeVault.deployed();
  console.log("StakeVault deployed to:", stakeVault.address);

  // 3. Deploy RUMWL
  const RumWL = await ethers.getContractFactory("RUMWL");
  const rumWL = await RumWL.deploy();
  await rumWL.deployed();
  console.log("RUMWL deployed to:", rumWL.address);

  // 4. Deploy HourlyDraw
  const HourlyDraw = await ethers.getContractFactory("HourlyDraw");
  const hourlyDraw = await HourlyDraw.deploy(
    stakeVault.address,
    "0x0000000000000000000000000000000000000000",
    rumWL.address,
    process.env.ROUTER,
    "0x0000000000000000000000000000000000000000"
  );
  await hourlyDraw.deployed();
  console.log("HourlyDraw deployed to:", hourlyDraw.address);

  // 5. Deploy Redeemer with LLT placeholder
  const Redeemer = await ethers.getContractFactory("Redeemer");
  const redeemer = await Redeemer.deploy(
    "0x0000000000000000000000000000000000000000",
    lotto.address,
    process.env.ROUTER,
    stakeVault.address,
    hourlyDraw.address,
    ethers.utils.parseUnits("1", 18)
  );
  await redeemer.deployed();
  console.log("Redeemer deployed to:", redeemer.address);

  console.log("All contracts deployed. Please record the addresses:");
  console.log("LOTTO:", lotto.address);
  console.log("StakeVault:", stakeVault.address);
  console.log("RUMWL:", rumWL.address);
  console.log("HourlyDraw:", hourlyDraw.address);
  console.log("Redeemer:", redeemer.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
