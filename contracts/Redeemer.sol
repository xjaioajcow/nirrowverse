// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Uniswap V2–style Router interface, only swapExactTokensForTokens is needed
interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

/// @notice ERC20 burn interface, if LLT supports burn()
interface IERC20Burnable {
    function burn(uint256 amount) external;
}

/// @notice LOTTO mint interface, if LOTTO supports mint()
interface ILotto {
    function mint(address to, uint256 amount) external;
}

contract Redeemer is Ownable {
    using SafeERC20 for IERC20;

    address public llt;      // LLT token contract address
    address public lotto;    // LOTTO token contract address
    address public router;   // DEX Router contract address (HyperSwap Router)
    address public locker;   // StakeVault contract address
    address public pool;     // Pool address (e.g., HourlyDraw contract)
    address public hype;     // HYPE token contract address
    uint256 public unit;     // LOTTO unit, typically 1e18

    /**
     * @param _llt    LLT contract address (use address(0) as placeholder until LLT is deployed)
     * @param _lotto  LOTTO contract address (use address(0) until LOTTO is deployed)
     * @param _router HyperSwap Router address (e.g., 0xb4a9C4e6Ea8E2191d2FA5B380452a634Fb21240A)
     * @param _locker StakeVault contract address (use address(0) until StakeVault is deployed)
     * @param _pool   Pool address (e.g., HourlyDraw contract address, use address(0) placeholder)
     * @param _hype   HYPE token contract address (e.g., 0x5555555555555555555555555555555555555555)
     * @param _unit   LOTTO unit in smallest decimals (e.g., 1e18 if LOTTO is 18 decimals)
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
     * @notice Swap amt LLT into HYPE and LOTTO, then send portions to pool and locker
     *   • 20% of amt LLT is swapped for HYPE via router and sent to pool
     *   • 5% of amt LLT is burned
     *   • 75% of amt LLT is transferred to locker
     *   • Mint (amt * 75%)/unit LOTTO to msg.sender
     *   • Mint (amt * 10%)/unit LOTTO to pool
     * @param amt Amount of LLT (in 18-decimal units) to redeem
     */
    function swap(uint256 amt) external {
        require(amt > 0, "Amount must be greater than zero");
        require(llt != address(0) && lotto != address(0), "LLT or LOTTO not set");
        require(router != address(0), "Router not set");
        require(locker != address(0), "Locker not set");
        require(pool != address(0), "Pool not set");
        require(hype != address(0), "HYPE not set");

        // Transfer all LLT from user to this contract
        IERC20(llt).safeTransferFrom(msg.sender, address(this), amt);

        // 20% → swap to HYPE → send to pool
        uint256 sellAmt = (amt * 20) / 100;
        if (sellAmt > 0) {
            IERC20(llt).safeApprove(router, sellAmt);
            address;
            path[0] = llt;
            path[1] = hype;
            IUniswapV2Router(router).swapExactTokensForTokens(
                sellAmt,
                0,
                path,
                pool,
                block.timestamp + 300
            );
            IERC20(llt).safeApprove(router, 0);
        }

        // 5% → burn LLT
        uint256 burnAmt = (amt * 5) / 100;
        if (burnAmt > 0) {
            IERC20(llt).safeApprove(llt, burnAmt);
            IERC20Burnable(llt).burn(burnAmt);
        }

        // 75% → transfer to locker
        uint256 lockAmt = (amt * 75) / 100;
        if (lockAmt > 0) {
            IERC20(llt).safeTransfer(locker, lockAmt);
        }

        // Mint LOTTO to user: (amt * 75%)/unit
        uint256 userUnits = ((amt * 75) / 100) / unit;
        if (userUnits > 0) {
            ILotto(lotto).mint(msg.sender, userUnits * unit);
        }

        // Mint LOTTO to pool: (amt * 10%)/unit
        uint256 poolUnits = ((amt * 10) / 100) / unit;
        if (poolUnits > 0) {
            ILotto(lotto).mint(pool, poolUnits * unit);
        }
    }

    /// @notice Owner can update locker address
    function setLocker(address _locker) external onlyOwner {
        require(_locker != address(0), "Invalid locker address");
        locker = _locker;
    }

    /// @notice Owner can update router address
    function setRouter(address _router) external onlyOwner {
        require(_router != address(0), "Invalid router address");
        router = _router;
    }

    /// @notice Owner can update pool address
    function setPool(address _pool) external onlyOwner {
        require(_pool != address(0), "Invalid pool address");
        pool = _pool;
    }

    /// @notice Owner can update HYPE address
    function setHype(address _hype) external onlyOwner {
        require(_hype != address(0), "Invalid HYPE address");
        hype = _hype;
    }

    /// @notice Owner can update unit value
    function setUnit(uint256 _unit) external onlyOwner {
        require(_unit > 0, "Unit must be > 0");
        unit = _unit;
    }
}
