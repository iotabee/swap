//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.7;
import "../core/interfaces/IERC20.sol";
import "./ownable.sol";

contract FaucetERC20 is Ownable {
    constructor() {
        owner = msg.sender;
    }

    mapping(address => mapping(address => uint256)) public faucetLastOf;
    uint256 public faucetAmount = 100;
    uint256 public limitTime = 600; //as seconds
    event Faucet(
        address indexed sender,
        address indexed token,
        address indexed to,
        uint256 amount
    );

    function faucet(address token, address to) external returns (bool) {
        IERC20 t = IERC20(token);
        require(block.timestamp > faucetLastOf[token][to] + 600, "time wait");
        uint256 amount = faucetAmount * (10**t.decimals());
        faucetLastOf[token][to] = block.timestamp;
        t.transfer(to, amount);
        emit Faucet(msg.sender, token, to, amount);
        return true;
    }

    function setFaucetAmount(uint256 a) external {
        require(msg.sender == owner, "forbidden");
        faucetAmount = a;
    }

    function setLimitTime(uint256 t) external {
        require(msg.sender == owner, "forbidden");
        limitTime = t;
    }
}
