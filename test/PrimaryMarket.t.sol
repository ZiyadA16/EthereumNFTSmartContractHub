// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;


import "../lib/forge-std/src/Test.sol";
import "../src/contracts/PurchaseToken.sol";
import "../src/interfaces/ITicketNFT.sol";
import "../src/contracts/PrimaryMarket.sol";

contract PrimaryMarketTest is Test{
    PrimaryMarket public primaryMarket;
    PurchaseToken public purchaseToken;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");

    function setUp() public {
        purchaseToken = new PurchaseToken();
        primaryMarket = new PrimaryMarket(purchaseToken);

        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");

        payable(alice).transfer(1e18);
        payable(bob).transfer(2e18);
    }

    function testCreateNewEvent() external {
        vm.startPrank(charlie);
        ITicketNFT ticketNFT = primaryMarket.createNewEvent("Test Event", 1e18, 100);
        assertEq(ticketNFT.creator(), charlie);
        uint256 price = primaryMarket.getPrice(address(ticketNFT));
        assertEq(price, 1e18);
        uint256 maxTickets = primaryMarket.getMaximumNumberOfTickets(address(ticketNFT));
        assertEq(maxTickets, 100);
        uint256 ticketsSold = primaryMarket.getTicketsSold(address(ticketNFT));
        assertEq(ticketsSold, 0);
        vm.stopPrank();
    }

    function testPurchase() external {
        // Setup and create event
        vm.startPrank(charlie);
        ITicketNFT ticketNFT = primaryMarket.createNewEvent("Test Event", 1e18, 100);
        vm.stopPrank();

        vm.startPrank(alice);
        purchaseToken.mint{value: 1e18}();
        purchaseToken.approve(address(primaryMarket), 1e18);
        uint256 ticketId = primaryMarket.purchase(address(ticketNFT), "Alice");
        assertEq(ticketNFT.balanceOf(alice), 1);
        assertEq(ticketNFT.holderOf(ticketId), alice);
        assertEq(ticketNFT.holderNameOf(ticketId), "Alice");
        uint256 ticketsSold = primaryMarket.getTicketsSold(address(ticketNFT));
        assertEq(ticketsSold, 1);
        vm.stopPrank();
    }

    function testGetPrice() external {
        // Setup and create event
        vm.startPrank(charlie);
        ITicketNFT ticketNFT = primaryMarket.createNewEvent("Test Event", 1e18, 100);
        vm.stopPrank();

        uint256 price = primaryMarket.getPrice(address(ticketNFT));
        assertEq(price, 1e18);
    }
}   