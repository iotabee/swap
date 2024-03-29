//SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.17;

import "./interfaces/IIotaBeeSwapFactory.sol";
import "./interfaces/IIotaBeeSwapPool.sol";
import "./IotaBeeSwapPoolDeployer.sol";

contract IotaBeeSwapFactory is IIotaBeeSwapFactory, IotaBeeSwapPoolDeployer {
    address public override feeTo;
    address public override owner;
    address internal newOwner;

    mapping(uint24 => int24) public override feeRateAmount;
    mapping(address => mapping(address => mapping(uint24 => address)))
        public
        override getPool;
    address[] public override allPools;

    constructor() {
        owner = msg.sender;
        feeRateAmount[50] = 1;
        feeRateAmount[300] = 1;
        feeRateAmount[1000] = 1;
    }

    function allPoolsLength() external view override returns (uint256) {
        return allPools.length;
    }

    function createPool(
        address tokenA,
        address tokenB,
        uint24 feeRate
    ) external override returns (address pool) {
        require(tokenA != tokenB, "IotaBeeSwap: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "IotaBeeSwap: ZERO_ADDRESS");
        require(feeRateAmount[feeRate] != 0, "IotaBeeSwap: INVALID_FEERATE");
        require(
            getPool[token0][token1][feeRate] == address(0),
            "IotaBeeSwap: POOL_EXISTS"
        );
        pool = deploy(address(this), token0, token1, feeRate);
        getPool[token0][token1][feeRate] = pool;
        getPool[token1][token0][feeRate] = pool;
        allPools.push(pool);
        emit PoolCreated(token0, token1, feeRate, pool);
    }

    function enableFeeAmount(uint24 feeRate, bool bOn) external override {
        require(msg.sender == owner);
        require(feeRate < 100000);
        int24 v = 0;
        if (bOn) {
            v = 1;
        }
        feeRateAmount[feeRate] = v;
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == owner, "IotaBeeSwap: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setOwner(address _owner) external override {
        require(msg.sender == owner, "IotaBeeSwap: FORBIDDEN");
        newOwner = _owner;
    }

    function acceptFeeToSetter() external override {
        require(msg.sender == newOwner, "IotaBeeSwap: FORBIDDEN");
        owner = newOwner;
        newOwner = address(0);
    }

    function POOL_INIT_CODE_HASH() public pure returns(bytes32){
        return keccak256(abi.encodePacked(type(IotaBeeSwapPool).creationCode));
    }
}
