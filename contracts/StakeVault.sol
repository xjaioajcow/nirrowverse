请在该文件中生成完整的 Solidity 合约代码，文件路径为 contracts/StakeVault.sol，内容要求如下：
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

    mapping(address => uint256) public tickets;
    address[] public holders;
    uint256[] public cumulativeEffectiveTickets;

    enum Tier { B0, S1, G2, D3 }

    constructor(address _lotto) {
        lotto = IERC20(_lotto);
    }

    function deposit(uint256 amount) external {
        require(amount % ENTRY_UNIT == 0, "Must be multiple of ENTRY_UNIT");
        uint256 numTickets = amount / ENTRY_UNIT;

        bool ok = lotto.transferFrom(msg.sender, address(this), amount);
        require(ok, "Transfer failed");

        tickets[msg.sender] += numTickets;
        uint256 userEff = getEffectiveTickets(tickets[msg.sender]);

        if (tickets[msg.sender] == numTickets) {
            holders.push(msg.sender);
            if (cumulativeEffectiveTickets.length == 0) {
                cumulativeEffectiveTickets.push(userEff);
            } else {
                uint256 prev = cumulativeEffectiveTickets[cumulativeEffectiveTickets.length - 1];
                cumulativeEffectiveTickets.push(prev + userEff);
            }
        } else {
            uint256 oldEff = getEffectiveTickets(tickets[msg.sender] - numTickets);
            int256 diff = int256(userEff) - int256(oldEff);
            uint256 idx = 0;
            for (uint256 i = 0; i < holders.length; i++) {
                if (holders[i] == msg.sender) {
                    idx = i;
                    break;
                }
            }
            for (uint256 j = idx; j < cumulativeEffectiveTickets.length; j++) {
                if (diff > 0) {
                    cumulativeEffectiveTickets[j] += uint256(diff);
                } else {
                    cumulativeEffectiveTickets[j] -= uint256(-diff);
                }
            }
        }
    }

    function withdraw(uint256 numTickets) external {
        require(numTickets > 0, "Num > 0");
        require(tickets[msg.sender] >= numTickets, "Not enough tickets");

        uint256 oldEff = getEffectiveTickets(tickets[msg.sender]);
        uint256 newCount = tickets[msg.sender] - numTickets;
        uint256 newEff = getEffectiveTickets(newCount);
        int256 diff = int256(newEff) - int256(oldEff);

        tickets[msg.sender] = newCount;

        uint256 idx = 0;
        for (uint256 i = 0; i < holders.length; i++) {
            if (holders[i] == msg.sender) {
                idx = i;
                break;
            }
        }
        for (uint256 j = idx; j < cumulativeEffectiveTickets.length; j++) {
            if (diff > 0) {
                cumulativeEffectiveTickets[j] += uint256(diff);
            } else {
                cumulativeEffectiveTickets[j] -= uint256(-diff);
            }
        }

        IELotto(address(lotto)).burn(address(this), numTickets * ENTRY_UNIT);
    }

    function getTier(uint256 userTickets) public pure returns (Tier) {
        if (userTickets >= 100) {
            return Tier.D3;
        } else if (userTickets >= 50) {
            return Tier.G2;
        } else if (userTickets >= 10) {
            return Tier.S1;
        } else {
            return Tier.B0;
        }
    }

    function getEffectiveTickets(uint256 userTickets) public pure returns (uint256) {
        Tier t = getTier(userTickets);
        if (t == Tier.B0) {
            return userTickets * 1;
        } else if (t == Tier.S1) {
            return (userTickets * 12) / 10;
        } else if (t == Tier.G2) {
            return (userTickets * 15) / 10;
        } else {
            return userTickets * 2;
        }
    }

    function totalEffectiveTickets() external view returns (uint256) {
        if (cumulativeEffectiveTickets.length == 0) return 0;
        return cumulativeEffectiveTickets[cumulativeEffectiveTickets.length - 1];
    }

    function findWinner(uint256 r) external view returns (address) {
        require(cumulativeEffectiveTickets.length > 0, "No tickets");
        uint256 left = 0;
        uint256 right = cumulativeEffectiveTickets.length - 1;
        while (left < right) {
            uint256 mid = (left + right) / 2;
            if (r < cumulativeEffectiveTickets[mid]) {
                right = mid;
            } else {
                left = mid + 1;
            }
        }
        return holders[left];
    }
}
