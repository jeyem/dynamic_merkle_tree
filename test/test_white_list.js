const WhiteList = artifacts.require("WhiteList")
const { MerkleTree } = require('merkletreejs')
const keccak256 = require('keccak256');


contract("WhiteList", (accounts) => {
  it("should assert true", async () => {
    console.log(accounts)
    const app = await WhiteList.deployed()
    const leafNodes = accounts.slice(0, 4).map(item => keccak256(item))
    const tree = new MerkleTree(leafNodes, keccak256, { sortPairs: true })
    const root = tree.getHexRoot()

    await app.setRoot(tree.getHexRoot(), leafNodes.length)

    assert.equal(root, await app.getRoot())

    const leaf = keccak256(accounts[1])
    const proof = tree.getHexProof(leaf)

    assert.isTrue(await app.mint(proof, { from: accounts[1] }))

    const lastItemProof = tree.getHexProof(leafNodes[leafNodes.length - 1])
    await app.addAddress(accounts[5], lastItemProof)


  })
})
