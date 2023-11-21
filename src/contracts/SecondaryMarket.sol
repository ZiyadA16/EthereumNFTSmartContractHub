// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../interfaces/ISecondaryMarket.sol";
import "../interfaces/IERC20.sol";
import "./TicketNFT.sol"; // Import the NFT contract
import "./PurchaseToken.sol";



contract SecondaryMarket is ISecondaryMarket {
IERC20 public purchaseToken;

    
    struct ListingOfTickets {
        address seller;
        uint256 price;
        bool isListed;
    }

    struct Bid {
        address bidder;
        uint256 amount;
        string name;
    }

    mapping (address => mapping (uint256 => Bid)) private highestBids;
    mapping (address => ListingOfTickets) public TicketList;

    // Constructor
    constructor(PurchaseToken _purchaseToken) {
        purchaseToken = IERC20(address(_purchaseToken));
    }


    function listTicket(
        address ticketCollection,
        uint256 ticketID,
        uint256 price

    )  external {
    
        if(ITicketNFT(ticketCollection).holderOf(ticketID) != msg.sender) {
    revert("Only ticket owner can list");
    }

        if(ITicketNFT(ticketCollection).isExpiredOrUsed(ticketID) == true) {
            revert("Cannot list expired or used ticket");
    }

        ITicketNFT(ticketCollection).transferFrom(msg.sender, address(this), ticketID);
        ITicketNFT(ticketCollection).approve(address(this), ticketID);
        highestBids[ticketCollection][ticketID] = Bid({
            bidder: address(0),
            amount: price,
            name: ""
        });

        TicketList[ticketCollection] = ListingOfTickets({
            seller: msg.sender,
            price: price,
            isListed: true
        });

        emit Listing(msg.sender, ticketCollection, ticketID, price);
    }


    function submitBid(
        address ticketCollection,
        uint256 ticketID,
        uint256 bidAmount,
        string calldata name
    ) external override {

        ListingOfTickets storage listing = TicketList[ticketCollection];    
        if(bidAmount <= highestBids[ticketCollection][ticketID].amount) {
            revert("The bid must be higher than the current highest bid!");
        }

        if(!listing.isListed) {
            revert("The ticket is not listed.");
        }

        
        // Refund previous bidder who was highest bidder   
        Bid memory currentTopBid = highestBids[ticketCollection][ticketID];
        if (currentTopBid.amount > 0 && currentTopBid.bidder != address(0)) {
            purchaseToken.transfer(currentTopBid.bidder, currentTopBid.amount);
        }
        // Transfer the new bid amount to the contract      
        purchaseToken.transferFrom(msg.sender, address(this), bidAmount);
        purchaseToken.approve(address(this), bidAmount);
    
        // Update the highest bid       
        highestBids[ticketCollection][ticketID] = Bid(msg.sender, bidAmount, name);
 
        // Emit an event for the new highest bid       
        emit BidSubmitted(msg.sender, ticketCollection, ticketID, bidAmount, name);
    }


    function acceptBid(address ticketCollection, uint256 ticketID) external override {
 
        ListingOfTickets memory listing = TicketList[ticketCollection];
        require(listing.seller == msg.sender, "Only the seller can accept the bid");
        Bid memory bid = highestBids[ticketCollection][ticketID];
         // Calculate and transfer the fees
        uint256 fee = (bid.amount * 5) / 100;
        purchaseToken.transfer(ITicketNFT(ticketCollection).creator(), fee);
        // Transfer the funds to the seller minus the fee
        purchaseToken.transfer(listing.seller, bid.amount - fee);
        // Transfer the ticket to the winning bidder
        ITicketNFT(ticketCollection).updateHolderName(ticketID, bid.name);
        ITicketNFT(ticketCollection).transferFrom(address(this), bid.bidder, ticketID);
        emit BidAccepted(bid.bidder, ticketCollection, ticketID, bid.amount, "");
        // Clear listing and bid
        delete highestBids[ticketCollection][ticketID];
    }
 

    function delistTicket(address ticketCollection, uint256 ticketID) external override {
        ListingOfTickets storage listing = TicketList[ticketCollection];
        require(msg.sender == listing.seller, "Only lister can delist");

        ITicketNFT(ticketCollection).transferFrom(address(this), msg.sender, ticketID);
        listing.isListed = false;
        emit Delisting(ticketCollection, ticketID);
    }

      // Getter functions for the nested mappings
    function getListing(address ticketCollection) external view returns (ListingOfTickets memory) {
        return TicketList[ticketCollection];
    }

    function getHighestBid(address ticketCollection, uint256 ticketID) external view override returns (uint256) {
        return highestBids[ticketCollection][ticketID].amount;
    }

    function getHighestBidder(address ticketCollection, uint256 ticketID) external view override returns (address) {
        return highestBids[ticketCollection][ticketID].bidder;
    }
}