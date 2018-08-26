const Safe = artifacts.require('Safe')
const SafeFactory = artifacts.require('SafeFactory')
const Signers = artifacts.require('Signers')

const CALL = 0
const DELEGATECALL = 1
const CREATE = 2

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
            try {
                await safe.execFromModule(accounts[0], web3.toWei(1, 'ether'), '0x0', CALL)
            } catch (err) {
                assert(err, 'Expected an error but did not get one')
                assert.equal(
                    err.message,
                    'VM Exception while processing transaction: revert', 
                    'Expected revert error'
                )
            }
        })

        const txTo = accounts[4]
        let txVal = {}
        const txData = '0x0'
        const txOp = CALL
        const txNonce = 1 // First tx ever yeah!
        const txTimestamp = 0 // Not used
        const reimbursementToken = '0x0' // ETH
        const minimumGas = 1e5
        let gasPrice = {}

        let hash = {}
        let signature = {}

        let expectedBalance = {}
        let initialNonce = {}

        before(async () => {
            txVal = web3.toWei(0.5, 'ether')
            assert.ok(txVal)

            expectedBalance = parseInt(web3.eth.getBalance(txTo), 10) + parseInt(txVal, 10)

            gasPrice = web3.toWei(4, 'gwei')
            assert.ok(gasPrice)

            initialNonce = parseInt(await safe.currentNonce(), 10)
        })

        it('prepare tx', async () => {
            // Get signer module
            const modules = await safe.listVerifModules()
            const signerAddress = modules[0] // Only 1 module
            const signers = await Signers.at(signerAddress)

            // Ask it the hash
            hash = await signers.getTxHash(
                txTo,
                txVal,
                txData,
                txOp,
                txNonce,
                txTimestamp,
                reimbursementToken,
                minimumGas,
                gasPrice
            )

            signature = await web3.eth.sign(owner, hash)

            assert.isTrue(
                await signers.verify(
                    txTo,
                    txVal,
                    txData,
                    txOp,
                    txNonce,
                    txTimestamp,
                    reimbursementToken,
                    minimumGas,
                    gasPrice,
                    signature
                ),
                'TX is not correct'
            )
        })

        it('is valid', async () => {
            assert.isTrue(
                await safe.isTxValid(
                    txTo,
                    txVal,
                    txData,
                    txOp,
                    txNonce,
                    txTimestamp,
                    reimbursementToken,
                    minimumGas,
                    gasPrice,
                    signature
                ),
                'TX should be valid'
            )
        })

        it('revert if not enough gas', async () => {
            try {
                await safe.exec(
                    txTo,
                    txVal,
                    txData,
                    txOp,
                    txNonce,
                    txTimestamp,
                    reimbursementToken,
                    minimumGas,
                    gasPrice,
                    signature,
                    { gasPrice: gasPrice, gas: minimumGas - 1000 }
                )
            } catch (err) {
                assert(err, 'Expected an error but did not get one')
                assert.equal(
                    err.message,
                    'VM Exception while processing transaction: revert', 
                    'Expected revert error'
                )
            }
        })

        it('send funds to safe', async () => {
            await web3.eth.sendTransaction({ from: accounts[2], to: safe.address, value: web3.toWei(0.5, 'ether') })
            assert.equal(await web3.eth.getBalance(safe.address), web3.toWei(0.5, 'ether'), "Got 0.5 ETH")
        })
    
        // Here, we have enough funds to EXEC the TX, but not enough to
        // reimburse the gas cost
        it('revert if cannot pay', async () => {
            try {
                await safe.exec(
                    txTo,
                    txVal,
                    txData,
                    txOp,
                    txNonce,
                    txTimestamp,
                    reimbursementToken,
                    minimumGas,
                    gasPrice,
                    signature,
                    { gasPrice: gasPrice }
                )
            } catch (err) {
                assert(err, 'expected an error but did not get one')
                assert.equal(
                    err.message,
                    'VM Exception while processing transaction: revert', 
                    'expected revert error'
                )
            }
        })

        it('send funds to safe', async () => {
            await web3.eth.sendTransaction({ from: accounts[2], to: safe.address, value: web3.toWei(1, 'ether') })
            assert.equal(await web3.eth.getBalance(safe.address), web3.toWei(1.5, 'ether'), "Got 1 ETH")
        })
    
        it('revert if wrong signature', async () => {
            // Signature is valid, but parameter isn't
            try {
                await safe.exec(
                    txTo,
                    txVal,
                    txData,
                    txOp,
                    txNonce,
                    txTimestamp,
                    reimbursementToken,
                    minimumGas,
                    web3.toWei(1, 'ether'), // That could be an interesting attack...
                    signature,
                    { gasPrice: gasPrice }
                )
            } catch (err) {
                assert(err, 'expected an error but did not get one')
                assert.equal(
                    err.message,
                    'VM Exception while processing transaction: revert', 
                    'expected revert error'
                )
            }
        })

        let balanceBefore = {}

        it('submit', async () => {
            balanceBefore = parseInt(await web3.eth.getBalance(accounts[0]), 10)
            
            await safe.exec(
                txTo,
                txVal,
                txData,
                txOp,
                txNonce,
                txTimestamp,
                reimbursementToken,
                minimumGas,
                gasPrice,
                signature,
                { gasPrice: gasPrice }
            )
        })

        it('executed tx correctly', async () => {
            assert.equal(web3.eth.getBalance(txTo), expectedBalance, 'txTo should have received funds')
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
            try {
                await safe.exec(
                    txTo,
                    txVal,
                    txData,
                    txOp,
                    txNonce,
                    txTimestamp,
                    reimbursementToken,
                    minimumGas,
                    gasPrice,
                    signature,
                    { gasPrice: gasPrice }
                )
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
})
