// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Basic ERC20 Token Contract
contract EduToken {
    string public name = "EduToken";
    string public symbol = "EDU";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 initialSupply) {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_from != address(0), "Invalid address");
        require(_to != address(0), "Invalid address");
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Allowance exceeded");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function mint(address _to, uint256 _amount) public returns (bool success) {
        // Only the contract owner should be able to mint tokens
        // Implement ownership check here if needed
        totalSupply += _amount;
        balanceOf[_to] += _amount;
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    function burn(address _from, uint256 _amount) public returns (bool success) {
        // Only the contract owner should be able to burn tokens
        // Implement ownership check here if needed
        require(balanceOf[_from] >= _amount, "Insufficient balance");
        totalSupply -= _amount;
        balanceOf[_from] -= _amount;
        emit Transfer(_from, address(0), _amount);
        return true;
    }
}

// Tokenized Competition Contract
contract TokenizedCompetition {
    EduToken public token;

    struct Participant {
        address addr;
        uint256 score;
    }

    mapping(address => Participant) public participants;
    address[] public participantAddresses;
    
    uint256 public competitionEndTime;
    address public winner;
    uint256 public winningScore;

    address private owner;

    event ParticipantRegistered(address participant);
    event ScoresUpdated(address participant, uint256 score);
    event CompetitionEnded(address winner, uint256 winningScore);
    event TokensAwarded(address winner, uint256 amount);

    constructor(address tokenAddress, uint256 durationInMinutes) {
        token = EduToken(tokenAddress);
        competitionEndTime = block.timestamp + (durationInMinutes * 1 minutes);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier onlyBeforeEnd() {
        require(block.timestamp < competitionEndTime, "Competition has ended");
        _;
    }

    modifier onlyAfterEnd() {
        require(block.timestamp >= competitionEndTime, "Competition has not ended");
        _;
    }

    function registerParticipant(address _participant) external onlyOwner onlyBeforeEnd {
        require(participants[_participant].addr == address(0), "Participant already registered");
        participants[_participant] = Participant(_participant, 0);
        participantAddresses.push(_participant);
        emit ParticipantRegistered(_participant);
    }

    function updateScore(address _participant, uint256 _score) external onlyOwner onlyBeforeEnd {
        require(participants[_participant].addr != address(0), "Participant not registered");
        participants[_participant].score = _score;
        emit ScoresUpdated(_participant, _score);
    }

    function endCompetition() external onlyOwner onlyBeforeEnd {
        competitionEndTime = block.timestamp;
        determineWinner();
        emit CompetitionEnded(winner, winningScore);
    }

    function determineWinner() internal {
        uint256 highestScore = 0;
        address topParticipant = address(0);
        for (uint i = 0; i < participantAddresses.length; i++) {
            address participant = participantAddresses[i];
            if (participants[participant].score > highestScore) {
                highestScore = participants[participant].score;
                topParticipant = participant;
            }
        }
        winner = topParticipant;
        winningScore = highestScore;
    }

    function awardTokens() external onlyOwner onlyAfterEnd {
        require(winner != address(0), "No winner determined");
        uint256 rewardAmount = 1000 * 10**18; // Example reward amount
        token.mint(winner, rewardAmount);
        emit TokensAwarded(winner, rewardAmount);
    }

    function getParticipants() external view returns (address[] memory) {
        return participantAddresses;
    }

    function getScore(address _participant) external view returns (uint256) {
        return participants[_participant].score;
    }

    function getCompetitionDetails() external view returns (address, uint256, uint256) {
        return (winner, winningScore, competitionEndTime);
    }
}
