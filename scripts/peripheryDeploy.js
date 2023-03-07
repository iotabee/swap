// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
const web3 = require("web3");

async function main() {
    const IotaBeeSwapRouter = await hre.ethers.getContractFactory("IotaBeeSwapRouter");
    const ibsr = await IotaBeeSwapRouter.deploy("","");
    await ibsr.deployed();
    console.log(`Deployed IotaBeeSwapRouter to ${ibsr.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
