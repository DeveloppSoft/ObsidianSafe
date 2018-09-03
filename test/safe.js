const Safe = artifacts.require('Safe')
const SafeFactory = artifacts.require('SafeFactory')
const AuthOracle = artifacts.require('AuthOracle')

const assertRevert = require('./helpers/revert.js').assertRevert
const TX = require('./helpers/tx.js')

contract('Safe', async accounts => {
    let safe = {}
    const owner = accounts[1]

    it('deploy new safe from factory', async () => {
        const factory = await SafeFactory.deployed()
        const receipt = await factory.createSafe(owner)

        const safeAddress = receipt.logs[0].args._safe
        safe = await Safe.at(safeAddress)
        assert.ok(safe)
    })

    context('Transactions', async () => {
        it('cannot call execFromModule if not module', async () => {
            await assertRevert(safe.execFromModule(accounts[0], web3.toWei(1, 'ether'), '0x0', 0))
        })

        let tx = {}
        let signature = {}
        let expectedBalance = {}
        let initialNonce = 0
        let oracle = {}

        before(async () => {
            tx = {
                to: accounts[4],
                value: web3.toWei(0.5, 'ether'),
                gasPrice: web3.toWei(1, 'wei')
            }

            expectedBalance = parseInt(web3.eth.getBalance(tx.to), 10) + parseInt(tx.value, 10)
            oracle = await AuthOracle.at(await safe.oracle())
        })

        it('prepare tx', async () => {
            tx = await TX.prepareTx(
                safe,
                tx
            )
        })

        it('sign tx', async () => {
            signature = await TX.sign(
                oracle,
                tx,
                owner
            )
        })

        it('is valid', async () => {
            assert.isTrue(
                await safe.isTxValid(
                    tx.to,
                    tx.value,
                    '0x0',
                    0,
                    1, // First tx ever
                    0,
                    '0x0', // ETH
                    tx.gas,
                    tx.gasPrice,
                    signature
                ),
                'TX should be valid'
            )
        })

        it('revert if not enough gas', async () => {
            await assertRevert(
                safe.exec(
                    tx.to,
                    tx.value,
                    '0x0',
                    0,
                    1, // First tx ever
                    0,
                    '0x0', // ETH
                    tx.gas,
                    tx.gasPrice,
                    signature,
                    { gasPrice: tx.gasPrice, gas: tx.gas - 1 }
                )
            )
        })

        it('send funds to safe', async () => {
            await web3.eth.sendTransaction({ from: accounts[2], to: safe.address, value: web3.toWei(0.5, 'ether') })
            assert.equal(await web3.eth.getBalance(safe.address), web3.toWei(0.5, 'ether'), "Got 0.5 ETH")
        })

        // Here, we have enough funds to EXEC the TX, but not enough to
        // reimburse the gas cost
        it('revert if cannot pay', async () => {
            await assertRevert(
                safe.exec(
                    tx.to,
                    tx.value,
                    '0x0',
                    0,
                    1, // First tx ever
                    0,
                    '0x0', // ETH
                    tx.gas,
                    tx.gasPrice,
                    signature,
                    { gasPrice: tx.gasPrice }
                )
            )
        })

        it('send funds to safe', async () => {
            await web3.eth.sendTransaction({ from: accounts[2], to: safe.address, value: web3.toWei(1, 'ether') })
            assert.equal(await web3.eth.getBalance(safe.address), web3.toWei(1.5, 'ether'), "Got 1 ETH")
        })

        it('revert if wrong signature', async () => {
            // Signature is valid, but parameter isn't
            await assertRevert(
                safe.exec(
                    tx.to,
                    tx.value,
                    '0x0',
                    0,
                    1, // First tx ever
                    0,
                    '0x0', // ETH
                    tx.gas,
                    tx.gasPrice,
                    signature.slice(1), // Remove one bit
                    { gasPrice: tx.gasPrice }
                )
            )
        })

        let balanceBefore = {}

        it('submit', async () => {
            balanceBefore = parseInt(await web3.eth.getBalance(accounts[0]), 10)

            await safe.exec(
                    tx.to,
                    tx.value,
                    '0x0',
                    0,
                    1, // First tx ever
                    0,
                    '0x0', // ETH
                    tx.gas,
                    tx.gasPrice,
                    signature,
                    { gasPrice: tx.gasPrice }
            )
        })

        it('executed tx correctly', async () => {
            assert.equal(web3.eth.getBalance(tx.to), expectedBalance, 'tx.to should have received funds')
        })

        it('incremented nonce', async () => {
            assert.equal(
                await safe.currentNonce(),
                initialNonce + 1,
                'Nonce should have increased by 1'
            )
        })

        it('refunded caller', async () => {
            const differenceAfter = balanceBefore - parseInt(await web3.eth.getBalance(accounts[0]), 10)

            assert.isAbove(differenceAfter, 0, 'Refund is too low')
        })

        it('cannot replay tx', async () => {
            await assertRevert(
                safe.exec(
                    tx.to,
                    tx.value,
                    '0x0',
                    0,
                    1, // First tx ever
                    0,
                    '0x0', // ETH
                    tx.gas,
                    tx.gasPrice,
                    signature,
                    { gasPrice: tx.gasPrice }
                )
            )
        })

        context('Module', async () => {
            const fakeModule = accounts[1]
            let tx = {}
            let signature = {}

            it('prepare tx', async () => {
                tx = await TX.prepareTx(
                    safe,
                    {
                        to: oracle.address,
                        op: 0, // CALL
                        gasPrice: web3.toWei(1, 'wei'),
                        data: await TX.encodeABI(oracle, 'addModule', fakeModule)
                    }
                )
            })

            it('sign tx', async () => {
                signature = await TX.sign(
                    oracle,
                    tx,
                    owner
                )
            })

            it('add module', async () => {
                await safe.exec(
                    tx.to,
                    tx.value,
                    tx.data,
                    tx.op,
                    tx.nonce,
                    tx.timestamp,
                    tx.token,
                    tx.gas,
                    tx.gasPrice,
                    signature,
                    { gasPrice: tx.gasPrice }
                )
            })

            it('grant access to module', async () => {
                safe.execFromModule(accounts[0], web3.toWei(1, 'wei'), '0x0', 0, { from: fakeModule })
            })
        })
    })
})
