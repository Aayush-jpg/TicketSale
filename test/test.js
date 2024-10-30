const TicketSale = artifacts.require("TicketSale");

contract("TicketSale", (accounts) => {
    let ticketSale;

    beforeEach(async () => {
        ticketSale = await TicketSale.new(100, web3.utils.toWei('0.01', 'ether'));
    });

    it("should allow users to buy tickets", async () => {
        const result = await ticketSale.buyTicket(1, { from: accounts[1], value: web3.utils.toWei('0.01', 'ether') });
        assert.equal(result.logs[0].event, "TicketPurchased", "Event should be TicketPurchased");
    });

    it("should not allow users to buy the same ticket twice", async () => {
        await ticketSale.buyTicket(1, { from: accounts[1], value: web3.utils.toWei('0.01', 'ether') });
        
        // Attempt to buy the same ticket again
        try {
            await ticketSale.buyTicket(1, { from: accounts[1], value: web3.utils.toWei('0.01', 'ether') });
            assert.fail("Expected an error but did not get one.");
        } catch (error) {
            assert(
                error.message.includes("Ticket already sold."),
                "Expected 'Ticket already sold.' error message"
            );
        }
    });

    it("should allow users to swap tickets", async () => {
        await ticketSale.buyTicket(1, { from: accounts[1], value: web3.utils.toWei('0.01', 'ether') });
        await ticketSale.buyTicket(2, { from: accounts[2], value: web3.utils.toWei('0.01', 'ether') });

        await ticketSale.offerSwap(1, { from: accounts[1] });
        const result = await ticketSale.acceptSwap(1, { from: accounts[2] });

        assert.equal(result.logs[0].event, "TicketsSwapped", "Event should be TicketsSwapped");
    });

    it("should allow resale of tickets", async () => {
        await ticketSale.buyTicket(1, { from: accounts[1], value: web3.utils.toWei('0.01', 'ether') });
        await ticketSale.resaleTicket(web3.utils.toWei('0.02', 'ether'), { from: accounts[1] });

        const result = await ticketSale.checkResale();
        assert.equal(result.length, 1, "There should be 1 resale offer");
    });

    it("should allow users to accept resale tickets", async () => {
        await ticketSale.buyTicket(1, { from: accounts[1], value: web3.utils.toWei('0.01', 'ether') });
        await ticketSale.resaleTicket(web3.utils.toWei('0.02', 'ether'), { from: accounts[1] });

        const result = await ticketSale.acceptResale(0, { from: accounts[2], value: web3.utils.toWei('0.02', 'ether') });
        assert.equal(result.logs[0].event, "TicketResold", "Event should be TicketResold");
    });
});
