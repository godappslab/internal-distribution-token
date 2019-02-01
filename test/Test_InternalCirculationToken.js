const InternalCirculationToken = artifacts.require('InternalCirculationToken');
const Web3 = require('web3');

contract('[TEST] InternalCirculationToken', async (accounts) => {
    const totalSupply = 1000000000;
    const alocateValue = 100;
    const distValue = 10;
    const otherValue = 5;

    const ownerAddress = accounts[0];
    const distributorAddress = accounts[1];
    const userAddress = accounts[2];
    const otherAddress = accounts[3];

    const log = function() {
        console.log('       [LOG]', ...arguments);
    };

    const balanceLog = (ownderValue = 0, distValue = 0, userValue = 0, otherValue = 0) => {
        log('Owner      :', ownderValue.toNumber());
        log('Distributor:', distValue.toNumber());
        log('User       :', userValue.toNumber());
        log('Other      :', otherValue.toNumber());
    };

    const myWeb3 = new Web3(web3.currentProvider.host);

    it(`Initial state is the owner address token holding number: ${totalSupply}`, async () => {
        const token = await InternalCirculationToken.deployed();

        const ownerBalance = await token.balanceOf.call(ownerAddress);
        const distBalance = await token.balanceOf.call(distributorAddress);
        const userBalance = await token.balanceOf.call(userAddress);
        const otherBalance = await token.balanceOf.call(otherAddress);

        balanceLog(ownerBalance, distBalance, userBalance, otherBalance);
        assert.equal(ownerBalance.valueOf(), totalSupply);
        assert.equal(distBalance.valueOf(), 0);
        assert.equal(userBalance.valueOf(), 0);
        assert.equal(otherBalance.valueOf(), 0);
    });

    it('Register as a distributor', async () => {
        const token = await InternalCirculationToken.deployed();

        const before = await token.isDistributor.call(distributorAddress);
        assert.equal(before, false);

        await token.addToDistributor.sendTransaction(distributorAddress);
        const after = await token.isDistributor.call(distributorAddress);
        assert.equal(after, true);
    });

    it(`Assign token to distributor (Number of tokens: ${alocateValue})`, async () => {
        const token = await InternalCirculationToken.deployed();

        await token.transfer.sendTransaction(distributorAddress, alocateValue);

        const ownerBalance = await token.balanceOf.call(ownerAddress);
        const distBalance = await token.balanceOf.call(distributorAddress);
        const userBalance = await token.balanceOf.call(userAddress);
        const otherBalance = await token.balanceOf.call(otherAddress);

        balanceLog(ownerBalance, distBalance, userBalance, otherBalance);
        assert.equal(ownerBalance.valueOf(), totalSupply - alocateValue);
        assert.equal(distBalance.valueOf(), alocateValue);
        assert.equal(userBalance.valueOf(), 0);
        assert.equal(otherBalance.valueOf(), 0);
    });

    it(`A token from the distributor to the user (Number of tokens: ${distValue})`, async () => {
        const token = await InternalCirculationToken.deployed();

        await token.transfer.sendTransaction(userAddress, distValue, { from: distributorAddress });

        const ownerBalance = await token.balanceOf.call(ownerAddress);
        const distBalance = await token.balanceOf.call(distributorAddress);
        const userBalance = await token.balanceOf.call(userAddress);
        const otherBalance = await token.balanceOf.call(otherAddress);

        balanceLog(ownerBalance, distBalance, userBalance, otherBalance);
        assert.equal(ownerBalance.valueOf(), totalSupply - alocateValue);
        assert.equal(distBalance.valueOf(), alocateValue - distValue);
        assert.equal(userBalance.valueOf(), distValue);
        assert.equal(otherBalance.valueOf(), 0);
    });

    it(`Test token move from user to other user (Number of tokens: ${otherValue})`, async () => {
        const token = await InternalCirculationToken.deployed();

        try {
            await token.transfer.sendTransaction(otherAddress, otherValue, { from: userAddress });
        } catch (e) {
            const reverted = e.message.search('revert') >= 0;
            assert.equal(reverted, true);

            return;
        }

        assert.fail('Expected throw not received');
        return;
    });
});
