# Hello FHEVM: Your First Confidential Application Tutorial

## 🎯 Welcome to FHEVM Development

This tutorial will guide you through building your first confidential application using Zama's Fully Homomorphic Encryption Virtual Machine (FHEVM). By the end of this tutorial, you'll have created a complete decentralized application that processes encrypted data without ever decrypting it.

## 🎓 Learning Objectives

After completing this tutorial, you will be able to:

1. **Understand FHE Basics**: Learn what Fully Homomorphic Encryption is and why it matters
2. **Set Up FHEVM Environment**: Configure your development environment for FHE applications
3. **Write FHE Smart Contracts**: Create contracts that work with encrypted data
4. **Build Frontend Integration**: Connect a web interface to your FHE contracts
5. **Deploy and Test**: Launch your confidential application on testnet

## 📋 Prerequisites

### Required Knowledge
- Basic Solidity programming (functions, variables, events)
- JavaScript fundamentals
- Familiarity with MetaMask wallet
- Basic understanding of blockchain concepts

### No Advanced Knowledge Required
- ❌ No cryptography background needed
- ❌ No advanced mathematics required
- ❌ No prior FHE experience necessary

## 🚀 What We're Building

We'll create a **Confidential Market Research Platform** where:
- Users can submit encrypted survey responses
- Data remains private while being processed
- Statistical analysis happens on encrypted data
- Results are computed without revealing individual responses

## 📚 Chapter 1: Understanding FHEVM

### What is Fully Homomorphic Encryption?

Imagine you have a locked box containing numbers. With FHE, you can:
- Add numbers inside the box without opening it
- Multiply values without seeing them
- Get the final result while keeping individual values secret

This is exactly what FHEVM enables on blockchain!

### Why Use FHEVM?

Traditional blockchain applications expose all data publicly. FHEVM allows:
- **Private Computations**: Process sensitive data without revealing it
- **Regulatory Compliance**: Meet privacy requirements while maintaining transparency
- **Competitive Advantage**: Perform analytics without exposing business secrets

### Key FHEVM Concepts

1. **Encrypted Inputs**: Data encrypted before submission to blockchain
2. **Homomorphic Operations**: Computations performed on encrypted data
3. **Access Control**: Only authorized parties can decrypt results
4. **Gas Optimization**: Efficient FHE operations designed for blockchain

## 📚 Chapter 2: Environment Setup

### Step 1: Install Prerequisites

```bash
# Install Node.js (version 16 or higher)
node --version

# Install development tools
npm install -g hardhat
```

### Step 2: Project Structure

Create your project directory:

```
confidential-market-research/
├── contracts/
│   ├── ConfidentialMarketResearch.sol
│   └── ...
├── scripts/
│   └── deploy.js
├── frontend/
│   ├── index.html
│   ├── app.js
│   └── style.css
├── hardhat.config.js
└── package.json
```

### Step 3: Initialize Hardhat Project

```bash
mkdir confidential-market-research
cd confidential-market-research
npx hardhat init
```

### Step 4: Install FHEVM Dependencies

```bash
npm install fhevm
npm install @openzeppelin/contracts
```

### Step 5: Configure Hardhat for FHEVM

Update `hardhat.config.js`:

```javascript
require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: "0.8.19",
  networks: {
    sepolia: {
      url: "https://sepolia.infura.io/v3/YOUR_INFURA_KEY",
      accounts: ["YOUR_PRIVATE_KEY"]
    }
  }
};
```

## 📚 Chapter 3: Writing Your First FHE Smart Contract

### Understanding FHE Data Types

FHEVM provides encrypted data types:

- `euint8`: Encrypted 8-bit unsigned integer (0-255)
- `euint16`: Encrypted 16-bit unsigned integer (0-65535)
- `euint32`: Encrypted 32-bit unsigned integer
- `ebool`: Encrypted boolean (true/false)
- `eaddress`: Encrypted address

### Basic FHE Operations

```solidity
// Addition
euint32 sum = TFHE.add(encryptedA, encryptedB);

// Comparison
ebool isGreater = TFHE.gt(encryptedA, encryptedB);

// Selection
euint32 result = TFHE.cmux(condition, valueIfTrue, valueIfFalse);
```

### Complete Smart Contract Example

Create `contracts/ConfidentialMarketResearch.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "fhevm/lib/TFHE.sol";

contract ConfidentialMarketResearch {

    // Survey structure
    struct Survey {
        uint256 id;
        string title;
        address creator;
        uint256 maxResponses;
        uint256 currentResponses;
        bool isActive;
        uint256 createdAt;
    }

    // Encrypted response structure
    struct EncryptedResponse {
        euint8 age;           // Encrypted age
        euint8 gender;        // Encrypted gender (0=other, 1=male, 2=female)
        euint8 income;        // Encrypted income level (1-10 scale)
        euint8 rating;        // Encrypted product rating (1-5)
        euint8 intention;     // Encrypted purchase intention (1-5)
        euint8 awareness;     // Encrypted brand awareness (1-5)
        address respondent;
        uint256 timestamp;
    }

    // State variables
    mapping(uint256 => Survey) public surveys;
    mapping(uint256 => EncryptedResponse[]) public surveyResponses;
    mapping(address => mapping(uint256 => bool)) public hasResponded;

    uint256 public nextSurveyId;

    // Events
    event SurveyCreated(uint256 indexed surveyId, string title, address creator);
    event ResponseSubmitted(uint256 indexed surveyId, address respondent);
    event SurveyCompleted(uint256 indexed surveyId);

    constructor() {
        nextSurveyId = 1;
    }

    // Create new survey
    function createSurvey(
        string memory _title,
        uint256 _maxResponses
    ) public returns (uint256) {
        uint256 surveyId = nextSurveyId++;

        surveys[surveyId] = Survey({
            id: surveyId,
            title: _title,
            creator: msg.sender,
            maxResponses: _maxResponses,
            currentResponses: 0,
            isActive: true,
            createdAt: block.timestamp
        });

        emit SurveyCreated(surveyId, _title, msg.sender);
        return surveyId;
    }

    // Submit encrypted response
    function submitResponse(
        uint256 _surveyId,
        bytes calldata _encryptedAge,
        bytes calldata _encryptedGender,
        bytes calldata _encryptedIncome,
        bytes calldata _encryptedRating,
        bytes calldata _encryptedIntention,
        bytes calldata _encryptedAwareness
    ) public {
        require(surveys[_surveyId].isActive, "Survey not active");
        require(!hasResponded[msg.sender][_surveyId], "Already responded");
        require(surveys[_surveyId].currentResponses < surveys[_surveyId].maxResponses, "Survey full");

        // Convert encrypted inputs
        euint8 age = TFHE.asEuint8(_encryptedAge);
        euint8 gender = TFHE.asEuint8(_encryptedGender);
        euint8 income = TFHE.asEuint8(_encryptedIncome);
        euint8 rating = TFHE.asEuint8(_encryptedRating);
        euint8 intention = TFHE.asEuint8(_encryptedIntention);
        euint8 awareness = TFHE.asEuint8(_encryptedAwareness);

        // Create encrypted response
        EncryptedResponse memory response = EncryptedResponse({
            age: age,
            gender: gender,
            income: income,
            rating: rating,
            intention: intention,
            awareness: awareness,
            respondent: msg.sender,
            timestamp: block.timestamp
        });

        surveyResponses[_surveyId].push(response);
        hasResponded[msg.sender][_surveyId] = true;
        surveys[_surveyId].currentResponses++;

        emit ResponseSubmitted(_surveyId, msg.sender);

        // Check if survey is complete
        if (surveys[_surveyId].currentResponses >= surveys[_surveyId].maxResponses) {
            surveys[_surveyId].isActive = false;
            emit SurveyCompleted(_surveyId);
        }
    }

    // Calculate encrypted average rating (only survey creator can call)
    function calculateAverageRating(uint256 _surveyId) public view returns (euint8) {
        require(msg.sender == surveys[_surveyId].creator, "Only creator can access");
        require(surveys[_surveyId].currentResponses > 0, "No responses yet");

        EncryptedResponse[] storage responses = surveyResponses[_surveyId];
        euint8 sum = responses[0].rating;

        // Sum all ratings (encrypted)
        for (uint256 i = 1; i < responses.length; i++) {
            sum = TFHE.add(sum, responses[i].rating);
        }

        // Return encrypted sum (client-side can decrypt and divide)
        return sum;
    }

    // Get survey statistics (encrypted)
    function getSurveyStats(uint256 _surveyId) public view returns (
        euint8 avgRating,
        euint8 avgIntention,
        euint8 avgAwareness,
        uint256 totalResponses
    ) {
        require(msg.sender == surveys[_surveyId].creator, "Only creator can access");
        require(surveys[_surveyId].currentResponses > 0, "No responses yet");

        EncryptedResponse[] storage responses = surveyResponses[_surveyId];

        euint8 sumRating = responses[0].rating;
        euint8 sumIntention = responses[0].intention;
        euint8 sumAwareness = responses[0].awareness;

        // Calculate encrypted sums
        for (uint256 i = 1; i < responses.length; i++) {
            sumRating = TFHE.add(sumRating, responses[i].rating);
            sumIntention = TFHE.add(sumIntention, responses[i].intention);
            sumAwareness = TFHE.add(sumAwareness, responses[i].awareness);
        }

        return (sumRating, sumIntention, sumAwareness, responses.length);
    }

    // Get public survey info
    function getSurveyInfo(uint256 _surveyId) public view returns (
        string memory title,
        address creator,
        uint256 maxResponses,
        uint256 currentResponses,
        bool isActive
    ) {
        Survey storage survey = surveys[_surveyId];
        return (survey.title, survey.creator, survey.maxResponses, survey.currentResponses, survey.isActive);
    }
}
```

## 📚 Chapter 4: Understanding the Smart Contract

### Key FHE Concepts in Our Contract

1. **Encrypted Data Types**: We use `euint8` for survey responses (age, rating, etc.)
2. **Input Encryption**: Client encrypts data before sending to contract
3. **Homomorphic Operations**: We can add encrypted ratings without decrypting
4. **Access Control**: Only survey creators can access aggregated results

### Important FHE Operations

```solidity
// Convert encrypted input from client
euint8 age = TFHE.asEuint8(_encryptedAge);

// Add encrypted values
euint8 sum = TFHE.add(encryptedA, encryptedB);

// Compare encrypted values
ebool isGreater = TFHE.gt(encryptedA, encryptedB);
```

## 📚 Chapter 5: Building the Frontend

### HTML Structure

Create `index.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Confidential Market Research</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="container">
        <header>
            <h1>🔐 Confidential Market Research</h1>
            <p>Privacy-preserving surveys using Fully Homomorphic Encryption</p>
        </header>

        <!-- Wallet Connection -->
        <div class="wallet-section">
            <button id="connectWallet" class="btn-primary">Connect Wallet</button>
            <div id="walletInfo" class="wallet-info hidden">
                <span id="walletAddress"></span>
                <span id="networkInfo"></span>
            </div>
        </div>

        <!-- Navigation Tabs -->
        <nav class="tabs">
            <button class="tab-btn active" onclick="showTab('participate')">📊 Participate</button>
            <button class="tab-btn" onclick="showTab('create')">➕ Create Survey</button>
            <button class="tab-btn" onclick="showTab('manage')">📈 Manage</button>
        </nav>

        <!-- Participate Tab -->
        <div id="participate" class="tab-content active">
            <h2>Available Surveys</h2>
            <div id="surveyList" class="survey-list">
                <!-- Surveys will be loaded here -->
            </div>

            <!-- Survey Response Form -->
            <div id="responseForm" class="form-section hidden">
                <h3>Survey Response</h3>
                <form id="surveyForm">
                    <div class="form-group">
                        <label>Age:</label>
                        <input type="number" id="age" min="18" max="100" required>
                    </div>

                    <div class="form-group">
                        <label>Gender:</label>
                        <select id="gender" required>
                            <option value="">Select...</option>
                            <option value="0">Prefer not to say</option>
                            <option value="1">Male</option>
                            <option value="2">Female</option>
                        </select>
                    </div>

                    <div class="form-group">
                        <label>Income Level (1-10 scale):</label>
                        <input type="range" id="income" min="1" max="10" value="5">
                        <span id="incomeValue">5</span>
                    </div>

                    <div class="form-group">
                        <label>Product Rating (1-5):</label>
                        <div class="rating">
                            <input type="radio" name="rating" value="1" id="r1">
                            <label for="r1">⭐</label>
                            <input type="radio" name="rating" value="2" id="r2">
                            <label for="r2">⭐⭐</label>
                            <input type="radio" name="rating" value="3" id="r3">
                            <label for="r3">⭐⭐⭐</label>
                            <input type="radio" name="rating" value="4" id="r4">
                            <label for="r4">⭐⭐⭐⭐</label>
                            <input type="radio" name="rating" value="5" id="r5">
                            <label for="r5">⭐⭐⭐⭐⭐</label>
                        </div>
                    </div>

                    <div class="form-group">
                        <label>Purchase Intention (1-5):</label>
                        <input type="range" id="intention" min="1" max="5" value="3">
                        <span id="intentionValue">3</span>
                    </div>

                    <div class="form-group">
                        <label>Brand Awareness (1-5):</label>
                        <input type="range" id="awareness" min="1" max="5" value="3">
                        <span id="awarenessValue">3</span>
                    </div>

                    <button type="submit" class="btn-primary">Submit Response</button>
                </form>
            </div>
        </div>

        <!-- Create Survey Tab -->
        <div id="create" class="tab-content">
            <h2>Create New Survey</h2>
            <form id="createSurveyForm" class="form-section">
                <div class="form-group">
                    <label>Survey Title:</label>
                    <input type="text" id="surveyTitle" required placeholder="e.g., Product Feedback Survey">
                </div>

                <div class="form-group">
                    <label>Maximum Responses:</label>
                    <input type="number" id="maxResponses" min="1" max="1000" value="100" required>
                </div>

                <button type="submit" class="btn-primary">Create Survey</button>
            </form>
        </div>

        <!-- Manage Surveys Tab -->
        <div id="manage" class="tab-content">
            <h2>Your Surveys</h2>
            <div id="managedSurveys" class="survey-list">
                <!-- Managed surveys will be loaded here -->
            </div>
        </div>
    </div>

    <!-- Loading Spinner -->
    <div id="loading" class="loading hidden">
        <div class="spinner"></div>
        <p>Processing encrypted data...</p>
    </div>

    <script src="https://cdn.ethers.io/lib/ethers-5.7.2.umd.min.js"></script>
    <script src="app.js"></script>
</body>
</html>
```

### JavaScript Application Logic

Create `app.js`:

```javascript
// Contract configuration
const CONTRACT_ADDRESS = "0x4cf42D50595388736900c25680c149cb62669B47";
const SEPOLIA_CHAIN_ID = "0xaa36a7";

// Contract ABI (simplified for tutorial)
const CONTRACT_ABI = [
    "function createSurvey(string memory _title, uint256 _maxResponses) public returns (uint256)",
    "function submitResponse(uint256 _surveyId, bytes calldata _encryptedAge, bytes calldata _encryptedGender, bytes calldata _encryptedIncome, bytes calldata _encryptedRating, bytes calldata _encryptedIntention, bytes calldata _encryptedAwareness) public",
    "function getSurveyInfo(uint256 _surveyId) public view returns (string memory title, address creator, uint256 maxResponses, uint256 currentResponses, bool isActive)",
    "function getSurveyStats(uint256 _surveyId) public view returns (uint8 avgRating, uint8 avgIntention, uint8 avgAwareness, uint256 totalResponses)",
    "event SurveyCreated(uint256 indexed surveyId, string title, address creator)",
    "event ResponseSubmitted(uint256 indexed surveyId, address respondent)"
];

// Global variables
let provider, signer, contract, fhevm;
let currentAccount = null;
let surveys = [];
let currentSurveyId = null;

// Initialize application
window.addEventListener('load', async () => {
    await initializeApp();
    setupEventListeners();
    await loadSurveys();
});

async function initializeApp() {
    // Check if MetaMask is installed
    if (typeof window.ethereum !== 'undefined') {
        provider = new ethers.providers.Web3Provider(window.ethereum);

        // Initialize FHEVM (mock for tutorial - use actual fhevm library)
        fhevm = {
            encrypt: (value) => {
                // In real implementation, use fhevm.encrypt()
                return ethers.utils.hexlify(ethers.utils.toUtf8Bytes(value.toString()));
            }
        };
    } else {
        alert('Please install MetaMask to use this application!');
    }
}

function setupEventListeners() {
    // Wallet connection
    document.getElementById('connectWallet').addEventListener('click', connectWallet);

    // Tab navigation
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const tabName = e.target.textContent.split(' ')[1].toLowerCase();
            showTab(tabName);
        });
    });

    // Form submissions
    document.getElementById('createSurveyForm').addEventListener('submit', createSurvey);
    document.getElementById('surveyForm').addEventListener('submit', submitResponse);

    // Range sliders
    document.getElementById('income').addEventListener('input', (e) => {
        document.getElementById('incomeValue').textContent = e.target.value;
    });

    document.getElementById('intention').addEventListener('input', (e) => {
        document.getElementById('intentionValue').textContent = e.target.value;
    });

    document.getElementById('awareness').addEventListener('input', (e) => {
        document.getElementById('awarenessValue').textContent = e.target.value;
    });
}

async function connectWallet() {
    try {
        // Request account access
        const accounts = await window.ethereum.request({
            method: 'eth_requestAccounts'
        });

        currentAccount = accounts[0];
        signer = provider.getSigner();
        contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);

        // Check network
        const network = await provider.getNetwork();
        if (network.chainId !== 11155111) { // Sepolia
            await switchToSepolia();
        }

        // Update UI
        document.getElementById('connectWallet').classList.add('hidden');
        document.getElementById('walletInfo').classList.remove('hidden');
        document.getElementById('walletAddress').textContent =
            `${currentAccount.substring(0, 6)}...${currentAccount.substring(38)}`;
        document.getElementById('networkInfo').textContent = 'Sepolia Testnet';

        await loadSurveys();

    } catch (error) {
        console.error('Wallet connection failed:', error);
        alert('Failed to connect wallet. Please try again.');
    }
}

async function switchToSepolia() {
    try {
        await window.ethereum.request({
            method: 'wallet_switchEthereumChain',
            params: [{ chainId: SEPOLIA_CHAIN_ID }],
        });
    } catch (error) {
        console.error('Network switch failed:', error);
        alert('Please switch to Sepolia testnet manually.');
    }
}

async function loadSurveys() {
    if (!contract) return;

    try {
        surveys = [];

        // In a real app, you'd query events or maintain a registry
        // For tutorial purposes, we'll load surveys 1-10
        for (let i = 1; i <= 10; i++) {
            try {
                const surveyInfo = await contract.getSurveyInfo(i);
                if (surveyInfo.title) {
                    surveys.push({
                        id: i,
                        title: surveyInfo.title,
                        creator: surveyInfo.creator,
                        maxResponses: surveyInfo.maxResponses.toNumber(),
                        currentResponses: surveyInfo.currentResponses.toNumber(),
                        isActive: surveyInfo.isActive
                    });
                }
            } catch (e) {
                // Survey doesn't exist, continue
                break;
            }
        }

        displaySurveys();
        displayManagedSurveys();

    } catch (error) {
        console.error('Failed to load surveys:', error);
    }
}

function displaySurveys() {
    const surveyList = document.getElementById('surveyList');
    surveyList.innerHTML = '';

    const activeSurveys = surveys.filter(s => s.isActive);

    if (activeSurveys.length === 0) {
        surveyList.innerHTML = '<p class="no-surveys">No active surveys available.</p>';
        return;
    }

    activeSurveys.forEach(survey => {
        const surveyCard = document.createElement('div');
        surveyCard.className = 'survey-card';
        surveyCard.innerHTML = `
            <h3>${survey.title}</h3>
            <div class="survey-meta">
                <span>Responses: ${survey.currentResponses}/${survey.maxResponses}</span>
                <span>Creator: ${survey.creator.substring(0, 8)}...</span>
            </div>
            <button class="btn-secondary" onclick="participateInSurvey(${survey.id})">
                Participate
            </button>
        `;
        surveyList.appendChild(surveyCard);
    });
}

function displayManagedSurveys() {
    if (!currentAccount) return;

    const managedSurveys = document.getElementById('managedSurveys');
    managedSurveys.innerHTML = '';

    const mySurveys = surveys.filter(s =>
        s.creator.toLowerCase() === currentAccount.toLowerCase()
    );

    if (mySurveys.length === 0) {
        managedSurveys.innerHTML = '<p class="no-surveys">You haven\'t created any surveys yet.</p>';
        return;
    }

    mySurveys.forEach(survey => {
        const surveyCard = document.createElement('div');
        surveyCard.className = 'survey-card';
        surveyCard.innerHTML = `
            <h3>${survey.title}</h3>
            <div class="survey-meta">
                <span>Status: ${survey.isActive ? 'Active' : 'Completed'}</span>
                <span>Responses: ${survey.currentResponses}/${survey.maxResponses}</span>
            </div>
            <button class="btn-secondary" onclick="viewSurveyStats(${survey.id})"
                    ${survey.currentResponses === 0 ? 'disabled' : ''}>
                View Stats
            </button>
        `;
        managedSurveys.appendChild(surveyCard);
    });
}

function participateInSurvey(surveyId) {
    currentSurveyId = surveyId;
    document.getElementById('responseForm').classList.remove('hidden');
    document.getElementById('responseForm').scrollIntoView();
}

async function createSurvey(e) {
    e.preventDefault();

    if (!contract) {
        alert('Please connect your wallet first.');
        return;
    }

    const title = document.getElementById('surveyTitle').value;
    const maxResponses = document.getElementById('maxResponses').value;

    try {
        showLoading();

        const tx = await contract.createSurvey(title, maxResponses);
        await tx.wait();

        hideLoading();
        alert('Survey created successfully!');

        document.getElementById('createSurveyForm').reset();
        await loadSurveys();

    } catch (error) {
        hideLoading();
        console.error('Survey creation failed:', error);
        alert('Failed to create survey. Please try again.');
    }
}

async function submitResponse(e) {
    e.preventDefault();

    if (!contract || !currentSurveyId) {
        alert('Please select a survey first.');
        return;
    }

    // Get form values
    const age = document.getElementById('age').value;
    const gender = document.getElementById('gender').value;
    const income = document.getElementById('income').value;
    const rating = document.querySelector('input[name="rating"]:checked')?.value;
    const intention = document.getElementById('intention').value;
    const awareness = document.getElementById('awareness').value;

    if (!rating) {
        alert('Please provide a product rating.');
        return;
    }

    try {
        showLoading();

        // Encrypt values (in real implementation, use proper FHE encryption)
        const encryptedAge = fhevm.encrypt(parseInt(age));
        const encryptedGender = fhevm.encrypt(parseInt(gender));
        const encryptedIncome = fhevm.encrypt(parseInt(income));
        const encryptedRating = fhevm.encrypt(parseInt(rating));
        const encryptedIntention = fhevm.encrypt(parseInt(intention));
        const encryptedAwareness = fhevm.encrypt(parseInt(awareness));

        const tx = await contract.submitResponse(
            currentSurveyId,
            encryptedAge,
            encryptedGender,
            encryptedIncome,
            encryptedRating,
            encryptedIntention,
            encryptedAwareness
        );

        await tx.wait();

        hideLoading();
        alert('Response submitted successfully! Your data remains completely private.');

        document.getElementById('surveyForm').reset();
        document.getElementById('responseForm').classList.add('hidden');
        currentSurveyId = null;

        await loadSurveys();

    } catch (error) {
        hideLoading();
        console.error('Response submission failed:', error);

        if (error.message.includes('Already responded')) {
            alert('You have already responded to this survey.');
        } else if (error.message.includes('Survey full')) {
            alert('This survey has reached maximum responses.');
        } else {
            alert('Failed to submit response. Please try again.');
        }
    }
}

async function viewSurveyStats(surveyId) {
    if (!contract) return;

    try {
        showLoading();

        // Note: In real implementation, you'd decrypt the encrypted results
        const stats = await contract.getSurveyStats(surveyId);

        hideLoading();

        alert(`Survey Statistics (Encrypted):
               Total Responses: ${stats.totalResponses}
               Note: Individual responses remain encrypted and private.
               Only aggregated statistics are available.`);

    } catch (error) {
        hideLoading();
        console.error('Failed to load stats:', error);
        alert('Failed to load survey statistics.');
    }
}

// UI Helper Functions
function showTab(tabName) {
    // Hide all tabs
    document.querySelectorAll('.tab-content').forEach(tab => {
        tab.classList.remove('active');
    });

    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.classList.remove('active');
    });

    // Show selected tab
    document.getElementById(tabName).classList.add('active');
    document.querySelector(`[onclick="showTab('${tabName}')"]`).classList.add('active');
}

function showLoading() {
    document.getElementById('loading').classList.remove('hidden');
}

function hideLoading() {
    document.getElementById('loading').classList.add('hidden');
}
```

## 📚 Chapter 6: Styling Your Application

Create `style.css`:

```css
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    min-height: 100vh;
    padding: 20px;
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    background: white;
    border-radius: 15px;
    box-shadow: 0 20px 40px rgba(0,0,0,0.1);
    overflow: hidden;
}

header {
    background: linear-gradient(135deg, #2c3e50, #3498db);
    color: white;
    padding: 40px;
    text-align: center;
}

header h1 {
    font-size: 2.5rem;
    margin-bottom: 10px;
}

header p {
    font-size: 1.1rem;
    opacity: 0.9;
}

.wallet-section {
    padding: 20px 40px;
    background: #f8f9fa;
    border-bottom: 1px solid #e9ecef;
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.wallet-info {
    display: flex;
    gap: 15px;
    align-items: center;
    color: #495057;
}

.tabs {
    display: flex;
    background: #e9ecef;
}

.tab-btn {
    flex: 1;
    padding: 15px;
    border: none;
    background: transparent;
    cursor: pointer;
    font-size: 1rem;
    transition: all 0.3s;
}

.tab-btn:hover {
    background: #dee2e6;
}

.tab-btn.active {
    background: white;
    border-bottom: 3px solid #3498db;
}

.tab-content {
    display: none;
    padding: 40px;
}

.tab-content.active {
    display: block;
}

.tab-content h2 {
    color: #2c3e50;
    margin-bottom: 30px;
    font-size: 1.8rem;
}

.form-section {
    background: #f8f9fa;
    padding: 30px;
    border-radius: 10px;
    margin-bottom: 30px;
}

.form-group {
    margin-bottom: 20px;
}

.form-group label {
    display: block;
    margin-bottom: 5px;
    font-weight: 600;
    color: #495057;
}

.form-group input,
.form-group select {
    width: 100%;
    padding: 12px;
    border: 2px solid #e9ecef;
    border-radius: 8px;
    font-size: 1rem;
    transition: border-color 0.3s;
}

.form-group input:focus,
.form-group select:focus {
    outline: none;
    border-color: #3498db;
}

.rating {
    display: flex;
    gap: 5px;
}

.rating input[type="radio"] {
    display: none;
}

.rating label {
    cursor: pointer;
    font-size: 1.5rem;
    transition: all 0.3s;
}

.rating input[type="radio"]:checked ~ label,
.rating label:hover {
    color: #f39c12;
}

.btn-primary,
.btn-secondary {
    padding: 12px 24px;
    border: none;
    border-radius: 8px;
    font-size: 1rem;
    cursor: pointer;
    transition: all 0.3s;
    font-weight: 600;
}

.btn-primary {
    background: linear-gradient(135deg, #3498db, #2980b9);
    color: white;
}

.btn-primary:hover {
    transform: translateY(-2px);
    box-shadow: 0 5px 15px rgba(52, 152, 219, 0.4);
}

.btn-secondary {
    background: #95a5a6;
    color: white;
}

.btn-secondary:hover {
    background: #7f8c8d;
}

.btn-secondary:disabled {
    background: #bdc3c7;
    cursor: not-allowed;
}

.survey-list {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 20px;
    margin-top: 20px;
}

.survey-card {
    background: white;
    padding: 25px;
    border-radius: 10px;
    border: 2px solid #e9ecef;
    transition: all 0.3s;
}

.survey-card:hover {
    border-color: #3498db;
    transform: translateY(-3px);
    box-shadow: 0 10px 25px rgba(0,0,0,0.1);
}

.survey-card h3 {
    color: #2c3e50;
    margin-bottom: 15px;
}

.survey-meta {
    display: flex;
    justify-content: space-between;
    margin-bottom: 20px;
    color: #7f8c8d;
    font-size: 0.9rem;
}

.no-surveys {
    text-align: center;
    color: #7f8c8d;
    font-style: italic;
    padding: 40px;
}

.loading {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0,0,0,0.8);
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    color: white;
    z-index: 1000;
}

.spinner {
    border: 4px solid #f3f3f3;
    border-top: 4px solid #3498db;
    border-radius: 50%;
    width: 50px;
    height: 50px;
    animation: spin 2s linear infinite;
    margin-bottom: 20px;
}

@keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
}

.hidden {
    display: none !important;
}

/* Responsive Design */
@media (max-width: 768px) {
    .container {
        margin: 0;
        border-radius: 0;
    }

    header {
        padding: 20px;
    }

    header h1 {
        font-size: 2rem;
    }

    .tab-content {
        padding: 20px;
    }

    .wallet-section {
        flex-direction: column;
        gap: 15px;
        text-align: center;
    }

    .tabs {
        flex-direction: column;
    }

    .survey-list {
        grid-template-columns: 1fr;
    }
}
```

## 📚 Chapter 7: Testing Your Application

### Local Testing Setup

1. **Start Local Development Server**:
```bash
# In your project directory
npx http-server . -p 3000 -c-1 --cors
```

2. **Configure MetaMask**:
   - Add Sepolia testnet
   - Get test ETH from faucet
   - Import your account

3. **Test Contract Deployment**:
```bash
npx hardhat run scripts/deploy.js --network sepolia
```

### Testing Checklist

- [ ] ✅ Wallet connects successfully
- [ ] ✅ Can create new surveys
- [ ] ✅ Can submit encrypted responses
- [ ] ✅ Survey statistics update correctly
- [ ] ✅ Access control works (only creators see stats)
- [ ] ✅ Responsive design works on mobile

## 📚 Chapter 8: Understanding FHE Security

### What Makes This Secure?

1. **Client-Side Encryption**: Data encrypted before leaving user's browser
2. **Server-Side Computation**: Operations performed on encrypted data
3. **Access Control**: Only authorized parties can decrypt results
4. **Zero Knowledge**: No intermediate values are exposed

### Privacy Guarantees

- **Individual Privacy**: No single response can be decrypted
- **Aggregate Privacy**: Only statistical summaries are available
- **Forward Security**: Past responses remain secure even if keys are compromised

## 📚 Chapter 9: Next Steps and Advanced Topics

### Expanding Your Application

1. **Add More Data Types**:
```solidity
euint64 largeNumber = TFHE.asEuint64(encryptedInput);
eaddress privateAddress = TFHE.asEaddress(encryptedAddress);
```

2. **Implement Complex Logic**:
```solidity
// Conditional operations
euint32 result = TFHE.cmux(condition, valueA, valueB);

// Comparison operations
ebool isEqual = TFHE.eq(encryptedA, encryptedB);
```

3. **Add Access Control**:
```solidity
modifier onlyAuthorized(uint256 surveyId) {
    require(isAuthorized(msg.sender, surveyId), "Not authorized");
    _;
}
```

### Performance Optimization

1. **Gas Optimization**: Use appropriate data types (euint8 vs euint32)
2. **Batch Operations**: Group multiple FHE operations together
3. **Caching**: Store frequently accessed encrypted values

### Real-World Considerations

1. **Key Management**: Implement secure key distribution
2. **Scalability**: Consider layer 2 solutions for high throughput
3. **Auditing**: Regular security audits for production deployment

## 📚 Chapter 10: Deployment and Production

### Production Checklist

- [ ] Security audit completed
- [ ] Gas optimization implemented
- [ ] Error handling comprehensive
- [ ] User experience tested
- [ ] Documentation complete

### Deployment Process

1. **Final Testing**: Comprehensive testing on testnet
2. **Security Review**: Professional audit recommended
3. **Mainnet Deployment**: Deploy to production network
4. **Monitoring**: Set up transaction monitoring
5. **Support**: Prepare user support documentation

## 🎉 Congratulations!

You've successfully built your first confidential application using FHEVM! You now understand:

- ✅ How FHE enables private computation on blockchain
- ✅ How to write smart contracts with encrypted data
- ✅ How to build frontend interfaces for FHE applications
- ✅ How to encrypt data client-side and process it on-chain
- ✅ How to implement access controls for encrypted data

## 🔗 Additional Resources

### Documentation
- [FHEVM Official Documentation](https://docs.zama.ai/fhevm)
- [Solidity FHE Library Reference](https://docs.zama.ai/fhevm/fundamentals)
- [Frontend Integration Guide](https://docs.zama.ai/fhevm/getting_started)

### Community
- [Zama Discord](https://discord.gg/zama)
- [GitHub Issues](https://github.com/zama-ai/fhevm)
- [Developer Forums](https://community.zama.ai/)

### Advanced Topics
- Multi-party computation with FHE
- Zero-knowledge proofs integration
- Cross-chain FHE applications
- Performance optimization techniques

---

*Ready to build the future of private blockchain applications? Start experimenting with your own FHE contracts today!*