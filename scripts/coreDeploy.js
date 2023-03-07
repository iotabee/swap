// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
const web3 = require("web3");

async function main() {
  const IotaBeeSwapFactory = await hre.ethers.getContractFactory("IotaBeeSwapFactory");
  const ibsf = await IotaBeeSwapFactory.deploy();

  const WSMR = await hre.ethers.getContractFactory("WSMR");
  const wsmr = await WSMR.deploy();

  await ibsf.deployed();
  await wsmr.deployed();

  console.log(`Deployed IotaBeeSwapFactory to ${ibsf.address}`);
  console.log(`Deployed WSMR to ${wsmr.address}`);

  //hre.ethers.Contract(ibsf.address, )

  // const IotaBeeSwapRouter = await hre.ethers.getContractFactory("IotaBeeSwapRouter");
// const ibsr = await IotaBeeSwapRouter.deploy(ibsf.address,wsmr.address);
// await ibsr.deployed();

//  console.log(`Deployed IotaBeeSwapRouter to ${ibsr.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
