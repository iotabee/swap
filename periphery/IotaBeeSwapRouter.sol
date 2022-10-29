//SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.17;

import "../core/interfaces/IIotaBeeSwapFactory.sol";
import "../core/interfaces/IERC20.sol";

import "./libraries/TransferHelper.sol";
import "./libraries/IotaBeeSwapLibrary.sol";

import "./interfaces/IIotaBeeSwapRouter.sol";
import "./interfaces/IWETH.sol";

contract IotaBeeSwapRouter is IIotaBeeSwapRouter {
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

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pool
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        uint24[] memory feeRates,
        address _to
    ) private {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = IotaBeeSwapLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < path.length - 2
                ? IotaBeeSwapLibrary.poolFor(
                    factory,
                    output,
                    path[i + 2],
                    feeRates[i + 1]
                )
                : _to;
            IIotaBeeSwapPool(
                IotaBeeSwapLibrary.poolFor(factory, input, output, feeRates[i])
            ).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint24[] calldata feeRates,
        address to,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256[] memory amounts) {
        amounts = IotaBeeSwapLibrary.getAmountsOut(
            factory,
            amountIn,
            path,
            feeRates
        );
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "IBSRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            IotaBeeSwapLibrary.poolFor(factory, path[0], path[1], feeRates[0]),
            amounts[0]
        );
        _swap(amounts, path, feeRates, to);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        uint24[] calldata feeRates,
        address to,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256[] memory amounts) {
        amounts = IotaBeeSwapLibrary.getAmountsIn(
            factory,
            amountOut,
            path,
            feeRates
        );
        require(amounts[0] <= amountInMax, "IBSRouter: EXCESSIVE_INPUT_AMOUNT");
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            IotaBeeSwapLibrary.poolFor(factory, path[0], path[1], feeRates[0]),
            amounts[0]
        );
        _swap(amounts, path, feeRates, to);
    }

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        uint24[] calldata feeRates,
        address to,
        uint256 deadline
    )
        external
        payable
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path[0] == WETH, "IBSRouter: INVALID_PATH");
        amounts = IotaBeeSwapLibrary.getAmountsOut(
            factory,
            msg.value,
            path,
            feeRates
        );
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "IBSRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(
            IWETH(WETH).transfer(
                IotaBeeSwapLibrary.poolFor(
                    factory,
                    path[0],
                    path[1],
                    feeRates[0]
                ),
                amounts[0]
            )
        );
        _swap(amounts, path, feeRates, to);
    }

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        uint24[] calldata feeRates,
        address to,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256[] memory amounts) {
        require(path[path.length - 1] == WETH, "IBSRouter: INVALID_PATH");
        amounts = IotaBeeSwapLibrary.getAmountsIn(
            factory,
            amountOut,
            path,
            feeRates
        );
        require(amounts[0] <= amountInMax, "IBSRouter: EXCESSIVE_INPUT_AMOUNT");
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            IotaBeeSwapLibrary.poolFor(factory, path[0], path[1], feeRates[0]),
            amounts[0]
        );
        _swap(amounts, path, feeRates, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint24[] calldata feeRates,
        address to,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256[] memory amounts) {
        require(path[path.length - 1] == WETH, "IBSRouter: INVALID_PATH");
        amounts = IotaBeeSwapLibrary.getAmountsOut(
            factory,
            amountIn,
            path,
            feeRates
        );
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "IBSRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            IotaBeeSwapLibrary.poolFor(factory, path[0], path[1], feeRates[0]),
            amounts[0]
        );
        _swap(amounts, path, feeRates, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        uint24[] calldata feeRates,
        address to,
        uint256 deadline
    )
        external
        payable
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path[0] == WETH, "IBSRouter: INVALID_PATH");
        amounts = IotaBeeSwapLibrary.getAmountsIn(
            factory,
            amountOut,
            path,
            feeRates
        );
        require(amounts[0] <= msg.value, "IBSRouter: EXCESSIVE_INPUT_AMOUNT");
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(
            IWETH(WETH).transfer(
                IotaBeeSwapLibrary.poolFor(
                    factory,
                    path[0],
                    path[1],
                    feeRates[0]
                ),
                amounts[0]
            )
        );
        _swap(amounts, path, feeRates, to);
        if (msg.value > amounts[0])
            TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]); // refund dust eth, if any
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pool
    function _swapSupportingFeeOnTransferTokens(
        address[] memory path,
        uint24[] memory feeRates,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = IotaBeeSwapLibrary.sortTokens(input, output);
            IIotaBeeSwapPool pool = IIotaBeeSwapPool(
                IotaBeeSwapLibrary.poolFor(factory, input, output, feeRates[i])
            );
            uint256 amountInput;
            uint256 amountOutput;
            {
                (
                    uint256 reserveInput,
                    uint256 reserveOutput
                ) = IotaBeeSwapLibrary.getReserves(
                        factory,
                        input,
                        output,
                        feeRates[i]
                    );
                amountInput =
                    IERC20(input).balanceOf(address(pool)) -
                    reserveInput;
                amountOutput = IotaBeeSwapLibrary.getAmountOut(
                    amountInput,
                    reserveInput,
                    reserveOutput,
                    feeRates[i]
                );
            }
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOutput)
                : (amountOutput, uint256(0));
            address to = i < path.length - 2
                ? IotaBeeSwapLibrary.poolFor(
                    factory,
                    output,
                    path[i + 2],
                    feeRates[i + 1]
                )
                : _to;
            pool.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint24[] calldata feeRates,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) {
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            IotaBeeSwapLibrary.poolFor(factory, path[0], path[1], feeRates[0]),
            amountIn
        );
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, feeRates, to);
        require(
            (IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore) >=
                amountOutMin,
            "IBSRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        uint24[] calldata feeRates,
        address to,
        uint256 deadline
    ) external payable virtual override ensure(deadline) {
        require(path[0] == WETH, "IBSRouter: INVALID_PATH");
        uint256 amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        assert(
            IWETH(WETH).transfer(
                IotaBeeSwapLibrary.poolFor(
                    factory,
                    path[0],
                    path[1],
                    feeRates[0]
                ),
                amountIn
            )
        );
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, feeRates, to);
        require(
            (IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore) >=
                amountOutMin,
            "IBSRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint24[] calldata feeRates,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) {
        require(path[path.length - 1] == WETH, "IBSRouter: INVALID_PATH");
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            IotaBeeSwapLibrary.poolFor(factory, path[0], path[1], feeRates[0]),
            amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, feeRates, address(this));
        uint256 amountOut = IERC20(WETH).balanceOf(address(this));
        require(
            amountOut >= amountOutMin,
            "IBSRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
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
