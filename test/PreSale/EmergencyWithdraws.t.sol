// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {PresaleTestBase} from "test/helpers/PresaleTestBase.t.sol";

/*
 forge coverage --fork-url https://1rpc.io/arb
 forge test -vvvv --fork-url https://1rpc.io/arb --match-test
*/
contract EmergencyWithdraws is PresaleTestBase {
    using SafeERC20 for IERC20;

    function testEmergencyWithdraws_RevertIfNotOwner() public {
        vm.startPrank(buyer);
        uint256 amount = 100 * 1e6;
        IERC20(usdcAddress).safeTransfer(address(presale), amount);

        vm.expectRevert();
        presale.emergencyERC20Withdraw(usdcAddress, amount);

        vm.expectRevert();
        presale.emergencyEthWithdraw();

        vm.stopPrank();
    }

    function testEmergencyTokenWithdraw_WorksCorrectly() public {
        vm.startPrank(owner);
        uint256 amount = 100 * 1e6;
        IERC20(usdcAddress).safeTransfer(address(presale), amount);

        uint256 expectedAmountToWithdraw_ = IERC20(usdcAddress).balanceOf(
            address(presale)
        );

        presale.emergencyERC20Withdraw(usdcAddress, amount);

        uint256 endTokenAmount_ = IERC20(usdcAddress).balanceOf(
            address(presale)
        );

        assertEq(endTokenAmount_, 0);
        assertEq(expectedAmountToWithdraw_, amount);

        vm.stopPrank();
    }

    function testEmergencyEthWithdraw_WorksCorrectly() public {
        vm.startPrank(owner);
        uint256 amount = 1 ether;
        (bool success, ) = address(presale).call{value: amount}("");
        require(success, "FAILED_TRANSFERADD_ETH");
        uint256 amountInContract_ = address(presale).balance;
        assertEq(amountInContract_, amount);
        // uint256 expectedAmountToWithdraw_ = address(presale).balance;
        presale.emergencyEthWithdraw();

        uint256 endEthAmount_ = address(presale).balance;

        assertEq(endEthAmount_, 0);

        vm.stopPrank();
    }
}
