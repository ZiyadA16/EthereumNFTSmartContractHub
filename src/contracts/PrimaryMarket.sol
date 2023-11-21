// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../interfaces/IERC20.sol";
import "./TicketNFT.sol"; // Import the NFT contract
import "../interfaces/IPrimaryMarket.sol";
import "./PurchaseToken.sol";

contract PrimaryMarket is IPrimaryMarket {
    IERC20 public paymentToken;

    constructor(PurchaseToken _paymentToken) {
        paymentToken = IERC20(address(_paymentToken));
    }

    // Struct to hold event details
    struct EventDetails {
        string eventName;
        uint256 price;
        uint256 maxNumberOfTickets;
        uint256 ticketsSold;
    }

    // Mapping from the ticket NFT contract address to its event details
    mapping(address => EventDetails) public eventDetails;
    // Mapping from the ticket NFT contract address to its creator's address
    mapping(address => address) public eventCreators;

    function createNewEvent(
        string memory eventName,
        uint256 price,
        uint256 maxNumberOfTickets
    ) external override returns (ITicketNFT ticketCollection) {
        TicketNFT newTicketNFT = new TicketNFT(eventName, maxNumberOfTickets, msg.sender, address(this));
        eventDetails[address(newTicketNFT)] = EventDetails({
            eventName: eventName,
            price: price,
            maxNumberOfTickets: maxNumberOfTickets,
            ticketsSold: 0
        });
        eventCreators[address(newTicketNFT)] = msg.sender;
        emit EventCreated(msg.sender, address(newTicketNFT), eventName, price, maxNumberOfTickets);
        return ITicketNFT(address(newTicketNFT));
    }

    function purchase(
        address ticketCollection,
        string memory holderName
    ) external override returns (uint256 id) {
        EventDetails storage details = eventDetails[ticketCollection];
        require(details.ticketsSold < details.maxNumberOfTickets, "All tickets sold out");

        uint256 ticketPrice = details.price;
        require(paymentToken.transferFrom(msg.sender, eventCreators[ticketCollection], ticketPrice), "Payment failed");

        TicketNFT nft = TicketNFT(ticketCollection);
        uint256 ticketId = nft.mint(msg.sender, holderName);
        details.ticketsSold += 1;

        emit Purchase(msg.sender, ticketCollection, ticketId, holderName);
        return ticketId;
    }

    function getPrice(
        address ticketCollection
    ) external view override returns (uint256 price) {
        return eventDetails[ticketCollection].price;
    }

    function getEventDetails(address ticketCollection) external view returns (EventDetails memory) {
    return eventDetails[ticketCollection];
}

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }


    function getMaximumNumberOfTickets(address ticketCollection) external view returns (uint256) {
    return eventDetails[ticketCollection].maxNumberOfTickets;
}

    function getTicketsSold(address ticketCollection) external view returns (uint256) {
    return eventDetails[ticketCollection].ticketsSold;
}

    function getEventName(address ticketCollection) external view returns (string memory) {
    return eventDetails[ticketCollection].eventName;
}

function mintTicket(address ticketNFTAddress, address holder, string memory holderName) public {
    ITicketNFT(ticketNFTAddress).mint(holder, holderName);
}
}