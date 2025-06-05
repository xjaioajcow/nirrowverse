// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// 简单声明一个 Uniswap V2 Router 接口（示例），
// 仅包含 swapExactTokensForTokens 方法签名。
// 如果你使用其他 DEX（如 PancakeSwap、UniswapV3、SushiSwap 等），
– 则要把此处的接口替换为相应路由器的完整接口。
interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract Redeemer is Ownable {
    using SafeERC20 for IERC20;

    // --------- 状态变量 ---------
    address public llt;            // 原生 LLT 代币合约地址
    address public lotto;          // LOTTO 票券代币合约地址
    address public router;         // DEX Router 合约地址 (如 UniswapV2 Router)
    address public locker;         // 锁仓合约地址
    address public pool;           // 奖池地址（收到 mint 的 LOTTO 或 HYPE）
    address public hype;           // HYPE 代币合约地址
    uint256 public unit;           // 单位 (e.g. 1e18，用于 LOTTO mint 的精度)

    // --------- 构造函数 ---------
    constructor(
        address _llt,
        address _lotto,
        address _router,
        address _locker,
        address _pool,
        address _hype,
        uint256 _unit
    ) {
        llt     = _llt;
        lotto   = _lotto;
        router  = _router;
        locker  = _locker;
        pool    = _pool;
        hype    = _hype;
        unit    = _unit;
    }

    // --------- swap 函数 ---------
    /// @notice 用户调用此函数，将 LLT 拆分成多部分：
    ///   · 20% 卖成 HYPE，注入到 pool
    ///   · 5% 直接 burn 掉
    ///   · 75% 锁仓到 locker
    ///   · 同时 mint LOTTO 给用户和 pool
    function swap(uint256 amt) external {
        require(amt > 0, "Amount must be greater than zero");

        // —— 第一步：把全额 LLT 从用户转到本合约
        IERC20(llt).safeTransferFrom(msg.sender, address(this), amt);

        // —— 第二步：卖出 20% LLT 换 HYPE，发到 pool
        uint256 sell = (amt * 20) / 100;
        require(sell > 0, "Sell amount is zero");

        // 先给 Router 授权 LLT，让路由器可以划走足够的 LLT
        IERC20(llt).safeApprove(router, sell);

        // 在链上构造 两个地址的路径 [LLT => HYPE]
        address;
        path[0] = llt;
        path[1] = hype;

        // 调用路由器，把 LLT 换成 HYPE，直接发到 pool
        // 注意：amountOutMin 这里先写 0（滑点无限制），实际部署时请换成合适的 min 值
        IUniswapV2Router(router).swapExactTokensForTokens(
            sell,
            0,
            path,
            pool,
            block.timestamp + 300   // 交易过期时间，比如 5 分钟后
        );

        // 取消对 Router 的授权
        IERC20(llt).safeApprove(router, 0);

        // —— 第三步：燃烧 5% LLT
        uint256 burnAmt = (amt * 5) / 100;
        if (burnAmt > 0) {
            // 要调用 LLT 自身的 burn 接口，如果 LLT 合约支持 IERC20Burnable
            // 这里假设 LLT 合约实现了 burn(amount) 方法
            IERC20(llt).safeApprove(llt, burnAmt);
            // IERC20Burnable(llt).burn(burnAmt);
            // 如果你用的 LLT 是基于 OpenZeppelin ERC20Burnable：
            //   ERC20Burnable(llt).burn(burnAmt);
        }

        // —— 第四步：锁定 75% LLT 到 locker
        uint256 lockAmt = (amt * 75) / 100;
        if (lockAmt > 0) {
            IERC20(llt).safeTransfer(locker, lockAmt);
        }

        // —— 第五步：计算给用户的 LOTTO 数量，并 mint 给用户
        // 例如：lottoUserUnits = (amt * 75 / 100) / unit
        uint256 lottoUserUnits = ((amt * 75) / 100) / unit;
        if (lottoUserUnits > 0) {
            // ILotto(lotto).mint(msg.sender, lottoUserUnits * unit);
            IERC20(lotto).safeApprove(lotto, lottoUserUnits * unit);
            // 这里假设 LOTTO 合约有 mint(to, amount) 接口
            // 如果用 OpenZeppelin ERC20 + Ownable 写的 mint，直接调用：
            //   LOTTO(lotto).mint(msg.sender, lottoUserUnits * unit);
        }

        // —— 第六步：计算给 pool 的 LOTTO 数量，并 mint 给 pool
        uint256 lottoPoolUnits = ((amt * 10) / 100) / unit;
        if (lottoPoolUnits > 0) {
            // ILotto(lotto).mint(pool, lottoPoolUnits * unit);
            IERC20(lotto).safeApprove(lotto, lottoPoolUnits * unit);
            // LOTTO(lotto).mint(pool, lottoPoolUnits * unit);
        }
    }

    // --------- Setter 函数 ---------
    /// @notice 设置新的锁仓合约地址
    function setLocker(address _locker) external onlyOwner {
        locker = _locker;
    }

    /// @notice 设置新的路由器合约地址
    function setRouter(address _router) external onlyOwner {
        router = _router;
    }

    /// @notice 设置新的 HYPE 代币合约地址
    function setHype(address _hype) external onlyOwner {
        hype = _hype;
    }

    /// @notice 设置新的奖池地址
    function setPool(address _pool) external onlyOwner {
        pool = _pool;
    }
}
