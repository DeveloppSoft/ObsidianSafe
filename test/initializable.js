// Used to check that modifiers are applied
const Safe = artifacts.require('Safe')
const AuthOracle = artifacts.require('AuthOracle')
const assertRevert = require('./helpers/revert.js').assertRevert

contract('Initializable', async accounts => {
    it('is used by Safe', async () => {
        const safe = await Safe.new()
        await safe.initialize(accounts[0])

        assert(await safe.initialized(), 'Safe is not initialized')
        assertRevert(safe.initialize(accounts[1]))
    })

    it('is used by AuthOracle', async () => {
        const oracle = await AuthOracle.new()
        await oracle.initialize(accounts[0], accounts[1])

        assert(await oracle.initialized(), 'Oracle is not initialized')
        assertRevert(oracle.initialize(accounts[2], accounts[3]))
    })
})
