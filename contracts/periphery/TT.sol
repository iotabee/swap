//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.7;
import "../core/interfaces/IERC20.sol";

contract TestErc20 is IERC20 {
    string public override name;
    string public override symbol;
    uint8  public immutable override decimals;
    uint256 public override totalSupply;
    address public minter;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    event Mint(address indexed sender, uint256 amount);
    constructor(string memory _name, string memory _symbol, uint8 d) {
        totalSupply = 10000000000 * 10**uint256(d);
        balanceOf[msg.sender] = totalSupply;
        minter = msg.sender;

        name = _name;
        symbol = _symbol;
        decimals = d;
    }

    function mint(uint256 amount) public {
        require(minter == msg.sender);
        totalSupply += amount;
        balanceOf[minter] += amount;
        emit Mint(msg.sender, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= value;
        }
        _transfer(from, to, value);
        return true;
    }

    address[] receivers;
    mapping(address => bool) public isFauceted;
    uint256 public faucetAmount = 1000;
    event Faucet(address indexed sender, uint256 amount);

    function setFaucetAmount(uint256 amount) external returns (bool) {
        require(minter == msg.sender);
        faucetAmount = amount;
        return true;
    }

    function faucet() external returns (bool) {
        require(!isFauceted[msg.sender], "fauceted");
        uint256 amount = faucetAmount * (10**decimals);
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        isFauceted[msg.sender] = true;
        receivers.push(msg.sender);
        emit Faucet(msg.sender, amount);
        return true;
    }

    function getReceivers() public view returns (address[] memory) {
        return receivers;
    }
}
