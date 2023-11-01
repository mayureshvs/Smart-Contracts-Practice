// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

//Metamask = Signing Off Transaction
//Computer -----(Metamask)-------Infura ---------------Blockchain
contract DAO {
    //Investors will contribute fund
    // startups will raise proposal for funding
    // Manager to deploy and execute the proposal
    // Investor will get tokens against the amount contributed
    // this tokens will decide the weight of votes
    // vote() only Investor
    // createProposal() Only manager
    // stages - yet to start, contribution time, Voting Time, Execution
    // fund() only Investor



    //Structures - for representing Objects

    struct Proposal {
        uint256 id;
        string description;
        uint256 fundingNeeded;
        address payable recipient;
        uint256 votes;
        bool isExecuted;
    }

    //Enums - to represent the any type of states in contract.
    enum stage {
        YetToStart,
        ContributionTime,
        VotingTime,
        ExecutionTime
    }

    // State Variables
    address DAOmanager;
    uint256 quorum;
    uint256 contributionTimeEnd;
    uint voteEndTime;
    uint256 availableFund;
    uint totalTokens;
   

    stage organizationState;

    //mappings
    mapping(uint256 => Proposal) public proposals;
    mapping(address => bool) public isInvestor;
    mapping(address => uint256) public tokensOwned;
    mapping (address => mapping (uint => bool)) public isVoted;

    //State Variable Increment Trackers
    uint256 nextProposalID;

    //Contructors
    constructor(uint256 _quorum, uint256 _contributionTimeEnd, uint _voteEndTime) {
        require(_quorum > 0 && _quorum < 100, "Not Valid Values");
        contributionTimeEnd = block.timestamp + _contributionTimeEnd; // if want to keep 2 hours of contribution time, keep contributionTimeEnd = 2hours in epoch unix time unit
        quorum = _quorum;
        DAOmanager = msg.sender;
        organizationState = stage.ContributionTime;
        voteEndTime = contributionTimeEnd + _voteEndTime;
    }

    //modifiers

    modifier OnlyInvestor() {
        require(isInvestor[msg.sender] == true, "You are not an investor");
        _;
    }

    modifier OnlyManager() {
        require(msg.sender == DAOmanager, "You are not an investor");
        _;
    }

    //Private or Internal Functions

    //Functionality Functions
    function contribute() external payable  {
        require(block.timestamp < contributionTimeEnd, "Contribution time is ended");
        require(msg.value > 0,"Amount should be greater than 0");
        availableFund = availableFund + msg.value;
        totalTokens = totalTokens + msg.value;
        tokensOwned[msg.sender] = tokensOwned[msg.sender] + msg.value;
        isInvestor[msg.sender] = true;
      

    }

    function redeemShare(uint _amount) external OnlyInvestor(){
        require(tokensOwned[msg.sender] >=  _amount, "You don't have enough tokens");
        require(block.timestamp <= contributionTimeEnd,"You cannot redeem your share during voting period");
        require(availableFund >= _amount,"Not enough funds");
        payable(msg.sender).transfer(_amount);
        availableFund = availableFund - _amount;
        totalTokens = totalTokens - _amount;
        tokensOwned[msg.sender] = tokensOwned[msg.sender] - _amount;
        if(tokensOwned[msg.sender] == 0){
            isInvestor[msg.sender] = false;
        }

    }

    function transferShare(uint _amount, address _to) external OnlyInvestor(){
        require(tokensOwned[msg.sender] >=  _amount, "You don't have enough tokens");
        require(block.timestamp <= contributionTimeEnd,"You cannot Transfer your share during voting period");
         tokensOwned[msg.sender] = tokensOwned[msg.sender] - _amount;
         tokensOwned[_to] = tokensOwned[_to] + _amount;
         if(tokensOwned[msg.sender] == 0){
            isInvestor[msg.sender] = false;
        }
        if(!isInvestor[_to]){
            isInvestor[_to] = false;
        }
    }

    function createProposal(string calldata _desc, uint _amount, address payable _recepient) external OnlyManager() {
        require(block.timestamp > contributionTimeEnd , "Still in contribution period.");
        require(_amount < availableFund,"amount is greater than available fund");
        proposals[nextProposalID] = Proposal(nextProposalID,_desc,_amount,_recepient,0,false);
        nextProposalID++;

    }

    function voteProposal(uint _proposalID) external OnlyInvestor(){
        require(!isVoted[msg.sender][_proposalID],"You have already voted");
        require(block.timestamp > contributionTimeEnd && block.timestamp < voteEndTime, "Your are try to vote outside Voting window");
        require(!proposals[_proposalID].isExecuted,"It is already executed");
        proposals[_proposalID].votes += tokensOwned[msg.sender];
        isVoted[msg.sender][_proposalID] = true;

    }

    function executeProposal(uint _proposalID) external OnlyManager(){
        require(!proposals[_proposalID].isExecuted, "It is already Executed");
        uint currentAgreement = proposals[_proposalID].votes*100/totalTokens;
        require(currentAgreement > quorum,"Majority is not in agreement with executing this Proposal");
        proposals[_proposalID].isExecuted = true;
        _transfer(proposals[_proposalID].fundingNeeded,proposals[_proposalID].recipient);
    }

    function _transfer(uint _amount, address payable _recipient) internal{
        _recipient.transfer(_amount);
    }

    function getProposalList() external view returns(Proposal[] memory){
        Proposal[] memory proposalList = new Proposal[](nextProposalID);
        for (uint i = 0;i <nextProposalID;i++){
            proposalList[i] = proposals[i];

        }
        return proposalList;

    }
}
