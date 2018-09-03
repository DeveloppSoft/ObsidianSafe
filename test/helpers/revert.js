module.exports = {
    assertRevert: async promise => {
        try {
            await promise
        } catch(err) {
            assert.equal(
                err.message,
                'VM Exception while processing transaction: revert',
                'expected revert error'
            )
        }
    }
}
