//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.9;

interface IIotaBeeSwapCallee {
    function iotabeeSwapCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}
