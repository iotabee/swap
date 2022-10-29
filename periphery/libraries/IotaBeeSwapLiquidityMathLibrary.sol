// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;

import "../../core/interfaces/IIotaBeeSwapERC20.sol";
import "../../core/interfaces/IIotaBeeSwapPool.sol";
import "../../core/interfaces/IIotaBeeSwapFactory.sol";
import "./Babylonian.sol";
import "./FullMath.sol";

import "./IotaBeeSwapLibrary.sol";

// library containing some math for dealing with the liquidity shares of a pool, e.g. computing their exact value
// in terms of the underlying tokens
library IotaBeeSwapLiquidityMathLibrary {
    // computes the direction and magnitude of the profit-maximizing trade
    function computeProfitMaximizingTrade(
        uint256 truePriceTokenA,
        uint256 truePriceTokenB,
        uint256 reserveA,
        uint256 reserveB,
        uint24 feeRate
    ) internal pure returns (bool aToB, uint256 amountIn) {
        aToB =
            FullMath.mulDiv(reserveA, truePriceTokenB, reserveB) <
            truePriceTokenA;

        uint256 invariant = reserveA * reserveB;

        uint256 leftSide = Babylonian.sqrt(
            FullMath.mulDiv(
                invariant * IotaBeeSwapLibrary.FEE_DIV_CONST,
                aToB ? truePriceTokenA : truePriceTokenB,
                (aToB ? truePriceTokenB : truePriceTokenA) *
                    (IotaBeeSwapLibrary.FEE_DIV_CONST - feeRate)
            )
        );
        uint256 rightSide = (
            aToB
                ? reserveA * (IotaBeeSwapLibrary.FEE_DIV_CONST)
                : reserveB * (IotaBeeSwapLibrary.FEE_DIV_CONST)
        ) / (IotaBeeSwapLibrary.FEE_DIV_CONST - feeRate);

        if (leftSide < rightSide) return (false, 0);

        // compute the amount that must be sent to move the price to the profit-maximizing price
        amountIn = leftSide - (rightSide);
    }

    // gets the reserves after an arbitrage moves the price to the profit-maximizing ratio given an externally observed true price
    function getReservesAfterArbitrage(
        address factory,
        address tokenA,
        address tokenB,
        uint24 feeRate,
        uint256 truePriceTokenA,
        uint256 truePriceTokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        // first get reserves before the swap
        (reserveA, reserveB) = IotaBeeSwapLibrary.getReserves(
            factory,
            tokenA,
            tokenB,
            feeRate
        );

        require(
            reserveA > 0 && reserveB > 0,
            "IotaBeeSwapArbitrageLibrary: ZERO_POOL_RESERVES"
        );

        // then compute how much to swap to arb to the true price
        (bool aToB, uint256 amountIn) = computeProfitMaximizingTrade(
            truePriceTokenA,
            truePriceTokenB,
            reserveA,
            reserveB,
            feeRate
        );

        if (amountIn == 0) {
            return (reserveA, reserveB);
        }

        // now affect the trade to the reserves
        if (aToB) {
            uint256 amountOut = IotaBeeSwapLibrary.getAmountOut(
                amountIn,
                reserveA,
                reserveB,
                feeRate
            );
            reserveA += amountIn;
            reserveB -= amountOut;
        } else {
            uint256 amountOut = IotaBeeSwapLibrary.getAmountOut(
                amountIn,
                reserveB,
                reserveA,
                feeRate
            );
            reserveB += amountIn;
            reserveA -= amountOut;
        }
    }

    // computes liquidity value given all the parameters of the pool
    function computeLiquidityValue(
        uint256 reservesA,
        uint256 reservesB,
        uint256 totalSupply,
        uint256 liquidityAmount,
        bool feeOn,
        uint256 kLast
    ) internal pure returns (uint256 tokenAAmount, uint256 tokenBAmount) {
        if (feeOn && kLast > 0) {
            uint256 rootK = Babylonian.sqrt(reservesA * reservesB);
            uint256 rootKLast = Babylonian.sqrt(kLast);
            if (rootK > rootKLast) {
                uint256 numerator1 = totalSupply;
                uint256 numerator2 = rootK - rootKLast;
                uint256 denominator = rootK * 5 + rootKLast;
                uint256 feeLiquidity = FullMath.mulDiv(
                    numerator1,
                    numerator2,
                    denominator
                );
                totalSupply = totalSupply + feeLiquidity;
            }
        }
        return (
            (reservesA * liquidityAmount) / totalSupply,
            (reservesB * liquidityAmount) / totalSupply
        );
    }

    // get all current parameters from the pool and compute value of a liquidity amount
    // **note this is subject to manipulation, e.g. sandwich attacks**. prefer passing a manipulation resistant price to
    // #getLiquidityValueAfterArbitrageToPrice
    function getLiquidityValue(
        address factory,
        address tokenA,
        address tokenB,
        uint24 feeRate,
        uint256 liquidityAmount
    ) internal view returns (uint256 tokenAAmount, uint256 tokenBAmount) {
        (uint256 reservesA, uint256 reservesB) = IotaBeeSwapLibrary.getReserves(
            factory,
            tokenA,
            tokenB,
            feeRate
        );
        IIotaBeeSwapPool pool = IIotaBeeSwapPool(
            IotaBeeSwapLibrary.poolFor(factory, tokenA, tokenB, feeRate)
        );
        bool feeOn = IIotaBeeSwapFactory(factory).feeTo() != address(0);
        uint256 kLast = feeOn ? pool.kLast() : 0;
        uint256 totalSupply = pool.totalSupply();
        return
            computeLiquidityValue(
                reservesA,
                reservesB,
                totalSupply,
                liquidityAmount,
                feeOn,
                kLast
            );
    }

    // given two tokens, tokenA and tokenB, and their "true price", i.e. the observed ratio of value of token A to token B,
    // and a liquidity amount, returns the value of the liquidity in terms of tokenA and tokenB
    function getLiquidityValueAfterArbitrageToPrice(
        address factory,
        address tokenA,
        address tokenB,
        uint24 feeRate,
        uint256 truePriceTokenA,
        uint256 truePriceTokenB,
        uint256 liquidityAmount
    ) internal view returns (uint256 tokenAAmount, uint256 tokenBAmount) {
        bool feeOn = IIotaBeeSwapFactory(factory).feeTo() != address(0);
        IIotaBeeSwapPool pool = IIotaBeeSwapPool(
            IotaBeeSwapLibrary.poolFor(factory, tokenA, tokenB, feeRate)
        );
        uint256 kLast = feeOn ? pool.kLast() : 0;
        uint256 totalSupply = pool.totalSupply();

        // this also checks that totalSupply > 0
        require(
            totalSupply >= liquidityAmount && liquidityAmount > 0,
            "ComputeLiquidityValue: LIQUIDITY_AMOUNT"
        );

        (uint256 reservesA, uint256 reservesB) = getReservesAfterArbitrage(
            factory,
            tokenA,
            tokenB,
            feeRate,
            truePriceTokenA,
            truePriceTokenB
        );

        return
            computeLiquidityValue(
                reservesA,
                reservesB,
                totalSupply,
                liquidityAmount,
                feeOn,
                kLast
            );
    }
}
