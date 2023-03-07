//SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.17;

import "../../core/IotaBeeSwapPool.sol";

library IotaBeeSwapLibrary {
    uint24 public constant FEE_DIV_CONST = 100000;

    //keccak256(abi.encodePacked(type(IotaBeeSwapPool).creationCode));
    bytes32 internal constant POOL_INIT_CODE_HASH =
        0x5a46d8e7d5ac420387bd203f5fcd5593ba34af9f0ee9b781a31834bec17eda90;

    // returns sorted token addresses, used to handle return values from pools sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "IotaBeeSwapLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "IotaBeeSwapLibrary: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pool without making any external calls
    function poolFor(
        address factory,
        address tokenA,
        address tokenB,
        uint24 feeRate
    ) internal pure returns (address pool) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encode(token0, token1, feeRate)),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pool
    function getReserves(
        address factory,
        address tokenA,
        address tokenB,
        uint24 feeRate
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IIotaBeeSwapPool(
            poolFor(factory, tokenA, tokenB, feeRate)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pool reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "IotaBeeSwapLibrary: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "IotaBeeSwapLibrary: INSUFFICIENT_LIQUIDITY"
        );
        amountB = (amountA * reserveB) / reserveA;
    }

    // given an input amount of an asset and pool reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint24 feeRate
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "IotaBeeSwapLibrary: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "IotaBeeSwapLibrary: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn * (FEE_DIV_CONST - feeRate);
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * FEE_DIV_CONST) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pool reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint24 feeRate
    ) internal pure returns (uint256 amountIn) {
        require(
            amountOut > 0,
            "IotaBeeSwapLibrary: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        require(
            reserveIn > 0 && reserveOut > 0,
            "IotaBeeSwapLibrary: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn * amountOut * (FEE_DIV_CONST);
        uint256 denominator = (reserveOut - amountOut) *
            (FEE_DIV_CONST - feeRate);
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pools
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path,
        uint24[] memory feeRates
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "IotaBeeSwapLibrary: INVALID_PATH");
        require(
            feeRates.length == path.length - 1,
            "IotaBeeSwapLibrary: INVALID_FEERATE"
        );
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1],
                feeRates[i]
            );
            amounts[i + 1] = getAmountOut(
                amounts[i],
                reserveIn,
                reserveOut,
                feeRates[i]
            );
        }
    }

    // performs chained getAmountIn calculations on any number of pools
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path,
        uint24[] memory feeRates
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "IotaBeeSwapLibrary: INVALID_PATH");
        require(
            feeRates.length == path.length - 1,
            "IotaBeeSwapLibrary: INVALID_FEERATE"
        );
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i],
                feeRates[i]
            );
            amounts[i - 1] = getAmountIn(
                amounts[i],
                reserveIn,
                reserveOut,
                feeRates[i]
            );
        }
    }
}
