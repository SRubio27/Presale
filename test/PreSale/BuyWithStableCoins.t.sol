// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {PresaleTestBase} from "test/helpers/PresaleTestBase.t.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {console} from "forge-std/console.sol";

contract buyWithStableCoinsTest is PresaleTestBase {
    function testReverIfMaxSupplyExceeded() public {
        vm.startPrank(buyer);
        uint256 amountIn_ = maxSellingAmount + 10 * 1e6;
        vm.expectRevert("MAX_SELLING_AMOUNT_EXCEEDED");
        presale.buyWithStableCoins(usdcAddress, amountIn_);
        vm.stopPrank();
    }

    function testRevertIfPresaleFinished() public {
        vm.startPrank(buyer);
        vm.warp(endingTime + 1 days);
        vm.expectRevert("PRESALE_IS_FINISHED");
        presale.buyWithStableCoins(usdcAddress, 1e6);
        vm.stopPrank();
    }

    function testRevertIfPresaleNotStarted() public {
        vm.startPrank(buyer);
        vm.warp(startTime - 1 days);
        vm.expectRevert("PRESALE_HAS_NOT_START_YET");
        presale.buyWithStableCoins(usdcAddress, 1e6);
        vm.stopPrank();
    }

    function testRevertIfIncorrectToken() public {
        vm.startPrank(buyer);
        vm.expectRevert("INCORRECT_TOKEN");
        presale.buyWithStableCoins(vm.addr(4), 1e6);
        vm.stopPrank();
    }

    function testBuyWithStableCoinsCorrectly() public {
        vm.startPrank(buyer);
        uint256 amountToBuy_ = 10e6;
        IERC20(usdcAddress).approve(address(presale), amountToBuy_);

        uint256 totalTokensBefore_ = presale.totalSold();
        uint256 userTokensBefore_ = presale.userTokensBalance(buyer);
        uint256 usdcReceiverBefore_ = IERC20(usdcAddress).balanceOf(
            fundsReceiver
        );
        uint256 usdcBuyerBefore_ = IERC20(usdcAddress).balanceOf(buyer);

        uint256 expectedTokens = (amountToBuy_ *
            10 ** (18 - ERC20(usdcAddress).decimals()) *
            1e6) / phases[presale.currentPhase()][1];

        presale.buyWithStableCoins(usdcAddress, amountToBuy_);
        uint256 totalTokensAfter_ = presale.totalSold();
        uint256 userTokensAfter_ = presale.userTokensBalance(buyer);

        uint256 usdcReceiverAfter_ = IERC20(usdcAddress).balanceOf(
            fundsReceiver
        );
        uint256 usdcBuyerAfter_ = IERC20(usdcAddress).balanceOf(buyer);

        assertEq(userTokensAfter_ - userTokensBefore_, expectedTokens);
        assertEq(totalTokensAfter_ - totalTokensBefore_, expectedTokens);
        assertEq(
            usdcBuyerBefore_ - usdcBuyerAfter_,
            usdcReceiverAfter_ - usdcReceiverBefore_
        );
        vm.stopPrank();
    }
}
