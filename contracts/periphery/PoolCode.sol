//SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.17;

import "../core/IotaBeeSwapPool.sol";
import "./libraries/IotaBeeSwapLibrary.sol";

contract PoolCode {
    constructor() {
    }

    function GetPoolCode() public pure returns(bytes32){
        return keccak256(abi.encodePacked(type(IotaBeeSwapPool).creationCode));
    }

    function GetPoolAddress(address factory, address tokenA, address tokenB, uint24 feeRate) public pure returns(address){
        return IotaBeeSwapLibrary.poolFor(
            factory,
            tokenA,
            tokenB,
            feeRate
        );
    }
}