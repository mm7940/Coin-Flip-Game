# Web3 Solidity Challenge: Coin Flip

## About Game

This is Coin Flip betting game where users bet with an amount from their balance and choose a flip value (0-> TAILS, 1-> HEADS). Each user get a balance of 100 by deafult to start a bet then the amount increases or decreases based on the wins or looses of the user.

## How to play

1. enterGame: Takes you inside the game. You must enter the game before using any feature.
2. viewBalance: Shows the current balance you have. Do not bet more than the balance.
3. bet: Provide the amount you want to bet for and the flip value( 0-> TAILS, 1-> HEADS) to start a bet. You cannot enter multiple bets.
4. rewardBets: If any of the user who are playing and in the bet uses this then all the users will be rewrded who were waiting for the bet rewards. Any user have to wait for atmost 10 seconds.
5. exitGame: Once you are done playing or your balance have reduced to 0 you may quit playing.

Don't use the features getRandomNumber, userIndex or rawfulfillRandomness

## Testing

Testnet Deployment address: 0x4bF2c7ccE1c024F8A3f30eA48C7830A3b8186546
All the features described above are tested thoroughly by deploying it to Injected Web3 environment. The rewardBets feature is tested using Javascript VM environment using multiple users in same bet betting independently.
