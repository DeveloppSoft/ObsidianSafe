const SafeFactory = artifacts.require('SafeFactory')
const Safe = artifacts.require('Safe')

contract('SafeFactory', async accounts => {
    let factory = {}

    it('should have deployed factory', async () => {
        factory = await SafeFactory.deployed()
        assert.ok(factory)
    })

    it('can deploy a new safe', async () => {
        const receipt = await factory.createSafe(accounts[1])
        const safeAddress = receipt.logs[0].args._safe

        const safe = await Safe.at(safeAddress)
        assert.isTrue(await safe.isNonceValid(1), "Contract is not a new safe")
    })

    // Shall we check the modules installed?
})
