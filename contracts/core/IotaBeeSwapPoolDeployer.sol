//SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.17;
import "./IotaBeeSwapPool.sol";
import "./interfaces/IIotaBeeSwapPoolDeployer.sol";

contract IotaBeeSwapPoolDeployer is IIotaBeeSwapPoolDeployer {
    struct Parameters {
        address factory;
        address token0;
        address token1;
        uint24 feeRate;
    }

    Parameters public parameters;

    /// @dev Deploys a pool with the given parameters by transiently setting the parameters storage slot and then
    /// clearing it after deploying the pool.
    /// @param factory The contract address of the IotaBeeSwap factory
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param feeRate The fee collected upon every swap in the pool, multiple 100000 for percentages
    function deploy(
        address factory,
        address token0,
        address token1,
        uint24 feeRate
    ) internal returns (address pool) {
        parameters = Parameters({
            factory: factory,
            token0: token0,
            token1: token1,
            feeRate: feeRate
        });
        pool = address(
            new IotaBeeSwapPool{
                salt: keccak256(abi.encode(token0, token1, feeRate))
            }()
        );
        delete parameters;
    }
}
