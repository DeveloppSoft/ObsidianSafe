module.exports = {
    mocha: {
        reporter: 'eth-gas-reporter',
        reporterOptions : {
            currency: 'EUR',
            gasPrice: 21,
            noColors: true
        }
    }
}
