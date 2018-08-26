const Signers = artifacts.require('Signers')

contract('Signers', async accounts => {
    const fakeSafe = accounts[1]
    const signers = [
        accounts[2],
        accounts[3]
    ]
    const signatures = 2

    let signerModule = {}

    it('deploys and configure module', async () => {
        signers.sort()

        signerModule = await Signers.new(fakeSafe, signers, signatures)
        assert.ok(signerModule)
    })

    it('has signers', async () => {
        const signersInModules = await signerModule.listSigners()

        assert.equal(signersInModules.length, 2, "Should have two signers")
        assert.isTrue(
            signers[0] == signersInModules[0] ||
            signers[0] == signersInModules[1],
            "Signer 0 should be added"
        )
        assert.isTrue(
            signers[1] == signersInModules[0] ||
            signers[1] == signersInModules[1],
            "Signer 1 should be added"
        )

        assert.isTrue(await signerModule.isSigner(signers[0]), "0 should be signer");
        assert.isTrue(await signerModule.isSigner(signers[1]), "1 should be signer");
    })

    context('Add and remove signer', async () => {
        it('add signer', async () => {
            await signerModule.addSigner(accounts[4], { from: fakeSafe })

            const signersInModules = await signerModule.listSigners()

            assert.equal(signersInModules.length, 3, "Should have three signers")
            assert.isTrue(
                accounts[4] == signersInModules[0] ||
                accounts[4] == signersInModules[1] ||
                accounts[4] == signersInModules[2],
                "Signer not found")
        })

        it('remove signer', async () => {
            let signersInModules = await signerModule.listSigners()

            const signerAt = signersInModules.indexOf(accounts[4])

            let signerBefore = '0x1'
            if (signerAt > 0) {
                signerBefore = signersInModules[signerAt - 1]
            }

            await signerModule.removeSigner(signerBefore, accounts[4], { from: fakeSafe })

            signersInModules = await signerModule.listSigners()

            assert.equal(signersInModules.length, 2, "Should have three signers")
            assert.isFalse(
                accounts[4] == signersInModules[0] ||
                accounts[4] == signersInModules[1],
                "Signer not found")
        })
    })

    context('access control', async () => {
        const dst   = '0x42'
        const value = 2
        const data  = '0xdeadbeef'
        const op    = 2
        const nonce = 1
        const time  = 23
        const token = '0x21'
        const gasPr = 90

        let hash = {}

        let sign0 = {}
        let sign1 = {}

        let signatures = '0x'

        it('sign data', async () => {
            hash = await signerModule.getTxHash(
                dst,
                value,
                data,
                op,
                nonce,
                time,
                token,
                gasPr
            )

            sign0 = await web3.eth.sign(signers[0], hash)
            sign1 = await web3.eth.sign(signers[1], hash)

            // Remove '0x0'
            signatures += sign0.slice(2)
            signatures += sign1.slice(2)
        })

        it('grant access', async () => {
            assert.isTrue(
                await signerModule.verify(
                    dst,
                    value,
                    data,
                    op,
                    nonce,
                    time,
                    token,
                    gasPr,
                    signatures
                ),
                "Should grant access"
            )
        })

        it('refuse access if not enough signatures', async () => {
            assert.isFalse(
                await signerModule.verify(
                    dst,
                    value,
                    data,
                    op,
                    nonce,
                    time,
                    token,
                    gasPr,
                    sign0 // One is missing
                ),
                "Should refuse access"
            )
        })

        it('refuse access if wrong signature', async () => {
            assert.isFalse(
                await signerModule.verify(
                    dst,
                    value,
                    data,
                    op,
                    nonce,
                    time,
                    token,
                    gasPr,
                    '0xdeadbeef' //signatures
                ),
                "Should refuse access"
            )
        })
    })
})
