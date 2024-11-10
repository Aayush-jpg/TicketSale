// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TicketSale {

    address public owner;
    uint public ticketPrice;
    uint public totalTickets;
    uint public ticketsSold;

    mapping (uint => address) public ticketOwners;  // Maps ticket ID to owner address
    mapping (uint => address) public swapOffers;    // Maps ticket ID to offerer for swaps

    // Struct for resale offers with ticket ID, price, and the seller's address
    struct ResaleOffer {
        uint ticketId;
        uint price;
        address seller;
    }

    // Array of all resale offers
    ResaleOffer[] public resaleTickets;

    // Events for various actions
    event TicketPurchased(address indexed buyer, uint indexed ticketId);
    event TicketsSwapped(address indexed buyer1, uint indexed ticketId1, address indexed buyer2, uint ticketId2);
    event TicketResold(address indexed seller, address indexed buyer, uint indexed ticketId, uint price);

    // Constructor sets the initial ticket price and total number of tickets
    constructor(uint numTickets, uint price) {
        owner = msg.sender;
        totalTickets = numTickets;
        ticketPrice = price;
    }

    // Buy a ticket if conditions are met
    function buyTicket(uint ticketId) public payable {
        require(ticketId > 0 && ticketId <= totalTickets, "Invalid ticket ID.");
        require(ticketOwners[ticketId] == address(0), "Ticket already sold.");
        require(msg.value == ticketPrice, "Incorrect payment amount.");
        require(getTicketOf(msg.sender) == 0, "You can only buy one ticket.");

        ticketOwners[ticketId] = msg.sender;
        ticketsSold++;

        emit TicketPurchased(msg.sender, ticketId);
    }

    // Helper function to check if an address owns a ticket
    function getTicketOf(address person) public view returns (uint) {
        for (uint i = 1; i <= totalTickets; i++) {
            if (ticketOwners[i] == person) {
                return i;
            }
        }
        return 0; // Return 0 if no ticket owned
    }

    // Offer a ticket for swap
    function offerSwap(uint ticketId) public {
        require(ticketOwners[ticketId] == msg.sender, "You don't own this ticket.");
        swapOffers[ticketId] = msg.sender;
    }

    // Accept a swap offer for a ticket
    function acceptSwap(uint ticketId) public {
        uint userTicket = getTicketOf(msg.sender);
        require(userTicket != 0, "You need to own a ticket to swap.");
        require(swapOffers[ticketId] != address(0), "No swap offer for this ticket.");
        require(swapOffers[ticketId] != msg.sender, "Cannot accept your own swap offer.");

        address offerer = swapOffers[ticketId];
        uint offererTicket = ticketId;

        // Swap ownership of the two tickets
        ticketOwners[offererTicket] = msg.sender;
        ticketOwners[userTicket] = offerer;

        delete swapOffers[offererTicket];  // Remove the swap offer

        emit TicketsSwapped(offerer, offererTicket, msg.sender, userTicket);
    }

    // Offer a ticket for resale
    function resaleTicket(uint price) public {
        uint ticketId = getTicketOf(msg.sender);
        require(ticketId != 0, "You don't own a ticket to resell.");

        resaleTickets.push(ResaleOffer({
            ticketId: ticketId,
            price: price,
            seller: msg.sender
        }));
    }

    // Accept a resale offer and transfer payment
    function acceptResale(uint index) public payable { 
        require(index < resaleTickets.length, "Invalid resale ticket index.");
        ResaleOffer memory offer = resaleTickets[index];
        require(offer.price == msg.value, "Incorrect payment amount.");
        require(getTicketOf(msg.sender) == 0, "You can only buy one ticket.");

        uint serviceFee = offer.price * 10 / 100; // 10% service fee
        uint sellerPayment = offer.price - serviceFee;

        ticketOwners[offer.ticketId] = msg.sender;

        // Transfer funds to the seller (after service fee deduction)
        (bool sentToSeller, ) = payable(offer.seller).call{value: sellerPayment}("");
        require(sentToSeller, "Failed to transfer funds to seller.");

        // Transfer the service fee to the contract owner
        (bool sentToOwner, ) = payable(owner).call{value: serviceFee}("");
        require(sentToOwner, "Failed to transfer service fee to owner.");

        // Remove the fulfilled resale offer from the array
        resaleTickets[index] = resaleTickets[resaleTickets.length - 1];
        resaleTickets.pop();

        emit TicketResold(offer.seller, msg.sender, offer.ticketId, offer.price);
    }

    // View all resale offers
    function checkResale() public view returns (ResaleOffer[] memory) {
        return resaleTickets;
    }
}
