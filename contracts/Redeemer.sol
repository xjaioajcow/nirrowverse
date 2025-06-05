// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice 可燃烧的 ERC20 接口
interface IERC20Burnable {
    function burn(uint256 amount) external;
}

/// @notice LOTTO 代币铸造接口
interface ILotto {
    function mint(address to, uint256 amount) external;
}

/// @notice DEX Router 接口（这里只示例了 UniswapV2）
interface IRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract Redeemer is Ownable {
    using SafeERC20 for IERC20;

    address public llt;      // LLT 代币合约地址
    address public lotto;    // LOTTO 代币合约地址
    address public router;   // DEX Router 合约地址
    address public locker;   // 锁仓合约地址
    address public pool;     // 奖池地址
    address public hype;     // HYPE 代币合约地址
    uint256 public unit;     // LOTTO 最小单位，通常 1e18

    /**
     * @param _llt    LLT 合约地址
     * @param _lotto  LOTTO 合约地址
     * @param _router DEX Router 合约地址
     * @param _locker 锁仓合约地址
     * @param _pool   奖池地址
     * @param _hype   HYPE 代币合约地址
     * @param _unit   LOTTO 单位 (1e18)
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
        llt = _llt;
        lotto = _lotto;
        router = _router;
        locker = _locker;
        pool = _pool;
        hype = _hype;
        unit = _unit;
    }

    /**
     * @notice 用 amt 个 LLT 换成 LOTTO，并注入 HYPE 及锁仓 LLT
     * 步骤：
     *   1) 卖出 20% 的 LLT → 换成 HYPE → 转给 pool
     *   2) 燃烧 5% LLT
     *   3) 锁定 75% LLT 到 locker
     *   4) 铸造 (amt*75%)/unit LOTTO 给用户
     *   5) 铸造 (amt*10%)/unit LOTTO 给 pool
     */
    function swap(uint256 amt) external {
        require(amt > 0, "Amount must be > 0");

        // —— 第一步：把 amt 个 LLT 从用户转到合约
        IERC20(llt).safeTransferFrom(msg.sender, address(this), amt);

        // —— 第二步：卖出 20% LLT → 换 HYPE → 注入 pool
        uint256 sell = (amt * 20) / 100;
        IERC20(llt).safeApprove(router, sell);
        address;
        path[0] = llt;
        path[1] = hype;
        IRouter(router).swapExactTokensForTokens(
            sell,
            0,
            path,
            pool,
            block.timestamp + 300
        );

        // —— 第三步：燃烧 5% LLT
        uint256 burnAmt = (amt * 5) / 100;
        IERC20Burnable(llt).burn(burnAmt);

        // —— 第四步：锁定 75% LLT 到 locker
        uint256 lockAmt = (amt * 75) / 100;
        IERC20(llt).safeTransfer(locker, lockAmt);

        // —— 第五步：给用户铸造 LOTTO，按 unit 大小对齐
        uint256 userUnits = ((amt * 75) / 100) / unit;
        if (userUnits > 0) {
            ILotto(lotto).mint(msg.sender, userUnits * unit);
        }

        // —— 第六步：给 pool 铸造 LOTTO，按 unit 大小对齐
        uint256 poolUnits = ((amt * 10) / 100) / unit;
        if (poolUnits > 0) {
            ILotto(lotto).mint(pool, poolUnits * unit);
        }
    }

    /// @notice 设置新的锁仓合约地址（仅 owner）
    function setLocker(address _locker) external onlyOwner {
        locker = _locker;
    }
}
