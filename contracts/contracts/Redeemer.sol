// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Redeemer 合约需求：
///         1. 构造函数参数：
///            (address _llt, address _lotto, address _router, address _locker, address _pool, uint256 _unit)
///         2. 函数 swap(uint256 amt) 实现：
///            a) 用户先调用 IERC20(_llt).transferFrom(msg.sender, address(this), amt)；
///            b) 计算 uint256 sell = amt * 20 / 100，用 SafeERC20 批准并 swapExactTokensForTokens 到 HYPE，将所得 HYPE 发到 _pool 地址；
///            c) 计算 uint256 burnAmt = amt * 5 / 100，调用 IERC20Burnable(_llt).burn(burnAmt) 将 LLT 燃烧；
///            d) 计算 uint256 lockAmt = amt * 75 / 100，调用 IERC20(_llt).transfer(_locker, lockAmt) 将剩余的 LLT 转给 _locker；
///            e) 计算 uint256 lottoUser = (amt * 75 / 100) / _unit，调用 ILotto(_lotto).mint(msg.sender, lottoUser * _unit)；
///            f) 计算 uint256 lottoPool = (amt * 10 / 100) / _unit，调用 ILotto(_lotto).mint(_pool, lottoPool * _unit)；
///         3. 以上逻辑里要确保使用 SafeERC20 或 IERC20Burnable。
/// @dev Copilot/Codex，看到以上提示后，请在此处自动补全完整的 Redeemer.sol 源码，实现以上所有需求。
