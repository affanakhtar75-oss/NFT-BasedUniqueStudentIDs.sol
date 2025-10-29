// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFT-Based Unique Student IDs
 * @dev Smart contract for managing student identity as non-transferable NFTs
 * @notice This contract creates soulbound tokens representing verified student credentials
 */
contract Project {
    
    // Student structure to store comprehensive identity data
    struct Student {
        uint256 tokenId;
        string fullName;
        string institutionName;
        uint256 enrollmentYear;
        string program;
        bool isActive;
        uint256 issuedAt;
    }
    
    // State variables
    address public admin;
    uint256 private tokenCounter;
    
    // Mappings for efficient data retrieval
    mapping(uint256 => Student) public students;
    mapping(address => uint256) public studentTokens;
    mapping(uint256 => address) public tokenOwners;
    
    // Events for tracking contract activities
    event StudentIDIssued(
        address indexed studentAddress,
        uint256 indexed tokenId,
        string fullName,
        string institutionName
    );
    
    event StudentIDRevoked(
        address indexed studentAddress,
        uint256 indexed tokenId
    );
    
    event StudentDataUpdated(
        uint256 indexed tokenId,
        string updatedField
    );
    
    // Modifiers for access control
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    modifier studentExists(uint256 _tokenId) {
        require(students[_tokenId].isActive, "Student ID does not exist or is inactive");
        _;
    }
    
    constructor() {
        admin = msg.sender;
        tokenCounter = 1;
    }
    
    /**
     * @dev Core Function 1: Issue a new Student ID NFT
     * @param _studentAddress Ethereum address of the student
     * @param _fullName Full legal name of the student
     * @param _institutionName Name of the educational institution
     * @param _enrollmentYear Year of enrollment
     * @param _program Academic program or course
     */
    function issueStudentID(
        address _studentAddress,
        string memory _fullName,
        string memory _institutionName,
        uint256 _enrollmentYear,
        string memory _program
    ) public onlyAdmin returns (uint256) {
        require(_studentAddress != address(0), "Invalid student address");
        require(studentTokens[_studentAddress] == 0, "Student already has an ID");
        require(bytes(_fullName).length > 0, "Name cannot be empty");
        require(bytes(_institutionName).length > 0, "Institution name cannot be empty");
        require(_enrollmentYear >= 1900 && _enrollmentYear <= 2100, "Invalid enrollment year");
        
        uint256 newTokenId = tokenCounter;
        
        students[newTokenId] = Student({
            tokenId: newTokenId,
            fullName: _fullName,
            institutionName: _institutionName,
            enrollmentYear: _enrollmentYear,
            program: _program,
            isActive: true,
            issuedAt: block.timestamp
        });
        
        studentTokens[_studentAddress] = newTokenId;
        tokenOwners[newTokenId] = _studentAddress;
        
        tokenCounter++;
        
        emit StudentIDIssued(_studentAddress, newTokenId, _fullName, _institutionName);
        
        return newTokenId;
    }
    
    /**
     * @dev Core Function 2: Verify Student Identity
     * @param _studentAddress Address to verify
     * @return bool Verification status
     * @return Student memory Student data if verified
     */
    function verifyStudentIdentity(address _studentAddress) 
        public 
        view 
        returns (bool, Student memory) 
    {
        uint256 tokenId = studentTokens[_studentAddress];
        
        if (tokenId == 0) {
            return (false, Student(0, "", "", 0, "", false, 0));
        }
        
        Student memory student = students[tokenId];
        
        if (!student.isActive) {
            return (false, student);
        }
        
        return (true, student);
    }
    
    /**
     * @dev Core Function 3: Revoke Student ID (for graduation, transfer, or violations)
     * @param _tokenId Token ID to revoke
     */
    function revokeStudentID(uint256 _tokenId) 
        public 
        onlyAdmin 
        studentExists(_tokenId) 
    {
        students[_tokenId].isActive = false;
        address studentAddress = tokenOwners[_tokenId];
        
        emit StudentIDRevoked(studentAddress, _tokenId);
    }
    
    /**
     * @dev Additional Function: Update student program (for course changes)
     * @param _tokenId Token ID to update
     * @param _newProgram New program name
     */
    function updateStudentProgram(uint256 _tokenId, string memory _newProgram) 
        public 
        onlyAdmin 
        studentExists(_tokenId) 
    {
        require(bytes(_newProgram).length > 0, "Program name cannot be empty");
        students[_tokenId].program = _newProgram;
        
        emit StudentDataUpdated(_tokenId, "program");
    }
    
    /**
     * @dev Get student details by address
     * @param _studentAddress Student's wallet address
     * @return Student data
     */
    function getStudentByAddress(address _studentAddress) 
        public 
        view 
        returns (Student memory) 
    {
        uint256 tokenId = studentTokens[_studentAddress];
        require(tokenId != 0, "No student ID found for this address");
        return students[tokenId];
    }
    
    /**
     * @dev Get total number of issued student IDs
     * @return uint256 Total count
     */
    function getTotalStudents() public view returns (uint256) {
        return tokenCounter - 1;
    }
    
    /**
     * @dev Transfer admin rights (for institutional governance)
     * @param _newAdmin Address of new administrator
     */
    function transferAdmin(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0), "Invalid admin address");
        admin = _newAdmin;
    }
}
