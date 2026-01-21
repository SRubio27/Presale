// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {PresaleTestBase} from "test/helpers/PresaleTestBase.t.sol";
import {IAggregator} from "src/interfaces/IAggregator.sol";
import {console} from "forge-std/console.sol";

contract Presale is PresaleTestBase {
    function testBuyWithEther_RevertIfBuyerIsBlackListed() public {
        vm.startPrank(owner);
        presale.blackListUser(buyer);
        vm.stopPrank();
        vm.startPrank(buyer);

        vm.expectRevert("USER_IS_BLACKLISTED");
        presale.buyWithEther{value: 1 ether}();

        vm.stopPrank();
    }

    function testBuyWithEtherReverIfMaxSupplyExceeded() public {
        vm.startPrank(buyer);
        (, int256 price, , , ) = IAggregator(oracleEthUsd).latestRoundData();
        uint256 ethUsdValue = (uint256(price) * (10 ** 10)) / 1e18; // 18 decimals

        uint256 ethAmountToBuy_ = (maxSellingAmount *
            phases[presale.currentPhase()][1]) / (1e6 * ethUsdValue);

        console.log("CALCULATED_AMOUNT_TO_BUY", ethAmountToBuy_);
        vm.expectRevert("MAX_SELLING_AMOUNT_EXCEEDED");
        presale.buyWithEther{value: ethAmountToBuy_ + 10 ether}();
        vm.stopPrank();
    }

    function testBuyWithEtherRevertIfPresaleFinished() public {
        vm.startPrank(buyer);
        uint256 amountToBuy_ = 1 * 1e16 wei; // 0.01 ether

        vm.warp(endingTime + 1 days);
        vm.expectRevert("PRESALE_IS_FINISHED");
        presale.buyWithEther{value: amountToBuy_}();
        vm.stopPrank();
    }

    function testBuyWithEtherRevertIfPresaleNotStarted() public {
        vm.startPrank(buyer);
        uint256 amountToBuy_ = 1 * 1e16 wei; // 0.01 ether

        vm.warp(startTime - 1 days);
        vm.expectRevert("PRESALE_HAS_NOT_START_YET");
        presale.buyWithEther{value: amountToBuy_}();
        vm.stopPrank();
    }

    function testBuyWithEtherCorrectly() public {
        vm.startPrank(buyer);
        uint256 amountToBuy_ = 1 * 1e16 wei; // 0.01 ether

        (, int256 price, , , ) = IAggregator(oracleEthUsd).latestRoundData();
        uint256 usdValue = (amountToBuy_ * (uint256(price) * (10 ** 10))) /
            1e18; // 18 decimals

        uint256 expectedTokens = (usdValue * 1e6) /
            phases[presale.currentPhase()][1];
        uint256 userTokensBefore_ = presale.userTokensBalance(buyer);
        uint256 totalTokensSoldBefore_ = presale.totalSold();
        vm.expectCall(fundsReceiver, amountToBuy_, "");
        presale.buyWithEther{value: amountToBuy_}();

        uint256 userTokensAfter_ = presale.userTokensBalance(buyer);
        uint256 totalTokensSoldAfter_ = presale.totalSold();

        assertEq(
            totalTokensSoldAfter_ - totalTokensSoldBefore_,
            expectedTokens
        );
        assertEq(userTokensAfter_ - userTokensBefore_, expectedTokens);

        vm.stopPrank();
    }
}
