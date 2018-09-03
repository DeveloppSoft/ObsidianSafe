module.exports = {
    ops: {
        'CALL': 0,
        'DELEGATECALL': 1,
        'CREATE': 2
    },

    encodeABI: async (truffleContract, method, ...methodArgs) => {
        const web3Contract = web3.eth.contract(truffleContract.abi).at(truffleContract.address)
        return await web3Contract[method].getData(...methodArgs)
    },

    prepareTx: async (safeContract, tx) => {
        if (tx.nonce === undefined || tx.nonce == 0) {
            tx.nonce = parseInt(await safeContract.currentNonce(), 10) + 1
        }

        if (tx.gas === undefined || tx.gas == 0) {
            const web3Tx = {
                from: safeContract.address,
                to: tx.to,
                value: tx.value || 0,
                data: tx.data
            }

            tx.gas = await web3.eth.estimateGas(web3Tx)

            // Add some gas for other tasks
            tx.gas += 10000
        }

        return {
            to: tx.to,
            value: tx.value || 0,
            data: tx.data || '0x0',
            op: tx.op || 0,
            nonce: tx.nonce,
            timestamp: tx.timestamp || 0,
            token: tx.token || '0x0',
            gas: tx.gas,
            gasPrice: tx.gasPrice || 0
        }
    },

    sign: async (hashOracle, tx, ...signers) => {
        const hash = await hashOracle.getTxHash(
            tx.to,
            tx.value,
            tx.data,
            tx.op,
            tx.nonce,
            tx.timestamp,
            tx.token,
            tx.gas,
            tx.gasPrice
        )

        let signature = '0x'

        for (const signer of signers) {
            signature += (await web3.eth.sign(signer, hash)).slice(2)
        }

        return signature
    }
}
