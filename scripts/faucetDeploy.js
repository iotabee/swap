// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
    const TestErc20 = await hre.ethers.getContractFactory("TestErc20");
    const tt4 = await TestErc20.deploy("Test Token 4", "TT4", 18);
    await tt4.deployed();
    console.log(`Deployed TT4 to ${tt4.address}`);

    const FaucetERC20 = await hre.ethers.getContractFactory("FaucetERC20");
    const faucet = await FaucetERC20.deploy();
    await faucet.deployed();
    console.log(`Deployed FaucetERC20 to ${faucet.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
