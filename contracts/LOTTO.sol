// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title LOTTO 票券代币
/// @notice 只有合约 Owner 有权限铸造（mint）新的 LOTTO 代币，初始总量为 0
/// @dev 继承 OpenZeppelin 的 ERC20 和 Ownable，实现最简单的 mint + burn 功能
contract LOTTO is ERC20, Ownable {
    /// @dev 构造函数固定名称和符号均为 "LOTTO"
    constructor() ERC20("LOTTO", "LOTTO") {
        // 部署时初始总量 0
    }

    /// @notice 铸造新的 LOTTO 代币（仅 owner）
    /// @param to 接收地址
    /// @param amount 铸造数量（最小单位，18 decimals）
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /// @notice 销毁指定地址的 LOTTO 代币
    /// @dev 如果 msg.sender == from，则直接销毁；如果 msg.sender != from，则先检查 allowance 后销毁
    /// @param from 被销毁 token 的地址
    /// @param amount 销毁数量（最小单位，18 decimals）
    function burn(address from, uint256 amount) external {
        if (msg.sender != from) {
            _spendAllowance(from, msg.sender, amount);
        }
        _burn(from, amount);
    }

    /*
    // 如果只允许持币者自己销毁，可改成：
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
    */
}
