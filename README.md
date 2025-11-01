# Cross Chain Rebase Token #

## Implementation of Cross Chain Rebase Token using CCIP from Chainlink ##

### CCIP: https://chain.link/cross-chain ###

1. A protocol that allows user to deposit into a vault and in return, receive rebase token that represent their underlying balance.
2. Rebase token -> balanceOf function is dynamic to show the changing balance with time.
    - Balance increases linearly with time
    - Mint tokens to our users every time they perform actions instead of updating the state every time (the actual token minting only happen when action is done. E.g. Minting, Burning, Transferring, Bridging, etc).
3. Interest Rate
    - Individually set an interest rate for each user based on global interest rate of the protocol at the time the user deposit into the vault. 
    - This global interest rate can only decrease to incentivize/reward early adopters.
    - Increase token adoption!
