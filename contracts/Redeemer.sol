// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Uniswap V2 路由器接口（仅使用 swapExactTokensForTokens 方法）
interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

/// @notice ERC20 燃烧接口（LLT 如果支持 burn）
interface IERC20Burnable {
    function burn(uint256 amount) external;
}

/// @notice LOTTO 铸币接口（LOTTO 支持 mint）
interface ILotto {
    function mint(address to, uint256 amount) external;
}

contract Redeemer is Ownable {
    using SafeERC20 for IERC20;

    address public llt;      // LLT 主代币合约地址
    address public lotto;    // LOTTO 票券代币合约地址
    address public router;   // 去中心化交易所路由合约地址 (如 HyperSwap Router)
    address public locker;   // 锁仓合约地址（StakeVault）
    address public pool;     // 奖池地址（如 HourlyDraw 合约地址）
    address public hype;     // HYPE 代币合约地址（LLT 兑换目标代币）
    uint256 public unit;     // LOTTO 单位比例，通常为 1e18

    /**
     * @param _llt    LLT 合约地址（若部署时未知可暂设为 address(0)）
     * @param _lotto  LOTTO 合约地址
     * @param _router 去中心化交易所 Router 地址
     * @param _locker StakeVault 合约地址
     * @param _pool   奖池地址（如 HourlyDraw 合约地址）
     * @param _hype   HYPE 代币合约地址
     * @param _unit   LOTTO 单位（如 LOTTO 为18位精度则传入 1e18）
     */
    constructor(
        address _llt,
        address _lotto,
        address _router,
        address _locker,
        address _pool,
        address _hype,
        uint256 _unit
    ) {
        llt    = _llt;
        lotto  = _lotto;
        router = _router;
        locker = _locker;
        pool   = _pool;
        hype   = _hype;
        unit   = _unit;
    }

    /**
     * @notice 用户兑换操作：将一定数量 amt 的 LLT 按比例兑换为 HYPE 和 LOTTO
     *  - 20% 的 LLT 通过去中心化交易所兑换为 HYPE 转入奖池
     *  - 5% 的 LLT 被直接销毁 (burn)
     *  - 75% 的 LLT 转入锁仓合约（StakeVault）
     *  - 按 75% 比例的 LLT 数量铸造等值的 LOTTO 给用户 (作为兑换奖励)
     *  - 按 10% 比例的 LLT 数量铸造等值的 LOTTO 给奖池
     * @param amt 要兑换的 LLT 数量（18 位精度）
     */
    function swap(uint256 amt) external {
        require(amt > 0, "Amount must be greater than zero");
        require(llt != address(0) && lotto != address(0), "LLT or LOTTO not set");
        require(router != address(0), "Router not set");
        require(locker != address(0), "Locker not set");
        require(pool != address(0), "Pool not set");
        require(hype != address(0), "HYPE not set");

        // 将用户的 amt 数量 LLT 转移到本合约
        IERC20(llt).safeTransferFrom(msg.sender, address(this), amt);

        // 20% 用于兑换 HYPE 并转入奖池
        uint256 sellAmt = (amt * 20) / 100;
        if (sellAmt > 0) {
            // 允许 Router 合约支配 sellAmt 数量的 LLT
            IERC20(llt).safeApprove(router, sellAmt);
            // 构建兑换路径：LLT -> HYPE
            address[] memory path = new address[](2);
            path[0] = llt;
            path[1] = hype;
            // 执行兑换，将获得的 HYPE 直接发送到奖池地址
            IUniswapV2Router(router).swapExactTokensForTokens(
                sellAmt,
                0,
                path,
                pool,
                block.timestamp + 300
            );
            // 重置 Router 的 LLT 授权为0（安全起见）
            IERC20(llt).safeApprove(router, 0);
        }

        // 5% 直接燃烧 LLT
        uint256 burnAmt = (amt * 5) / 100;
        if (burnAmt > 0) {
            // 使用 LLT 合约自己的燃烧函数销毁（从本合约持有的余额中扣除）
            IERC20Burnable(llt).burn(burnAmt);
        }

        // 75% 转移到锁仓合约 StakeVault
        uint256 lockAmt = (amt * 75) / 100;
        if (lockAmt > 0) {
            IERC20(llt).safeTransfer(locker, lockAmt);
        }

        // 根据75%部分，为用户按比例铸造 LOTTO：铸造数量 = (amt * 75%) / unit
        uint256 userUnits = ((amt * 75) / 100) / unit;
        if (userUnits > 0) {
            ILotto(lotto).mint(msg.sender, userUnits * unit);
        }

        // 根据10%部分，为奖池铸造 LOTTO：铸造数量 = (amt * 10%) / unit
        uint256 poolUnits = ((amt * 10) / 100) / unit;
        if (poolUnits > 0) {
            ILotto(lotto).mint(pool, poolUnits * unit);
        }
    }

    /// @notice Owner 可以更新 StakeVault (locker) 地址
    function setLocker(address _locker) external onlyOwner {
        require(_locker != address(0), "Invalid locker address");
        locker = _locker;
    }

    /// @notice Owner 可以更新 Router 地址
    function setRouter(address _router) external onlyOwner {
        require(_router != address(0), "Invalid router address");
        router = _router;
    }

    /// @notice Owner 可以更新奖池地址
    function setPool(address _pool) external onlyOwner {
        require(_pool != address(0), "Invalid pool address");
        pool = _pool;
    }

    /// @notice Owner 可以更新 HYPE 代币地址
    function setHype(address _hype) external onlyOwner {
        require(_hype != address(0), "Invalid HYPE address");
        hype = _hype;
    }

    /// @notice Owner 可以更新 LOTTO 单位值
    function setUnit(uint256 _unit) external onlyOwner {
        require(_unit > 0, "Unit must be > 0");
        unit = _unit;
    }

    /// @notice Owner 可以设置/更新 LLT 主代币合约地址
    function setLlt(address _llt) external onlyOwner {
        require(_llt != address(0), "Invalid LLT address");
        llt = _llt;
    }
}
