// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IAggregator} from "./interfaces/IAggregator.sol";
import {MockToken} from "./MockToken.sol";

contract Presale is Ownable {
    using SafeERC20 for IERC20;

    MockToken public mockToken;
    address public usdtAddress;
    address public usdcAddress;
    address public saleTokenAddress;
    address public fundsRecieverAddress;
    address public dataFeedAddress;
    uint256 public maxSellingAmount;
    uint256 public startingTime;
    uint256 public endingTime;
    uint256[][3] public phases;
    //            supply |   price |   time
    // phase 1 ->  []    |    []   |    []
    // phase 2 ->  []    |    []   |    []
    // phase 3 ->  []    |    []   |    []

    uint256 public totalSold;
    uint256 public currentPhase = 0;
    mapping(address => bool) public blacklist;
    mapping(address => uint256) public userTokensBalance;

    // Events
    event ContractDeployed(
        address owner,
        address fundsReciever,
        uint256 maxSellingAmount,
        uint256[][3] pases
    );

    // Modifiers
    modifier userIsNotBlackListed(address user_) {
        require(blacklist[user_] == false, "USER_IS_IN_BLACKLIST");
        _;
    }
    modifier userIsBlackListed(address user_) {
        require(blacklist[user_] == true, "USER_IS_IN_BLACKLIST");
        _;
    }

    constructor(
        address usdtAddress_,
        address usdcAddress_,
        // address saleTokenAddress_,
        address fundsRecieverAddress_,
        address dataFeedAddress_,
        uint256 maxSellingAmount_,
        uint256 startingTime_,
        uint256 endingTime_,
        uint256 initialMintTokenAmount_,
        string memory tokenName_,
        string memory tokenSymbol_,
        uint256[][3] memory phases_
    ) Ownable(msg.sender) {
        require(endingTime_ > startingTime_, "PRESALE_CANNOT_END_BEFORE_START");
        mockToken = new MockToken(
            initialMintTokenAmount_,
            tokenName_,
            tokenSymbol_
        );
        usdtAddress = usdtAddress_;
        usdcAddress = usdcAddress_;
        saleTokenAddress = address(mockToken);
        fundsRecieverAddress = fundsRecieverAddress_;
        dataFeedAddress = dataFeedAddress_; // 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612 (Oracle of eth price in USD)
        maxSellingAmount = maxSellingAmount_;
        startingTime = startingTime_;
        endingTime = endingTime_;
        phases = phases_;

        // IERC20(saleTokenAddress).safeTransferFrom(
        //     msg.sender,
        //     address(this),
        //     maxSellingAmount
        // );

        emit ContractDeployed(
            msg.sender,
            fundsRecieverAddress,
            maxSellingAmount,
            phases
        );
    }

    /**
     * Used to buy tokens with stable tokens
     * @param tokenUsedToBuy_ address of stable token used to buy
     * @param amount_ amount of tokens sended
     */
    function buyWithStableCoins(
        address tokenUsedToBuy_,
        uint256 amount_
    ) external userIsNotBlackListed(msg.sender) {
        require(block.timestamp >= startingTime, "PRESALE_HAS_NOT_START_YET");
        require(block.timestamp <= endingTime, "PRESALE_IS_FINISHED");
        require(
            tokenUsedToBuy_ == address(usdtAddress) ||
                tokenUsedToBuy_ == address(usdcAddress),
            "INCORRECT_TOKEN"
        );
        uint256 tokenAmountToReceive;

        if (ERC20(tokenUsedToBuy_).decimals() == 18)
            tokenAmountToReceive = (amount_ * 1e6) / phases[currentPhase][1];
        else
            tokenAmountToReceive =
                (amount_ *
                    10 ** (18 - ERC20(tokenUsedToBuy_).decimals()) *
                    1e6) /
                phases[currentPhase][1];

        checkCurrentPhase(tokenAmountToReceive);
        require(
            totalSold + tokenAmountToReceive <= maxSellingAmount,
            "MAX_SELLING_AMOUNT_EXCEEDED"
        );
        IERC20(tokenUsedToBuy_).safeTransferFrom(
            msg.sender,
            fundsRecieverAddress,
            amount_
        );

        userTokensBalance[msg.sender] += tokenAmountToReceive;

        totalSold += tokenAmountToReceive;
    }

    /**
     * Used for buy tokens with ether
     * @param to_ address to set the tokens
     */
    function buyWithEther(
        address to_
    ) external payable userIsNotBlackListed(to_) {
        require(block.timestamp >= startingTime, "PRESALE_HAS_NOT_START_YET");
        require(block.timestamp <= endingTime, "PRESALE_IS_FINISHED");

        uint256 tokenAmountToReceive;
        uint256 ethPrice = getEtherPrice();
        uint256 usdValue = (ethPrice * msg.value) / 1e18;

        tokenAmountToReceive = (usdValue * 1e6) / phases[currentPhase][1];

        checkCurrentPhase(tokenAmountToReceive);
        require(
            totalSold + tokenAmountToReceive <= maxSellingAmount,
            "MAX_SELLING_AMOUNT_EXCEEDED"
        );
        (bool success, ) = fundsRecieverAddress.call{value: msg.value}("");
        require(success, "TRANSFER_FAILED");
        userTokensBalance[msg.sender] += tokenAmountToReceive;

        totalSold += tokenAmountToReceive;
    }

    /**
     * Used to claim pre sale tokens once it end
     */
    function claim() external {
        require(block.timestamp > endingTime, "PRESLAE_NOT_ENDED");

        uint256 amountToClaim = userTokensBalance[msg.sender];

        require(amountToClaim > 0, "NO_TOKENS_TO_CLAIM");

        delete userTokensBalance[msg.sender];

        IERC20(saleTokenAddress).safeTransfer(msg.sender, amountToClaim);
    }

    /**
     * Used to get the USD price of ETH with an Chainlink oracle
     */
    function getEtherPrice() internal view returns (uint256) {
        (, int256 price, , , ) = IAggregator(dataFeedAddress).latestRoundData();

        int256 finalPrice = price * (10 ** 10); // Añadimos 10 ceros porque el oraculo devuelve el precio con 8 decimales, nosotros calculamos con 18

        return uint256(finalPrice);
    }

    /**
     * Used internly check current phase(used in buys to check)
     * @param amount_ amount to calculate the current phase
     */
    function checkCurrentPhase(
        uint256 amount_
    ) private returns (uint256 phase) {
        if (
            (totalSold + amount_ > phases[currentPhase][0] ||
                block.timestamp >= phases[currentPhase][2]) && phase < 3
        ) currentPhase++;

        phase = currentPhase;
    }

    /**
     * Used to set users in blacklist
     * @param user_ the address of the user to add in the blacklist
     */
    function setUserInBlackList(
        address user_
    ) external onlyOwner userIsBlackListed(user_) {
        blacklist[user_] = true;
    }

    /**
     * Used to remove users from the blacklist
     * @param user_ the address of the user to remove in the blacklist
     */
    function removeUserInBlacklist(
        address user_
    ) external onlyOwner userIsNotBlackListed(user_) {
        blacklist[user_] = false;
    }

    /**
     * Used to withdraw  ERC20 tokens in a emergency
     * @param tokenAddress_ the address of the token to withderaw,
     * @param amount_ the amount of tokens to withderaw
     */
    function emergencyERC20Withdraw(
        address tokenAddress_,
        uint256 amount_
    ) external onlyOwner {
        IERC20(tokenAddress_).safeTransfer(msg.sender, amount_);
    }

    /**
     * Used to remove the ethers of the contract in emergencies (this contract should not contain ether)
     */
    function emergencyETHWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success = true, "RANSACTION_FAILED");
    }
}
