//SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.17;

import "../core/interfaces/IIotaBeeSwapFactory.sol";
import "../core/interfaces/IERC20.sol";

import "./libraries/TransferHelper.sol";
import "./libraries/IotaBeeSwapLibrary.sol";

import "./interfaces/IIotaBeeSwapLpRouter.sol";
import "./interfaces/IWETH.sol";

contract IotaBeeSwapLpRouter is IIotaBeeSwapLpRouter {
    address public immutable factory;
    address public immutable WETH;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "IBSRouter: EXPIRED");
        _;
    }

    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint24 feeRate,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) private returns (uint256 amountA, uint256 amountB) {
        // create the pool if it doesn't exist yet
        if (
            IIotaBeeSwapFactory(factory).getPool(tokenA, tokenB, feeRate) ==
            address(0)
        ) {
            IIotaBeeSwapFactory(factory).createPool(tokenA, tokenB, feeRate);
        }
        (uint256 reserveA, uint256 reserveB) = IotaBeeSwapLibrary.getReserves(
            factory,
            tokenA,
            tokenB,
            feeRate
        );
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = IotaBeeSwapLibrary.quote(
                amountADesired,
                reserveA,
                reserveB
            );
            if (amountBOptimal <= amountBDesired) {
                require(
                    amountBOptimal >= amountBMin,
                    "IBSRouter: INSUFFICIENT_B_AMOUNT"
                );
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = IotaBeeSwapLibrary.quote(
                    amountBDesired,
                    reserveB,
                    reserveA
                );
                assert(amountAOptimal <= amountADesired);
                require(
                    amountAOptimal >= amountAMin,
                    "IBSRouter: INSUFFICIENT_A_AMOUNT"
                );
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint24 feeRate,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        override
        ensure(deadline)
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        (amountA, amountB) = _addLiquidity(
            tokenA,
            tokenB,
            feeRate,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );
        address pool = IotaBeeSwapLibrary.poolFor(
            factory,
            tokenA,
            tokenB,
            feeRate
        );
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pool, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pool, amountB);
        liquidity = IIotaBeeSwapPool(pool).mint(to);
    }

    function addLiquidityETH(
        address token,
        uint24 feeRate,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        override
        ensure(deadline)
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            feeRate,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pool = IotaBeeSwapLibrary.poolFor(
            factory,
            token,
            WETH,
            feeRate
        );
        TransferHelper.safeTransferFrom(token, msg.sender, pool, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pool, amountETH));
        liquidity = IIotaBeeSwapPool(pool).mint(to);
        if (msg.value > amountETH)
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH); // refund dust eth, if any
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint24 feeRate,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        public
        override
        ensure(deadline)
        returns (uint256 amountA, uint256 amountB)
    {
        address pool = IotaBeeSwapLibrary.poolFor(
            factory,
            tokenA,
            tokenB,
            feeRate
        );
        IIotaBeeSwapPool(pool).transferFrom(msg.sender, pool, liquidity); // send liquidity to pool
        (uint256 amount0, uint256 amount1) = IIotaBeeSwapPool(pool).burn(to);
        (address token0, ) = IotaBeeSwapLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0
            ? (amount0, amount1)
            : (amount1, amount0);
        require(amountA >= amountAMin, "IBSRouter: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "IBSRouter: INSUFFICIENT_B_AMOUNT");
    }

    function WithdrawETH(address to, uint256 amount) private {
        amount = (amount / 10**12) * (10**12);
        IWETH(WETH).withdraw(amount);
        TransferHelper.safeTransferETH(to, amount);
    }

    function removeLiquidityETH(
        address token,
        uint24 feeRate,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        public
        override
        ensure(deadline)
        returns (uint256 amountToken, uint256 amountETH)
    {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            feeRate,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        WithdrawETH(to, amountETH);
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint24 feeRate,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        PermitData memory pd
    ) external override returns (uint256 amountA, uint256 amountB) {
        address pool = IotaBeeSwapLibrary.poolFor(
            factory,
            tokenA,
            tokenB,
            feeRate
        );
        uint256 value = pd.approveMax ? type(uint256).max : liquidity;
        IIotaBeeSwapPool(pool).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            pd.v,
            pd.r,
            pd.s
        );
        (amountA, amountB) = removeLiquidity(
            tokenA,
            tokenB,
            feeRate,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            deadline
        );
    }

    function removeLiquidityETHWithPermit(
        address token,
        uint24 feeRate,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        PermitData memory pd
    ) external override returns (uint256 amountToken, uint256 amountETH) {
        address pool = IotaBeeSwapLibrary.poolFor(
            factory,
            token,
            WETH,
            feeRate
        );
        uint256 value = pd.approveMax ? type(uint256).max : liquidity;
        IIotaBeeSwapPool(pool).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            pd.v,
            pd.r,
            pd.s
        );
        (amountToken, amountETH) = removeLiquidityETH(
            token,
            feeRate,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint24 feeRate,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountETH) {
        (, amountETH) = removeLiquidity(
            token,
            WETH,
            feeRate,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(
            token,
            to,
            IERC20(token).balanceOf(address(this))
        );
        WithdrawETH(to, amountETH);
    }

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint24 feeRate,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        PermitData memory pd
    ) external virtual override returns (uint256 amountETH) {
        address pool = IotaBeeSwapLibrary.poolFor(
            factory,
            token,
            WETH,
            feeRate
        );
        uint256 value = pd.approveMax ? type(uint256).max : liquidity;
        IIotaBeeSwapPool(pool).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            pd.v,
            pd.r,
            pd.s
        );
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token,
            feeRate,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) public pure override returns (uint256 amountB) {
        return IotaBeeSwapLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint24 feeRate
    ) public pure override returns (uint256 amountOut) {
        return
            IotaBeeSwapLibrary.getAmountOut(
                amountIn,
                reserveIn,
                reserveOut,
                feeRate
            );
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint24 feeRate
    ) public pure override returns (uint256 amountIn) {
        return
            IotaBeeSwapLibrary.getAmountOut(
                amountOut,
                reserveIn,
                reserveOut,
                feeRate
            );
    }

    function getAmountsOut(
        uint256 amountIn,
        address[] memory path,
        uint24[] calldata feeRates
    ) public view override returns (uint256[] memory amounts) {
        return
            IotaBeeSwapLibrary.getAmountsOut(factory, amountIn, path, feeRates);
    }

    function getAmountsIn(
        uint256 amountOut,
        address[] memory path,
        uint24[] calldata feeRates
    ) public view override returns (uint256[] memory amounts) {
        return
            IotaBeeSwapLibrary.getAmountsIn(factory, amountOut, path, feeRates);
    }
}
