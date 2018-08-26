const ListOnSteroids = artifacts.require('ListOnSteroids')
const Signers = artifacts.require('Signers')

module.exports = async deployer => {
    deployer.deploy(ListOnSteroids)
    deployer.link(ListOnSteroids, Signers)
}
