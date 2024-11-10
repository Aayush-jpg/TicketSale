// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract TicketSale {
    // Contract Variables
    address public owner;             // Owner of the contract
    uint public ticketPrice;          // Price per ticket in wei
    uint public totalTickets;         // Total number of tickets available
    uint public ticketsSold;          // Number of tickets sold
    uint public serviceFee = 10;      // Service fee percentage for resale transactions
    uint public contractBalance;      // Accumulated earnings for the owner

    // Ticket ownership - mapping from ticket ID to owner address
    mapping(uint => address) public ticketOwners;

    // Swap offers - mapping from offerer's ticket ID to offeree's address
    mapping(uint => address) public swapOffers;

    // Resale information
    struct ResaleOffer {
        uint ticketId;
        uint price;
        address seller;
    }
    ResaleOffer[] public resaleTickets;

    // Events (for better DApp integration later)
    event TicketPurchased(address indexed buyer, uint ticketId, uint amount);
    event TicketsSwapped(address indexed buyer1, uint ticketId1, address indexed buyer2, uint ticketId2);
    event TicketResold(address indexed seller, address indexed buyer, uint ticketId, uint price);
    event FundsWithdrawn(address indexed owner, uint amount);

    // Constructor
    constructor(uint numTickets, uint price) {
        owner = msg.sender;
        totalTickets = numTickets;
        ticketPrice = price;
    }

    // Modifier to restrict access to owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    // Buy a Ticket
    function buyTicket(uint ticketId) public payable {
        require(ticketId > 0 && ticketId <= totalTickets, "Invalid ticket ID.");
        require(ticketOwners[ticketId] == address(0), "Ticket already sold.");
        require(msg.value == ticketPrice, "Incorrect payment amount.");
        require(getTicketOf(msg.sender) == 0, "You can only buy one ticket.");

        ticketOwners[ticketId] = msg.sender;
        ticketsSold++;

        emit TicketPurchased(msg.sender, ticketId, msg.value);
    }

    // Get Ticket ID for an Address
    function getTicketOf(address person) public view returns (uint) {
        for (uint i = 1; i <= totalTickets; i++) {
            if (ticketOwners[i] == person) {
                return i;
            }
        }
        return 0;
    }

    // Offer a Ticket Swap
    function offerSwap(uint ticketId) public {
        require(ticketOwners[ticketId] == msg.sender, "You don't own this ticket.");
        swapOffers[ticketId] = msg.sender;
    }

    // Accept a Swap Offer
    function acceptSwap(uint ticketId) public {
        require(getTicketOf(msg.sender) != 0, "You need to own a ticket to swap.");
        require(swapOffers[ticketId] != address(0), "No swap offer for this ticket.");
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
            seller: msg.sender
        }));
    }

    // Accept a resale offer
    function acceptResale(uint index) public payable {
        require(index < resaleTickets.length, "Invalid resale ticket index.");
        ResaleOffer memory offer = resaleTickets[index];
        require(offer.price == msg.value, "Incorrect payment amount.");
        require(getTicketOf(msg.sender) == 0, "You can only buy one ticket.");

        uint serviceFeeAmount = offer.price * serviceFee / 100;
        uint sellerPayment = offer.price - serviceFeeAmount;

        // Transfer ownership to the buyer
        ticketOwners[offer.ticketId] = msg.sender;

        // Transfer funds to the seller and store service fee in contract balance
        (bool successSeller, ) = offer.seller.call{value: sellerPayment}("");
        require(successSeller, "Transfer to seller failed.");

        contractBalance += serviceFeeAmount;

        // Remove the resale offer from the array
        resaleTickets[index] = resaleTickets[resaleTickets.length - 1];
        resaleTickets.pop();

        emit TicketResold(offer.seller, msg.sender, offer.ticketId, offer.price);
    }

    // Check available resale tickets
    function checkResale() public view returns (ResaleOffer[] memory) {
        return resaleTickets;
    }

    // Owner withdraws funds from contract balance
    function withdrawFunds() public onlyOwner {
        uint amount = contractBalance;
        contractBalance = 0;

        (bool success, ) = owner.call{value: amount}("");
        require(success, "Withdraw failed.");

        emit FundsWithdrawn(owner, amount);
    }

    // Fallback function to handle unexpected transfers
    receive() external payable {
        contractBalance += msg.value;
    }
}
