// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract CoinFlip is VRFConsumerBase {
    struct User {
        address payable addr;   // Address of the user
        uint balance;           // current balance of the user
        bool inGame;            // Chcek if user is in the game
        bool inBet;             // Check if user have started a new bet
        uint betAmount;         // The betting amount of the user
        uint flipVal;           // Choosen flip value, 0-> TAILS, 1-> HEADS
        uint betTime;           // Time at which user had started the bet
    }

    // Event emitted in case of a win
    event win(address payable _arr, uint _betAmount);

    // Array of all the users who have entered the game atleast once
    User[] users;

    /*
        Random number generation using VRFConsumerBase
        Reference from the link: https://docs.chain.link/docs/intermediates-tutorial/
    */

    bytes32 keyHash;
    uint256 fee;
    uint256 public randomResult;    // Decides the value of coin flip

    constructor() VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9,
            0xa36085F69e2889c224210F603D836748e7dC0088
        ){
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1*10**18;
    }

    function getRandomNumber() public returns (bytes32 requestId) {
        return requestRandomness(keyHash,fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }

    // Finds the index of a address in our users array. Returns users.length in case not-found
    function userIndex(address payable _addr) public view returns (uint) {
        for(uint i=0; i<users.length; i++){
            if(users[i].addr == _addr) return i;
        }
        return users.length;
    }

    // Enter the Coin Flip Game
    function enterGame() public {
        address payable _addr = payable(msg.sender);
        uint idx = userIndex(_addr);

        // Sets the user with default values of the variables
        // Different cases based on already played the game before or first time
        if(idx == users.length){
            users.push(User(_addr,100,true,false,0,0,0));
        }
        else {
            require(users[idx].inGame == false, "You are already in the game.");
            users[idx].balance = 100;
            users[idx].inGame = true;
            users[idx].inBet = false;
            users[idx].betAmount = 0;
            users[idx].flipVal = 0;
            users[idx].betTime = 0;
        }
    }

    // Exit the Coin Flip Game
    function exitGame() public {

        // User must be present in the game before exiting which is checked by 2 require statements
        uint idx = userIndex(payable(msg.sender));
        require(idx < users.length, "You never entered in this Game.");
        require(users[idx].inGame == true, "You have already exited.");

        //Sets the values of the variables of the exiting user
        users[idx].balance = 0;
        users[idx].inGame = false;
        users[idx].inBet = false;
        users[idx].betAmount = 0;
        users[idx].flipVal = 0;
        users[idx].betTime = 0;
    }

    // View current balance of the user, 0 in case of not present or exited
    function viewBalance() public view returns (uint) {
        uint idx = userIndex(payable(msg.sender));
        if(idx == users.length) return 0;
        return users[idx].balance;
    }   

    // Start a bet by providing the value of bet amount and the coin flip value.
    function bet(uint _betAmount, uint _flipVal) public {

        // Betting is allowed in certain cases only which is checked by the following require statements
        /*
            1. User must be present in the game
            2. The flip value provided must be 0/1 (0-> TAILS, 1-> HEADS)
            3. Bet amount must not exceed the current balance of the user
            4. The user must not be present in some another bet
        */
        uint idx = userIndex(payable(msg.sender));
        require(idx < users.length && users[idx].inGame == true, "You have not entered the Game.");
        require(_flipVal < 2, "Please enter 0/1 in _flipVal.");
        require(_betAmount <= users[idx].balance, "You have exceeded your balance.");
        require(users[idx].inBet == false, "You are already in this bet.");

        // Sets the values of the variables of the betting user
        users[idx].inBet = true;
        users[idx].balance -= _betAmount;
        users[idx].betAmount = _betAmount;
        users[idx].flipVal = _flipVal;
        users[idx].betTime = block.timestamp;
    }

    // Reward the amounts in case of win for every user who have started the bet.
    function rewardBets() public {

        // Rewarding bets is allowed in certain cases only
        /*
            1. User must be present in the game
            2. User must have started a bet
            3. User must wait a certain amount of time depending on when he/she has started
        */
        uint idx = userIndex(payable(msg.sender));
        require(idx < users.length && users[idx].inGame == true, "You have not entered the Game.");
        require(users[idx].inBet == true, "You have been rewarded or you have not started any bet.");

        // User may have to wait for 1 to 10 seconds
        // Whithin this waiting if some other user joins then he/she is also the part of same bet
        uint userWaitingTime = 10-(users[idx].betTime%10);
        uint userWaited = block.timestamp-users[idx].betTime;
        require(userWaited >= userWaitingTime, "You have to wait for some time");

        // Tosses the coin using this function
        // While debugging observed that the value of randomResult changes after 2 calls of getRandomNumber function
        getRandomNumber();
        getRandomNumber();

        // Iterates over all users to check who were in the current bet
        for(uint i=0; i<users.length; i++){
            if(users[i].inGame && users[i].inBet){

                // Returns double the betting amount to balance in case of win and emits a win event
                if(users[i].flipVal == (randomResult%2)){
                    users[i].balance += 2*users[i].betAmount;
                    emit win(users[i].addr,users[i].betAmount);
                }

                // Sets the variables after betting is over
                users[i].inBet = false;
                users[i].betAmount = 0;
                users[i].flipVal = 0;
            }
        }
    }
    
}