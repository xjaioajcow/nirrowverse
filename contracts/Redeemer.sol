// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
interface IERC20Burnable {
    function burn(uint256 amount) external;
}

interface ILotto {
    function mint(address to, uint256 amount) external;
}

interface IRouter {
    function WETH() external pure returns (address);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

/// @notice Redeemer 合约实现 LLT 兑换和 LOTTO 铸造逻辑
contract Redeemer is Ownable {
    using SafeERC20 for IERC20;

    address public llt;
    ILotto public lotto;
    IRouter public router;
    address public locker;
    address public pool;
    uint256 public unit;

    constructor(
        address _llt,
        address _lotto,
        address _router,
        address _locker,
        address _pool,
        uint256 _unit
    ) {
        llt = _llt;
        lotto = ILotto(_lotto);
        router = IRouter(_router);
        locker = _locker;
        pool = _pool;
        unit = _unit;
    }

    function setLlt(address _llt) external onlyOwner {
        llt = _llt;
    }

    function setLocker(address _locker) external onlyOwner {
        locker = _locker;
    }

    function setPool(address _pool) external onlyOwner {
        pool = _pool;
    }

    function swap(uint256 amt) external {
        IERC20(llt).safeTransferFrom(msg.sender, address(this), amt);

        uint256 sell = (amt * 20) / 100;
        if (sell > 0) {
            IERC20(llt).safeIncreaseAllowance(address(router), sell);
            address[] memory path = new address[](2);
            path[0] = llt;
            path[1] = router.WETH();
            router.swapExactTokensForTokens(sell, 0, path, pool, block.timestamp);
        }

        uint256 burnAmt = (amt * 5) / 100;
        if (burnAmt > 0) {
            IERC20Burnable(llt).burn(burnAmt);
        }

        uint256 lockAmt = (amt * 75) / 100;
        if (lockAmt > 0) {
            IERC20(llt).safeTransfer(locker, lockAmt);
        }

        uint256 lottoUser = lockAmt / unit;
        if (lottoUser > 0) {
            lotto.mint(msg.sender, lottoUser * unit);
        }

        uint256 lottoPool = ((amt * 10) / 100) / unit;
        if (lottoPool > 0) {
            lotto.mint(pool, lottoPool * unit);
        }
    }
}
