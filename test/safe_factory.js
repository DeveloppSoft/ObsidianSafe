const SafeFactory = artifacts.require('SafeFactory')
const Safe = artifacts.require('Safe')
const Signers = artifacts.require('Signers')

contract('SafeFactory', async accounts => {
    let factory = {}
    let safe = {}

    it('should have deployed factory', async () => {
        factory = await SafeFactory.deployed()
        assert.ok(factory)
    })

    it('can deploy a new safe', async () => {
        const receipt = await factory.createSafe(accounts[1])
        const safeAddress = receipt.logs[0].args._safe

        safe = await Safe.at(safeAddress)
        assert.isTrue(await safe.isNonceValid(1), 'Contract is not a new safe')
    })

    it('signer correctly configured', async () => {
        const modules = await safe.listVerifModules()
        const signerAddress = modules[0] // Only 1 module
        const signerModule = await Signers.at(signerAddress)
        const signers = await signerModule.listSigners()

        assert.equal(signers.length, 1, 'Must have only one signer')
        assert.equal(signers[0], accounts[1], 'Address mismatch')
        assert.isTrue(await signerModule.isSigner(accounts[1]), 'Account should be a signer')
    })
})
