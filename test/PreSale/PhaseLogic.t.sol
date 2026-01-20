// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IAggregator} from "src/interfaces/IAggregator.sol";
import {PresaleTestBase} from "test/helpers/PresaleTestBase.t.sol";

/*
 forge coverage --fork-url https://1rpc.io/arb
 forge test -vvvv --fork-url https://1rpc.io/arb --match-test
*/
contract PhaseLogic is PresaleTestBase {
    function testPhase_IncreaseWhenSupplyExceeded() public {
        vm.startPrank(buyer);
        uint256 phaseBefore_ = presale.currentPhase();
        // tokenAmount = (amount * (10 ** 18 - usdcAddress.decimals()) * 1e6) / price
        // amount = (price * tokenAmount) / (10 ** 18 - usdcAddress.decimals()) * 1e6

        uint256 amountToChangePhase = ((phases[phaseBefore_][1] *
            phases[phaseBefore_][0]) /
            (10 ** 18 - ERC20(usdcAddress).decimals())) * 1e6;

        presale.buyWithStableCoins(usdcAddress, amountToChangePhase);

        uint256 phaseAfter_ = presale.currentPhase();

        assertEq(phaseAfter_ - phaseBefore_, 1);

        vm.expectRevert();
    }
}
