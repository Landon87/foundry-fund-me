//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant STARTING_BALANCE = 100 ether;
    uint256 constant SEND_VALUE = 5 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    // function testWithdrawUpdatesFundedDataStructure() public {
    //     vm.deal(USER, STARTING_BALANCE);
    //     fundMe.fund{value: SEND_VALUE}();
    //     fundMe.withdraw();
    //     uint256 amountFunded = fundMe.getaddressToAmountFunded(USER);
    //     assertEq(amountFunded, 0, "Amount funded is not 0");
    // }

    function testMinDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), SEND_VALUE, "Minimum USD is not 5");
    }

    function testMsgSenderIsOwner() public {
        console.log("Sender: ", msg.sender);
        assertEq(fundMe.getOwner(), msg.sender, "Owner is not the sender");
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4, "Version is not 4");
    }

    function testFundFailsWithLessThanMin() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundSucceedsWithMin() public {
        fundMe.fund{value: SEND_VALUE}();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER);
        vm.deal(USER, STARTING_BALANCE);
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getaddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE, "Amount funded is not 5 ETH");
    }

    function testAddsFunderToArrayofFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER, "Funders array is not 0");
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithDrawWithSingleFunder() public funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundeMeBalance = address(fundMe).balance;
        //Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingOwnerBalance + startingFundeMeBalance,
            endingOwnerBalance,
            "Owner balance is not correct"
        );
    }

    function testWithdrawFromMultipleFunders() public {
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank(USER);
            // fundMe.fund{value: SEND_VALUE}();

            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundeMeBalance = address(fundMe).balance;
        //Act
        uint256 gasStart = gasleft();

        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;

        console.log(gasUsed);

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);

        assertEq(
            startingOwnerBalance + startingFundeMeBalance,
            endingOwnerBalance,
            "Owner balance is not correct"
        );
        // console.log(testWithdrawFromMultipleFunders);
    }
}
