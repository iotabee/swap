//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IIotaBeeSwapFactory {
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed feeRate,
        address pool
    );

    function feeTo() external view returns (address);

    function owner() external view returns (address);

    function feeRateAmount(uint24 feeRate) external view returns (int24);

    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    function allPools(uint256) external view returns (address pool);

    function allPoolsLength() external view returns (uint256);

    function createPool(
        address tokenA,
        address tokenB,
        uint24 feeRate
    ) external returns (address pool);

    function enableFeeAmount(uint24 feeRate, bool bOn) external;

    function setFeeTo(address) external;

    function setOwner(address) external;

    function acceptFeeToSetter() external;
}
