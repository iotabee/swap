// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
    const TestErc20 = await hre.ethers.getContractFactory("TestErc20");
    const tt1 = await TestErc20.deploy("Test Token 1","TT1",6);
    await tt1.deployed();
    console.log(`Deployed TT1 to ${tt1.address}`);

    const tt2 = await TestErc20.deploy("Test Token 2","TT2",6);
    await tt2.deployed();
    console.log(`Deployed TT2 to ${tt2.address}`);

    const tt3 = await TestErc20.deploy("Test Token 3","TT3",18);
    await tt3.deployed();
    console.log(`Deployed TT3 to ${tt3.address}`);

    const tt4 = await TestErc20.deploy("Test Token 4","TT4",18);
    await tt4.deployed();
    console.log(`Deployed TT4 to ${tt4.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
