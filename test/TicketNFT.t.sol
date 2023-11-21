// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../lib/forge-std/src/Test.sol";
import "../src/contracts/TicketNFT.sol";

contract TicketNFTTest is Test {
    TicketNFT private ticketNFT;
    address private creator;
    address private primaryMarket;
    string private eventName = "Sample Event";
    uint256 private maxTickets = 100;
    
    function setUp() public {
        creator = address(this); // assuming the test contract itself as the creator
        primaryMarket = makeAddr("primaryMarket"); // creating a mock primary market address
        ticketNFT = new TicketNFT(eventName, maxTickets, creator, primaryMarket);
    }

    function testConstructorAndInitialState() public {
        assertEq(ticketNFT.eventName(), eventName);
        assertEq(ticketNFT.creator(), creator);
        assertEq(ticketNFT.maxNumberOfTickets(), maxTickets);
    }

    function testMintFunction() public {
        address holder = makeAddr("holder");
        string memory holderName = "Alice";
        uint256 ticketId = ticketNFT.mint(holder, holderName);

        assertEq(ticketNFT.balanceOf(holder), 1);
        assertEq(ticketNFT.holderOf(ticketId), holder);
        assertEq(ticketNFT.holderNameOf(ticketId), holderName);
    }

    function testBalanceOfFunction() public {
        address holder = makeAddr("holder");
        ticketNFT.mint(holder, "Alice");
        ticketNFT.mint(holder, "Bob");

        assertEq(ticketNFT.balanceOf(holder), 2);
    }

    function testHolderOfFunction() public {
        address holder = makeAddr("holder");
        uint256 ticketId = ticketNFT.mint(holder, "Alice");

        assertEq(ticketNFT.holderOf(ticketId), holder);
    }

    function testTransferFromFunction() public {
        address holder = makeAddr("holder");
        address newHolder = makeAddr("newHolder");
        uint256 ticketId = ticketNFT.mint(holder, "Alice");

        vm.prank(holder);
        ticketNFT.approve(newHolder, ticketId);
        vm.prank(newHolder);
        ticketNFT.transferFrom(holder, newHolder, ticketId);

        assertEq(ticketNFT.holderOf(ticketId), newHolder);
        assertEq(ticketNFT.balanceOf(holder), 0);
        assertEq(ticketNFT.balanceOf(newHolder), 1);
    }

    function testApproveAndGetApprovedFunctions() public {
        address holder = makeAddr("holder");
        address approved = makeAddr("approved");
        uint256 ticketId = ticketNFT.mint(holder, "Alice");

        vm.prank(holder);
        ticketNFT.approve(approved, ticketId);

        assertEq(ticketNFT.getApproved(ticketId), approved);
    }

    function testUpdateHolderNameFunction() public {
        address holder = makeAddr("holder");
        uint256 ticketId = ticketNFT.mint(holder, "Alice");

        string memory newName = "Bob";
        vm.prank(holder);
        ticketNFT.updateHolderName(ticketId, newName);

        assertEq(ticketNFT.holderNameOf(ticketId), newName);
    }

    function testSetUsedFunction() public {
        uint256 ticketId = ticketNFT.mint(address(this), "Creator");

        vm.prank(creator);
        ticketNFT.setUsed(ticketId);

        assertTrue(ticketNFT.isExpiredOrUsed(ticketId));
    }

    function testIsExpiredOrUsedFunction() public {
        uint256 ticketId = ticketNFT.mint(address(this), "Creator");

        assertFalse(ticketNFT.isExpiredOrUsed(ticketId));

        vm.warp(block.timestamp + 11 days); // advance time to simulate expiration
        assertTrue(ticketNFT.isExpiredOrUsed(ticketId));
    }

}