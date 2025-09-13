module.exports = {
  prod: {
    Document: {
      args: ["https://infura-ipfs.io/ipfs/"],
      deployedAddress: "0xF8c3722Eb2b7711735D2f239798443D9456ae005"
    },
    network: "polygon_main",
  },
  test: {
    Document: {
      args: ["https://infura-ipfs.io/ipfs/"],
      deployedAddress: "0x0844E35e66Eb79Ee8b2A3FE0ef8d13be7c1Ed528"
    },
    network: "amoy",
  },
  dev: {
    Document: {
      args: ["https://infura-ipfs.io/ipfs/"],
    },
    network: "amoy",
  },
};