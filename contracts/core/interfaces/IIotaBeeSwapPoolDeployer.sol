//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IIotaBeeSwapPoolDeployer {
    function parameters()
        external
        view
        returns (
            address factory,
            address token0,
            address token1,
            uint24 fee
        );
}
