// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../lib/forge-std/src/Test.sol";
import "../src/contracts/PurchaseToken.sol";
import "../src/contracts/TicketNFT.sol";
import "../src/contracts/SecondaryMarket.sol";
import "../src/interfaces/ITicketNFT.sol";
import "../src/interfaces/ISecondaryMarket.sol";
import "../src/contracts/PrimaryMarket.sol";


contract SecondaryMarketTest is Test {
    SecondaryMarket public secondaryMarket;
    PurchaseToken public purchaseToken;
    PrimaryMarket public primaryMarket;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");
    uint256 ticketID;

    function setUp() public {
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(charlie, "Charlie");

        vm.deal(charlie, 1e18); // Allocate 1 ETH to Charlie
        vm.deal(alice, 1e18);   // Allocate 1 ETH to Alice
        vm.deal(bob, 2e18);     // Allocate 2 ETH to Bob

        purchaseToken = new PurchaseToken();
        primaryMarket = new PrimaryMarket(purchaseToken);
        secondaryMarket = new SecondaryMarket(purchaseToken);

        ITicketNFT ticketNFT = primaryMarket.createNewEvent("Test Event", 1e18, 100);

        vm.startPrank(alice);
        purchaseToken.mint{value: 1e18}();
        purchaseToken.approve(address(secondaryMarket), 1e18);
        ticketID = ticketNFT.mint(alice, "Alice");
        ticketNFT.approve(address(secondaryMarket), ticketID);
        vm.stopPrank();
    }

    function testListTicket() public {
        vm.startPrank(charlie);
         ITicketNFT ticketNFT = primaryMarket.createNewEvent("Test Event", 1e18, 100);
        secondaryMarket.listTicket(address(ticketNFT), ticketID, 1e18);

        SecondaryMarket.ListingOfTickets memory listing = secondaryMarket.getListing(address(ticketNFT));
        assertEq(listing.seller, charlie);
        assertEq(listing.price, 1e18);
        assertTrue(listing.isListed);
    }

    // function testSubmitBid() public {
    //     testListTicket(); // Ensure ticket is listed first

    //     vm.prank(bob);
    //     ITicketNFT ticketNFT = primaryMarket.createNewEvent("Test Event", 1e18, 100);
    //     secondaryMarket.submitBid(address(ticketNFT), ticketID, 1.5e18, "Bob");

    //     SecondaryMarket.Bid memory highestBid = secondaryMarket.getHighestBid(address(ticketNFT), ticketID);
    //     assertEq(highestBid.bidder, bob);
    //     assertEq(highestBid.amount, 1.5e18);
    // }

}