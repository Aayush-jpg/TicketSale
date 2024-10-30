// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract TicketSale {
    // Contract Variables
    address public owner; // Owner of the contract
    uint public ticketPrice; // Price per ticket in wei
    uint public totalTickets; // Total number of tickets available
    uint public ticketsSold;  // Number of tickets sold
    
    // Ticket ownership - mapping from ticket ID to owner address
    mapping (uint => address) public ticketOwners; 
    
    // Swap offers - mapping from offerer's ticket ID to offeree's address
    mapping (uint => address) public swapOffers; 

    // Resale information
    struct ResaleOffer {
        uint ticketId;
        uint price;
        address seller; // Add seller to the ResaleOffer struct
    }
    ResaleOffer[] public resaleTickets;

    // Events (for better DApp integration later)
    event TicketPurchased(address buyer, uint ticketId);
    event TicketsSwapped(address buyer1, uint ticketId1, address buyer2, uint ticketId2);
    event TicketResold(address seller, address buyer, uint ticketId, uint price);

    // Constructor
    constructor(uint numTickets, uint price) {
        owner = msg.sender;
        totalTickets = numTickets;
        ticketPrice = price; 
    }

    // Buy a Ticket
    function buyTicket(uint ticketId) public payable {
        require(ticketId > 0 && ticketId <= totalTickets, "Invalid ticket ID.");
        require(ticketOwners[ticketId] == address(0), "Ticket already sold.");
        require(msg.value == ticketPrice, "Incorrect payment amount.");
        require(getTicketOf(msg.sender) == 0, "You can only buy one ticket."); 

        ticketOwners[ticketId] = msg.sender;
        ticketsSold++;
        
        emit TicketPurchased(msg.sender, ticketId);
    }

    // Get Ticket ID for an Address
    function getTicketOf(address person) public view returns (uint) {
        for (uint i = 1; i <= totalTickets; i++) {
            if (ticketOwners[i] == person) {
                return i; 
            }
        }
        return 0; // Person doesn't own a ticket
    }

    // Offer a Ticket Swap 
    function offerSwap(uint ticketId) public {
        require(ticketOwners[ticketId] == msg.sender, "You don't own this ticket.");
        swapOffers[ticketId] = msg.sender; 
    }

    // Accept a Swap Offer
    function acceptSwap(uint ticketId) public {
        require(getTicketOf(msg.sender) != 0, "You need to own a ticket to swap.");
        require(swapOffers[ticketId] != address(0), "No swap offer for your ticket.");
        require(swapOffers[ticketId] != msg.sender, "Cannot accept your own swap offer.");

        uint offererTicket = ticketId;
        address offerer = swapOffers[ticketId];
        uint acceptorTicket = getTicketOf(msg.sender);

        // Swap Ownership
        ticketOwners[offererTicket] = msg.sender; 
        ticketOwners[acceptorTicket] = offerer; 

        // Remove the swap offer
        delete swapOffers[offererTicket];

        emit TicketsSwapped(offerer, offererTicket, msg.sender, acceptorTicket);
    }

    // Offer a ticket for resale
    function resaleTicket(uint price) public {
        uint ticketId = getTicketOf(msg.sender);
        require(ticketId != 0, "You don't own a ticket to resell.");
       
        // Create a ResaleOffer struct and add it to the array
        resaleTickets.push(ResaleOffer({
            ticketId: ticketId,
            price: price,
            seller: msg.sender // Add the seller's address
        }));
    }

    // Accept a resale offer
    function acceptResale(uint index) public payable { 
        require(index < resaleTickets.length, "Invalid resale ticket index.");
        ResaleOffer memory offer = resaleTickets[index];
        require(offer.price == msg.value, "Incorrect payment amount.");
        require(getTicketOf(msg.sender) == 0, "You can only buy one ticket."); 

        uint serviceFee = offer.price * 10 / 100; // 10% service fee
        uint sellerPayment = offer.price - serviceFee;

        // Transfer ownership to the buyer
        ticketOwners[offer.ticketId] = msg.sender;

        // Send funds to the seller and the manager
        payable(offer.seller).transfer(sellerPayment);  
        payable(owner).transfer(serviceFee);  

        // Remove the resale offer from the array
        resaleTickets[index] = resaleTickets[resaleTickets.length - 1];
        resaleTickets.pop(); 

        emit TicketResold(offer.seller, msg.sender, offer.ticketId, offer.price);
    }

    // Check available resale tickets 
    function checkResale() public view returns (ResaleOffer[] memory) {
        return resaleTickets;
    }
}
