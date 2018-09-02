// Used to check that modifiers are applied
const Safe = artifacts.require('Safe')
const AuthOracle = artifacts.require('AuthOracle')

contract('Initializable', async accounts => {
    it('is used by Safe', async () => {
        const safe = await Safe.new()
        await safe.initialize(accounts[0])

        assert(await safe.initialized(), 'Safe is not initialized')

        try {
            await safe.initialize(accounts[1])
        } catch (err) {
            assert(err, 'expected an error but did not get one')
            assert.equal(
                err.message,
                'VM Exception while processing transaction: revert',
                'expected revert error'
            )
        }
    })

    it('is used by AuthOracle', async () => {
        const oracle = await AuthOracle.new()
        await oracle.initialize(accounts[0], accounts[1])

        assert(await oracle.initialized(), 'Oracle is not initialized')

        try {
            await oracle.initialize(accounts[2], accounts[3])
        } catch (err) {
            assert(err, 'expected an error but did not get one')
            assert.equal(
                err.message,
                'VM Exception while processing transaction: revert',
                'expected revert error'
            )
        }
    })
})
