// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IELotto {
    function burn(address from, uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract StakeVault is Ownable {
    IERC20 public lotto;
    uint256 public constant ENTRY_UNIT = 10000 * 10**18;

    mapping(address => uint256) public tickets;       // 用户持有票数（以 ENTRY_UNIT 为单位）
    mapping(address => uint256) public effectiveTickets; // 用户实际有效票数（乘以倍率后）
    address[] public holders;                         // 当前所有持票用户列表

    // 累积有效票数数组，用于二分搜索
    uint256[] public cumulativeEffectiveTickets;

    constructor(address _lottoToken) {
        require(_lottoToken != address(0), "Invalid Lotto token");
        lotto = IERC20(_lottoToken);
    }

    /// @notice 用户存入 amount 个 LOTTO，换算成 tickets 份额
    /// @param amount 存入的 LOTTO 数量（最小单位 18 decimals）
    function deposit(uint256 amount) external {
        require(amount >= ENTRY_UNIT, "Amount too small");
        uint256 numTickets = amount / ENTRY_UNIT; // 每 10000 个 LOTTO 算作 1 张票
        require(numTickets > 0, "No whole tickets");

        // 把 LOTTO 从用户转到本合约
        require(lotto.transferFrom(msg.sender, address(this), numTickets * ENTRY_UNIT), "Transfer failed");

        // 更新用户票数和有效票数（初始倍率 1）
        if (tickets[msg.sender] == 0) {
            holders.push(msg.sender);
        }
        tickets[msg.sender] += numTickets;
        effectiveTickets[msg.sender] = tickets[msg.sender]; // 假设初始 Tier 为 B0，无倍率

        // 重建累积有效票数数组
        _rebuildCumulative();
    }

    /// @notice 用户根据票数 tickets 张取回 LOTTO（burn 掉相应票数）
    /// @param numTickets 要取回的票数份额
    function withdraw(uint256 numTickets) external {
        require(numTickets > 0 && tickets[msg.sender] >= numTickets, "Invalid withdraw");
        tickets[msg.sender] -= numTickets;
        effectiveTickets[msg.sender] = tickets[msg.sender]; // 更新有效票数

        // 把对应数量的 LOTTO 从合约退还给用户
        uint256 returnAmount = numTickets * ENTRY_UNIT;
        lotto.transferFrom(address(this), msg.sender, returnAmount);

        _rebuildCumulative();
    }

    /// @notice 返回用户当前票数 Tier
    /// @param user 用户地址
    /// @return tier 票数等级：0 = B0, 1 = S1, 2 = G2, 3 = D3
    function getTier(address user) public view returns (uint8 tier) {
        uint256 t = tickets[user];
        if (t >= 100) return 3; // D3
        if (t >= 50) return 2;  // G2
        if (t >= 10) return 1;  // S1
        return 0;                // B0
    }

    /// @notice 返回用户的有效票数（含倍率）
    /// @param user 用户地址
    /// @return eff 有效票数 = t × multiplier
    function getEffectiveTickets(address user) public view returns (uint256 eff) {
        uint8 tier = getTier(user);
        uint256 base = tickets[user];
        if (tier == 1) return (base * 12) / 10;  // S1, ×1.2
        if (tier == 2) return (base * 15) / 10;  // G2, ×1.5
        if (tier == 3) return base * 2;         // D3, ×2
        return base;                            // B0, ×1
    }

    /// @notice 返回当前所有用户的总有效票数
    function totalEffectiveTickets() external view returns (uint256) {
        uint256 sum = 0;
        for (uint i = 0; i < holders.length; i++) {
            sum += getEffectiveTickets(holders[i]);
        }
        return sum;
    }

    /// @notice 从累积有效票数数组中根据伪随机数 r 找到中奖者地址
    /// @param r 取模 totalEffectiveTickets() 后的随机数
    function findWinner(uint256 r) external view returns (address) {
        require(holders.length > 0, "No holders");
        // 先构建一次累积数组（或在 deposit/withdraw 里实时 rebuild）
        uint256[] memory cum = new uint256[](holders.length);
        uint256 acc = 0;
        for (uint i = 0; i < holders.length; i++) {
            acc += getEffectiveTickets(holders[i]);
            cum[i] = acc;
        }
        // 二分搜索
        uint256 left = 0;
        uint256 right = cum.length - 1;
        while (left < right) {
            uint256 mid = (left + right) / 2;
            if (r < cum[mid]) {
                right = mid;
            } else {
                left = mid + 1;
            }
        }
        return holders[left];
    }

    /// @notice 内部函数：重建累积有效票数数组（供 deposit/withdraw 调用）
    function _rebuildCumulative() internal {
        delete cumulativeEffectiveTickets;
        uint256 acc = 0;
        for (uint i = 0; i < holders.length; i++) {
            uint256 eff = getEffectiveTickets(holders[i]);
            acc += eff;
            cumulativeEffectiveTickets.push(acc);
        }
    }
}
