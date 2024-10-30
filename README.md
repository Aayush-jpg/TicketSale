**Ticket Sale**


A decentralized ticket sale system built on Ethereum using smart contracts. This project allows users to purchase tickets, swap them with others, and resell them. It features event emissions for better DApp integration and provides a secure and transparent way to manage ticket sales.

**Features**

Purchase Tickets: Users can buy tickets at a specified price.
Swap Tickets: Users can offer their tickets for swap with others.
Resell Tickets: Users can put their tickets for resale at a specified price.
Events: The contract emits events for ticket purchases, swaps, and resales.

**Technologies Used**

Solidity: Version 0.8.17
Ethereum: Smart contracts deployed on the Ethereum network
Truffle: Development framework for Ethereum
Ganache: Personal Ethereum blockchain for development
Node.js: JavaScript runtime for testing and scripts


**Key Functions**

buyTicket(uint ticketId): Allows users to purchase a ticket.
offerSwap(uint ticketId): Allows users to offer their ticket for a swap.
acceptSwap(uint ticketId): Allows users to accept a swap offer for their ticket.
resaleTicket(uint price): Allows users to put their ticket for resale.
acceptResale(uint ticketId): Allows users to buy a ticket listed for resale.













