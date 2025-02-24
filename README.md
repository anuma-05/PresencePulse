# PresencePulse: Digital Footprints Protocol

## Overview

PresencePulse is a blockchain-based attendance verification system built on the Stacks blockchain using Clarity smart contracts. The protocol provides a decentralized solution for tracking attendance at events, meetings, or gatherings while rewarding participants with digital collectibles and points.

## Features

- **Decentralized Attendance Tracking**: Verify attendance without relying on centralized systems
- **Digital Proof of Attendance**: Each attendance is minted as an NFT (Non-Fungible Token)
- **Rewards System**: Participants earn points for attending gatherings
- **Capacity Management**: Set maximum capacity for each gathering
- **On-Chain History**: All attendance records are permanently stored on the blockchain

## How It Works

1. **Gathering Creation**: Administrators register new gatherings with details like title, scheduled time, and capacity
2. **Attendance Recording**: Participants record their attendance on the blockchain
3. **Token Issuance**: Upon successful attendance verification, an NFT is minted to the participant's wallet
4. **Points Collection**: Participants can collect points for their attendance
5. **Verification**: Anyone can verify attendance records on the blockchain

## Smart Contract Functions

### Administrative Functions

- `register-gathering`: Create a new gathering with title, scheduled time, and capacity

### User Functions

- `record-attendance`: Record attendance for a specific gathering and receive an NFT
- `collect-points`: Collect points for verified attendance
- `get-gathering`: View details of a specific gathering
- `get-attendance-record`: Check attendance status for a specific user at a gathering
- `get-attendee-profile`: View a user's attendance history and total points

## Technical Details

PresencePulse is implemented as a Clarity smart contract on the Stacks blockchain. The contract uses:

- **NFTs**: Proof of attendance represented as unique tokens
- **Data Maps**: Store gathering details, attendance records, and user profiles
- **Principal-based Authentication**: Ensure only eligible participants can record attendance

## Use Cases

- **Conferences & Events**: Verify attendance and distribute digital memorabilia
- **Educational Institutions**: Track class attendance and reward participation
- **Community Gatherings**: Create incentives for community engagement
- **Corporate Meetings**: Ensure accurate attendance records for important meetings
- **Loyalty Programs**: Build attendance-based reward systems

## Getting Started

### Prerequisites

- Stacks wallet (Hiro Wallet or similar)
- STX tokens for transaction fees

### Interacting with the Contract

1. **For Administrators**:
   - Deploy the contract
   - Call `register-gathering` with appropriate parameters

2. **For Attendees**:
   - Navigate to a gathering's verification page
   - Connect your Stacks wallet
   - Call `record-attendance` with the gathering ID
   - After verification, call `collect-points` to claim your rewards

## Future Enhancements

- Integration with physical verification mechanisms (QR codes, NFC, etc.)
- Enhanced reward tiers based on attendance frequency
- Support for recurring gatherings
- Time-based verification windows
- Delegation of administrative privileges
