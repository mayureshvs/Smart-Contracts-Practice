// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Voting {
    address electionComission;
    address public winner;
    uint8 candidatesLimit;

    enum Gender {
        Male,
        Female,
        Other
    }

    enum Party {
        BJP,
        Congress,
        BSP,
        AAP,
        Shivsena
    }

    //Study Advance Enums in solidity if exists and try later
    /*
    enum ErrorCodes{
        FakeIDalert = 401,
        CandidateAlreadyRegistered = 402
    }
    */

    struct Voter {
        string name;
        uint8 age;
        uint256 voterId;
        Gender gender;
        address voterAddress;
        bool hasVoted;
        bytes1 AadharID;
    }

    struct Candidate {
        string name;
        uint8 age;
        uint256 candidateID;
        Party party;
        Gender gender;
        address candidateAddress;
        uint256 votes;
        bytes1 AadharID;
    }

    uint256 nextCandidateID;
    uint256 nextVoterID;

    mapping(uint256 => Voter) voterDetails;
    mapping(uint256 => Candidate) candidateDetails;

    uint startTime;
    uint endTime;

    bool stopVoting;

    constructor(uint8 _candidatesLimit) {
        electionComission = msg.sender;
        candidatesLimit = _candidatesLimit;
    }

    modifier isVotingOver(){
        require(block.timestamp > endTime || stopVoting,"Voting is not over");
        _;
    }

    modifier onlyCommissioner(){
        require(electionComission == msg.sender,"Not from Election Commission");
        _;
    }

    function candidateRegister(
        string calldata _name,
        uint8 _age,
        Party _party,
        Gender _gender,
        bytes1 _aadharID
    ) external {
        require(
            msg.sender != electionComission,
            "You are from election commission"
        );
        require(
            candidateVerification(msg.sender, _aadharID),
            "Candidate is already registered or Fake ID"
        );
        require(_age > 18, "You are not eligible");
        require(
            nextCandidateID < candidatesLimit,
            "Candidate Registration Full"
        );

        candidateDetails[nextCandidateID] = Candidate(
            _name,
            _age,
            nextCandidateID,
            _party,
            _gender,
            msg.sender,
            0,
            _aadharID
        );
        nextCandidateID++;
    }

    function _isValid(bytes1 _aadharID) private pure returns(bool){
        //logic to check if Aadhar ID is valid against some database
        if(_aadharID == _aadharID){
            return true;
        }else{
            return false;
        }
    }

    function candidateVerification(address _person, bytes1 _aadharID)
        private
        view
        returns (bool)
    {
        //check if fake candidate is trying to register
        if (_isValid(_aadharID)) {
            //check if already registered
            for(uint i = 0;i<nextCandidateID;i++){
                if(candidateDetails[i].candidateAddress == _person){
                    return false;
                }
            }
            return true;
        } else {
            return false;
        }

    }

    function candidateList() public view returns(Candidate[] memory){
        Candidate[] memory arrayCandidates = new Candidate[](nextCandidateID);

        for(uint i = 0;i < nextCandidateID;i++){
            arrayCandidates[i] = candidateDetails[i];
        }
        return arrayCandidates;
    }

    
    function voterRegister(
        string calldata _name,
        uint8 _age,
        Gender _gender,
        bytes1 _aadharID
    ) external {

        require(
            voterVerification(msg.sender, _aadharID),
            "Voter is already registered or Fake ID"
        );
        require(_age > 18, "You are not eligible");
        

        voterDetails[nextVoterID] = Voter(
            _name,
            _age,
            nextVoterID,
            _gender,
            msg.sender,
            false,
            _aadharID
        );
        nextVoterID++;
    }

    function voterVerification(address _person, bytes1 _aadharID)
        private
        view
        returns (bool)
    {
        //check if fake candidate is trying to register
        if (_isValid(_aadharID)) {
            //check if already registered
            for(uint i = 0;i<nextVoterID;i++){
                if(voterDetails[i].voterAddress == _person){
                    return false;
                }
            }
            return true;
        } else {
            return false;
        }

    }

    function voterList() public view returns(Voter[] memory){
        Voter[] memory arrayVoters = new Voter[](nextVoterID);

        for(uint i = 0;i < nextVoterID;i++){
            arrayVoters[i] = voterDetails[i];
        }
        return arrayVoters;
    }

    function vote(uint _voterID, uint _candidateIDtoBeVoted)external{
        require(voterDetails[_voterID].voterAddress == msg.sender,"you are not authorized to vote for provided voter ID");
        require(!(voterDetails[_voterID].hasVoted),"Voting already done");
        require(candidateDetails[_candidateIDtoBeVoted].age!=0,"Invalid Candidate ID");
        require(startTime!=0,"Voting has not started");

        voterDetails[_voterID].hasVoted = true;
        candidateDetails[_candidateIDtoBeVoted].votes++;


    }

    function voteTime(uint _startTime,uint _endTime) external onlyCommissioner() {
        startTime = _startTime + block.timestamp;
        endTime = startTime + _endTime;
    }

    function votingStatus() public view returns(string memory){
        if(startTime == 0){
            return "Voting has not started yet";
        }else if((endTime > block.timestamp) && stopVoting == false){
            return "Voting is in progress";
        }else{
            return "Voting Ended";
        }

    }

    function emergency()public onlyCommissioner() {
        stopVoting = true;
    }

    function result() external onlyCommissioner() {
        uint max = 0;
        uint winnerID;
        for(uint i = 0;i<nextCandidateID;i++){
            if(candidateDetails[i].votes > max){
                max = candidateDetails[i].votes;
                winnerID = i;
            }
        }

        winner = candidateDetails[winnerID].candidateAddress; 
    }
}
