pragma solidity ^0.5.2;

//DAO is like closed ended fund

contract DAO {
    modifier onlyInvestors() {
        require(investors[msg.sender] == true, "Only Investors");
        _;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only Admin");
        _;
    }

    struct Proposal {
        uint256 id;
        string name;
        uint256 amount;
        address payable recipient;
        uint256 votes;
        uint256 end;
        bool executed;
    }
    
    mapping(uint256 => Proposal) public proposals;
    
    mapping(address => bool) public investors;
    
    mapping(address => uint256) public shares;
    
    mapping(address => mapping(uint256 => bool)) public votes;
    
    uint256 public totalShares;
    
    uint256 public availableFunds;
    
    uint256 public contributionEnd;
    
    uint256 public nextProposalId;
    
    uint256 public voteTime;
    
    uint256 public quorum;
    
    address public admin;
    
    constructor(uint256 contributionTime, uint256 _voteTime, uint256 _quorum) public {
        require(_quorum < 100 && _quorum > 0);
        voteTime = _voteTime;
        quorum = _quorum;
        admin = msg.sender;
        contributionEnd = now + contributionTime;
    }
    
    function contribute() payable external {
        require(now < contributionEnd, "Cannot Contribute after closing period");
        investors[msg.sender] = true;
        shares[msg.sender] += msg.value;
        totalShares += msg.value;
        availableFunds += msg.value;
    }
    
    function redeemShare(uint256 amount) external {
        require(shares[msg.sender] >= amount, "Not Enough Shares to Redeem");
        require(availableFunds >= amount, "Not Enough Funds Available");
        shares[msg.sender] -= amount;
        availableFunds -= amount;
        msg.sender.transfer(amount);
        
    }
    
    function transferShare(uint256 amount, address to) external {
        require(shares[msg.sender] >= amount, "Not Enough Shares to Redeem");
        shares[msg.sender] -= amount;
        shares[to] += amount;
        investors[to] = true;
    }
    
    function createProposal(string calldata name, uint256 amount, address payable recipient) external onlyInvestors() {
        require(availableFunds >= amount, "Amount too big");
        proposals[nextProposalId] = Proposal(nextProposalId, name, amount, recipient, 0, now + voteTime, false);
        availableFunds -= amount;
        nextProposalId++;
    }
    
    function vote(uint256 proposalId) external onlyInvestors() {
     Proposal storage proposal = proposals[proposalId];
     require(votes[msg.sender][proposalId] == false, "Investor can only vote once for a proposal");
     require(now < proposal.end, "Can only vote till end time");
     votes[msg.sender][proposalId] = true;
     proposal.votes += shares[msg.sender];
    }
    
     function _transferEther(uint256 amount, address payable to) internal {
        require(amount <= availableFunds, "Not enough funds");
        availableFunds -= amount;
        to.transfer(amount);
    }
    
    function executeProposal(uint256 proposalId) external onlyAdmin() {
        Proposal storage proposal = proposals[proposalId];
        require(now > proposal.end, "Proposal already executed");
        require(proposal.executed == false, "Proposal has already been executed");
        require((proposal.votes / totalShares) * 100 >= quorum, "Not emough votes");
        proposal.executed = true;
        _transferEther(proposal.amount, proposal.recipient);
    }
    
   
    
    function withdrawEther(uint256 amount, address payable _admin) external onlyAdmin() {
        _transferEther(amount, _admin);
    }
    
    function() payable external {
        availableFunds += msg.value;
    }
    
}