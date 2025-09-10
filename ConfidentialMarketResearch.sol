// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint32, euint8, ebool } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

contract ConfidentialMarketResearch is SepoliaConfig {

    address public owner;
    uint32 public currentSurveyId;

    struct Survey {
        string title;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        uint32 maxResponses;
        uint32 currentResponses;
        address creator;
    }

    struct EncryptedResponse {
        euint32 demographicAge;      // Encrypted age range (1-7: 18-25, 26-35, 36-45, 46-55, 56-65, 65+, prefer not to say)
        euint8 genderCategory;       // Encrypted gender (1-4: male, female, other, prefer not to say)
        euint8 incomeLevel;          // Encrypted income level (1-6: <25k, 25-50k, 50-75k, 75-100k, 100k+, prefer not to say)
        euint8 productRating;        // Encrypted product rating (1-10)
        euint8 purchaseIntent;       // Encrypted purchase intent (1-5: very unlikely to very likely)
        euint8 brandAwareness;       // Encrypted brand awareness (1-5: never heard to very familiar)
        uint256 timestamp;
        bool hasResponded;
    }

    struct MarketInsights {
        uint32 totalResponses;
        uint256 lastUpdated;
        bool insightsGenerated;
    }

    mapping(uint32 => Survey) public surveys;
    mapping(uint32 => mapping(address => EncryptedResponse)) public surveyResponses;
    mapping(uint32 => MarketInsights) public marketInsights;
    mapping(uint32 => address[]) public surveyParticipants;

    event SurveyCreated(uint32 indexed surveyId, string title, address indexed creator);
    event ResponseSubmitted(uint32 indexed surveyId, address indexed participant);
    event SurveyCompleted(uint32 indexed surveyId, uint32 totalResponses);
    event InsightsGenerated(uint32 indexed surveyId, uint256 timestamp);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier onlyActiveSurvey(uint32 _surveyId) {
        require(surveys[_surveyId].isActive, "Survey not active");
        require(block.timestamp >= surveys[_surveyId].startTime, "Survey not started");
        require(block.timestamp <= surveys[_surveyId].endTime, "Survey ended");
        _;
    }

    modifier onlyValidSurvey(uint32 _surveyId) {
        require(_surveyId > 0 && _surveyId <= currentSurveyId, "Invalid survey ID");
        _;
    }

    constructor() {
        owner = msg.sender;
        currentSurveyId = 0;
    }

    // Create a new market research survey
    function createSurvey(
        string memory _title,
        uint256 _duration,
        uint32 _maxResponses
    ) external returns (uint32) {
        require(bytes(_title).length > 0, "Title required");
        require(_duration > 0, "Duration must be positive");
        require(_maxResponses > 0, "Max responses must be positive");

        currentSurveyId++;

        surveys[currentSurveyId] = Survey({
            title: _title,
            startTime: block.timestamp,
            endTime: block.timestamp + _duration,
            isActive: true,
            maxResponses: _maxResponses,
            currentResponses: 0,
            creator: msg.sender
        });

        emit SurveyCreated(currentSurveyId, _title, msg.sender);
        return currentSurveyId;
    }

    // Submit encrypted market research response
    function submitResponse(
        uint32 _surveyId,
        uint32 _age,           // Age range 1-7
        uint8 _gender,         // Gender 1-4
        uint8 _income,         // Income level 1-6
        uint8 _rating,         // Product rating 1-10
        uint8 _intent,         // Purchase intent 1-5
        uint8 _awareness       // Brand awareness 1-5
    ) external onlyActiveSurvey(_surveyId) {
        require(!surveyResponses[_surveyId][msg.sender].hasResponded, "Already responded");
        require(_age >= 1 && _age <= 7, "Invalid age range");
        require(_gender >= 1 && _gender <= 4, "Invalid gender");
        require(_income >= 1 && _income <= 6, "Invalid income level");
        require(_rating >= 1 && _rating <= 10, "Invalid rating");
        require(_intent >= 1 && _intent <= 5, "Invalid purchase intent");
        require(_awareness >= 1 && _awareness <= 5, "Invalid brand awareness");
        require(surveys[_surveyId].currentResponses < surveys[_surveyId].maxResponses, "Survey full");

        _processEncryptedResponse(_surveyId, _age, _gender, _income, _rating, _intent, _awareness);

        surveyParticipants[_surveyId].push(msg.sender);
        surveys[_surveyId].currentResponses++;

        emit ResponseSubmitted(_surveyId, msg.sender);

        // Check if survey is complete
        if (surveys[_surveyId].currentResponses >= surveys[_surveyId].maxResponses) {
            surveys[_surveyId].isActive = false;
            emit SurveyCompleted(_surveyId, surveys[_surveyId].currentResponses);
        }
    }

    // Internal function to handle encryption and storage
    function _processEncryptedResponse(
        uint32 _surveyId,
        uint32 _age,
        uint8 _gender,
        uint8 _income,
        uint8 _rating,
        uint8 _intent,
        uint8 _awareness
    ) internal {
        // Create encrypted response struct directly
        surveyResponses[_surveyId][msg.sender].demographicAge = FHE.asEuint32(_age);
        surveyResponses[_surveyId][msg.sender].genderCategory = FHE.asEuint8(_gender);
        surveyResponses[_surveyId][msg.sender].incomeLevel = FHE.asEuint8(_income);
        surveyResponses[_surveyId][msg.sender].productRating = FHE.asEuint8(_rating);
        surveyResponses[_surveyId][msg.sender].purchaseIntent = FHE.asEuint8(_intent);
        surveyResponses[_surveyId][msg.sender].brandAwareness = FHE.asEuint8(_awareness);
        surveyResponses[_surveyId][msg.sender].timestamp = block.timestamp;
        surveyResponses[_surveyId][msg.sender].hasResponded = true;

        _grantPermissions(_surveyId);
    }

    // Internal function to handle FHE permissions
    function _grantPermissions(uint32 _surveyId) internal {
        EncryptedResponse storage response = surveyResponses[_surveyId][msg.sender];
        address creator = surveys[_surveyId].creator;

        // Grant access permissions for FHE operations
        FHE.allowThis(response.demographicAge);
        FHE.allowThis(response.genderCategory);
        FHE.allowThis(response.incomeLevel);
        FHE.allowThis(response.productRating);
        FHE.allowThis(response.purchaseIntent);
        FHE.allowThis(response.brandAwareness);

        // Allow survey creator to access encrypted data for analysis
        FHE.allow(response.demographicAge, creator);
        FHE.allow(response.genderCategory, creator);
        FHE.allow(response.incomeLevel, creator);
        FHE.allow(response.productRating, creator);
        FHE.allow(response.purchaseIntent, creator);
        FHE.allow(response.brandAwareness, creator);
    }

    // Close survey manually (only creator or owner)
    function closeSurvey(uint32 _surveyId) external onlyValidSurvey(_surveyId) {
        require(
            msg.sender == surveys[_surveyId].creator || msg.sender == owner,
            "Not authorized to close survey"
        );
        require(surveys[_surveyId].isActive, "Survey already closed");

        surveys[_surveyId].isActive = false;
        surveys[_surveyId].endTime = block.timestamp;

        emit SurveyCompleted(_surveyId, surveys[_surveyId].currentResponses);
    }

    // Generate market insights (placeholder for advanced FHE analytics)
    function generateInsights(uint32 _surveyId) external onlyValidSurvey(_surveyId) {
        require(
            msg.sender == surveys[_surveyId].creator || msg.sender == owner,
            "Not authorized"
        );
        require(!surveys[_surveyId].isActive, "Survey still active");
        require(surveys[_surveyId].currentResponses > 0, "No responses to analyze");

        marketInsights[_surveyId] = MarketInsights({
            totalResponses: surveys[_surveyId].currentResponses,
            lastUpdated: block.timestamp,
            insightsGenerated: true
        });

        emit InsightsGenerated(_surveyId, block.timestamp);
    }

    // Get survey information
    function getSurveyInfo(uint32 _surveyId) external view onlyValidSurvey(_surveyId) returns (
        string memory title,
        uint256 startTime,
        uint256 endTime,
        bool isActive,
        uint32 maxResponses,
        uint32 currentResponses,
        address creator
    ) {
        Survey storage survey = surveys[_surveyId];
        return (
            survey.title,
            survey.startTime,
            survey.endTime,
            survey.isActive,
            survey.maxResponses,
            survey.currentResponses,
            survey.creator
        );
    }

    // Check if user has responded to survey
    function hasUserResponded(uint32 _surveyId, address _user) external view onlyValidSurvey(_surveyId) returns (bool) {
        return surveyResponses[_surveyId][_user].hasResponded;
    }

    // Get participant count for a survey
    function getParticipantCount(uint32 _surveyId) external view onlyValidSurvey(_surveyId) returns (uint32) {
        return uint32(surveyParticipants[_surveyId].length);
    }

    // Get market insights summary
    function getMarketInsights(uint32 _surveyId) external view onlyValidSurvey(_surveyId) returns (
        uint32 totalResponses,
        uint256 lastUpdated,
        bool insightsGenerated
    ) {
        require(
            msg.sender == surveys[_surveyId].creator || msg.sender == owner,
            "Not authorized to view insights"
        );

        MarketInsights storage insights = marketInsights[_surveyId];
        return (
            insights.totalResponses,
            insights.lastUpdated,
            insights.insightsGenerated
        );
    }

    // Emergency stop (owner only)
    function emergencyStop(uint32 _surveyId) external onlyOwner onlyValidSurvey(_surveyId) {
        surveys[_surveyId].isActive = false;
        surveys[_surveyId].endTime = block.timestamp;
    }

    // Get current survey count
    function getTotalSurveys() external view returns (uint32) {
        return currentSurveyId;
    }
}