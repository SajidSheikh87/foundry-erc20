// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {OurToken} from "../src/OurToken.sol";

contract OurTokenTest is Test {
    OurToken public ourToken;
    DeployOurToken public deployer;

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");
    address charlie = makeAddr("charlie");

    uint256 public constant STARTING_BALANCE = 100 ether;
    uint256 public constant APPROVAL_AMOUNT = 1000;

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();

        vm.prank(msg.sender);
        ourToken.transfer(bob, STARTING_BALANCE);
    }

    function testBobBalance() public view {
        assertEq(STARTING_BALANCE, ourToken.balanceOf(bob));
    }

    function testAllowancesWorks() public {
        uint256 initialAllowance = 1000;

        // Bob approves Alice to spend tokens on his behalf
        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);

        uint256 transferAmount = 500;

        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount);

        assertEq(ourToken.balanceOf(alice), transferAmount);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
    }

    // Test transferring tokens directly
    function testTransfer() public {
        uint256 transferAmount = 10 ether;

        // Bob transfers tokens to Charlie
        vm.prank(bob);
        ourToken.transfer(charlie, transferAmount);

        // Check the balances
        assertEq(ourToken.balanceOf(charlie), transferAmount);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
    }

    // Test transfer fails if allowance is not enough
    function testTransferFromFailsIfAllowanceNotEnough() public {
        uint256 transferAmount = 100;

        // Bob approves Alice for a smaller amount
        vm.prank(bob);
        ourToken.approve(alice, APPROVAL_AMOUNT - transferAmount);

        // Alice tries to transfer more than allowed
        vm.prank(alice);
        vm.expectRevert();
        ourToken.transferFrom(bob, charlie, APPROVAL_AMOUNT);
    }

    // Test approval can be set to a higher value
    function testApprovalIncreases() public {
        uint256 newApprovalAmount = 2000;

        // Bob approves Alice
        vm.prank(bob);
        ourToken.approve(alice, APPROVAL_AMOUNT);

        // Bob approves Alice to spend more tokens
        vm.prank(bob);
        ourToken.approve(alice, newApprovalAmount);

        // Check the allowance
        assertEq(ourToken.allowance(bob, alice), newApprovalAmount);
    }

    // Test approval can be decreased
    function testApprovalDecreases() public {
        uint256 decreaseAmount = 500;

        // Bob approves Alice
        vm.prank(bob);
        ourToken.approve(alice, APPROVAL_AMOUNT);

        // Bob reduces the allowance
        vm.prank(bob);
        ourToken.approve(alice, APPROVAL_AMOUNT - decreaseAmount);

        // Check the updated allowance
        uint256 expectedAllowance = APPROVAL_AMOUNT - decreaseAmount;
        assertEq(ourToken.allowance(bob, alice), expectedAllowance);
    }
}
