const ListOnSteroids = artifacts.require('ListOnSteroids')
const Signers = artifacts.require('Signers')
const SafeFactory = artifacts.require('SafeFactory')

module.exports = async deployer => {
    deployer.deploy(ListOnSteroids)
    deployer.link(ListOnSteroids, Signers)
    deployer.link(ListOnSteroids, SafeFactory)
}
