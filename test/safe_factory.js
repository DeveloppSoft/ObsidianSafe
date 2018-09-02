const SafeFactory = artifacts.require('SafeFactory')
const Safe = artifacts.require('Safe')
const AuthOracle = artifacts.require('AuthOracle')

contract('SafeFactory', async accounts => {
    let factory = {}
    let safe = {}
    let oracle = {}

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

    it('added the auth oracle', async () => {
        const oracleAddress = await safe.oracle()
        oracle = await AuthOracle.at(oracleAddress)

        assert(oracleAddress != '0x0', 'Oracle not configured')
    })

    it('configured signer', async () => {
        const signers = await oracle.listSigners()

        assert.equal(signers.length, 1, 'Has only one signer')
        assert.equal(signers[0], accounts[1], 'Signer not properly configured')
    })
})
