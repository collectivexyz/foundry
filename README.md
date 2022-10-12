# Foundry Development Container

Everything needed to develop smart contracts with Ethereum and [Foundry](https://github.com/foundry-rs/foundry)

SOLC: 0.8.17
ETH: 1.10.25
GO: 1.18.7

## Example Dockerfile

```
FROM ghcr.io/momentranks/foundry:latest

ENV PATH=${PATH}:~/.cargo/bin
RUN ~mr/.cargo/bin/forge build --sizes

CMD ~mr/.cargo/bin/forge test -vvv
```
